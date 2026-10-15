defmodule ActorSimulation.StatsPropertyTest do
  @moduledoc """
  Laws for aggregating actor statistics.

  `total_messages` counts everything that was ever added, while `actors` keeps the
  latest entry per name — `stats_test.exs` pins that, and `ActorSimulation` adds
  each actor once per pass. The termination conditions, the reports and the
  generated statistics all read these numbers, so the accounting rules are worth
  stating.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ActorSimulation.Stats

  describe "aggregating" do
    property "a collection that has seen nothing knows nothing" do
      assert Stats.new().total_messages == 0
      assert Stats.new().actors == %{}
    end

    property "every actor added contributes exactly its sent and received messages" do
      check all(additions <- additions()) do
        stats = collect(additions)

        assert stats.total_messages ==
                 Enum.sum(for {_name, actor_stats} <- additions, do: traffic(actor_stats))
      end
    end

    property "the order distinct actors arrive in does not change the entries" do
      check all(additions <- additions()) do
        distinct = Enum.uniq_by(additions, &elem(&1, 0))

        forward = collect(distinct)
        backward = distinct |> Enum.reverse() |> collect()

        assert forward.actors == backward.actors
        assert forward.total_messages == backward.total_messages
      end
    end
  end

  describe "formatting" do
    property "keeps every actor and the total, whatever the traffic" do
      check all(additions <- additions(), duration <- integer(1..100_000)) do
        stats = %{collect(additions) | end_time: duration}
        formatted = Stats.format(stats)

        assert Map.keys(formatted.actors) |> Enum.sort() ==
                 stats.actors |> Map.keys() |> Enum.sort()

        assert formatted.total_messages == stats.total_messages
        assert formatted.duration_ms == duration

        for {_name, summary} <- formatted.actors do
          assert summary.sent_rate >= 0
          assert summary.received_rate >= 0
        end
      end
    end

    property "a count over twice the time is half the rate" do
      check all(count <- integer(0..10_000)) do
        assert rate(count, 2000) == rate(count, 1000) / 2
      end
    end

    property "with no time elapsed the rate is zero, not infinite" do
      check all(count <- integer(1..10_000), at <- integer(0..10_000)) do
        stats = %{
          Stats.new()
          | actors: %{idle: %{sent_count: count, received_count: count}},
            total_messages: 2 * count,
            start_time: at,
            end_time: at
        }

        assert Stats.format(stats).actors[:idle].sent_rate == 0.0
      end
    end
  end

  defp rate(count, duration) do
    stats = %{
      Stats.new()
      | actors: %{worker: %{sent_count: count, received_count: 0}},
        total_messages: count,
        start_time: 0,
        end_time: duration
    }

    Stats.format(stats).actors[:worker].sent_rate
  end

  defp additions do
    list_of({actor_name(), actor_stats()}, max_length: 8, min_length: 1)
  end

  defp actor_name, do: member_of([:producer, :consumer, :worker, :sink, :source])

  defp actor_stats do
    gen all(sent <- integer(0..10_000), received <- integer(0..10_000)) do
      %{sent_count: sent, received_count: received}
    end
  end

  defp traffic(actor_stats), do: actor_stats.sent_count + actor_stats.received_count

  defp collect(additions) do
    Enum.reduce(additions, Stats.new(), fn {name, actor_stats}, stats ->
      Stats.add_actor_stats(stats, name, actor_stats)
    end)
  end
end
