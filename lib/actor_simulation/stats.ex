defmodule ActorSimulation.Stats do
  @moduledoc """
  Collects and aggregates statistics from actor simulations.
  """

  defstruct [
    actors: %{},
    total_messages: 0,
    start_time: 0,
    end_time: 0
  ]

  def new do
    %__MODULE__{}
  end

  @doc """
  Adds statistics for a specific actor.
  """
  def add_actor_stats(stats, actor_name, actor_stats) do
    actors = Map.put(stats.actors, actor_name, actor_stats)
    total = stats.total_messages + actor_stats.sent_count + actor_stats.received_count

    %{stats | actors: actors, total_messages: total}
  end

  @doc """
  Formats statistics into a readable map.
  """
  def format(stats) do
    actor_summaries =
      Enum.map(stats.actors, fn {name, actor_stats} ->
        {name, %{
          sent: actor_stats.sent_count,
          received: actor_stats.received_count,
          sent_rate: calculate_rate(actor_stats.sent_count, stats.end_time - stats.start_time),
          received_rate: calculate_rate(actor_stats.received_count, stats.end_time - stats.start_time)
        }}
      end)
      |> Map.new()

    %{
      actors: actor_summaries,
      total_messages: stats.total_messages,
      duration_ms: stats.end_time - stats.start_time
    }
  end

  defp calculate_rate(count, duration_ms) when duration_ms > 0 do
    Float.round(count * 1000 / duration_ms, 2)
  end
  defp calculate_rate(_count, _duration_ms), do: 0.0
end
