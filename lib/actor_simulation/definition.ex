defmodule ActorSimulation.Definition do
  @moduledoc """
  Defines an actor's behavior in the simulation.
  """

  defstruct [
    :name,
    :send_pattern,
    :targets,
    :on_receive,
    :initial_state
  ]

  def new(name, opts) do
    %__MODULE__{
      name: name,
      send_pattern: Keyword.get(opts, :send_pattern),
      targets: Keyword.get(opts, :targets, []),
      on_receive: Keyword.get(opts, :on_receive, &default_on_receive/2),
      initial_state: Keyword.get(opts, :initial_state, %{})
    }
  end

  defp default_on_receive(_msg, state) do
    {:ok, state}
  end

  @doc """
  Calculates the interval in milliseconds for a send pattern.
  """
  def interval_for_pattern({:periodic, interval, _message}), do: interval
  def interval_for_pattern({:rate, per_second, _message}), do: div(1000, per_second)
  def interval_for_pattern({:burst, _count, interval, _message}), do: interval
  def interval_for_pattern(nil), do: nil

  @doc """
  Gets the message(s) to send for a send pattern.
  """
  def messages_for_pattern({:periodic, _interval, message}), do: [message]
  def messages_for_pattern({:rate, _per_second, message}), do: [message]
  def messages_for_pattern({:burst, count, _interval, message}) do
    List.duplicate(message, count)
  end
  def messages_for_pattern(nil), do: []
end
