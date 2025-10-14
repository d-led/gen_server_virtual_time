defmodule ActorSimulation.StatsTest do
  use ExUnit.Case, async: true

  alias ActorSimulation.Stats

  describe "Stats.new/0" do
    test "creates empty stats with zero values" do
      stats = Stats.new()

      assert stats.actors == %{}
      assert stats.total_messages == 0
      assert stats.start_time == 0
      assert stats.end_time == 0
    end
  end

  describe "Stats.add_actor_stats/3" do
    test "records stats for single actor" do
      stats = Stats.new()
      actor_stats = %{sent_count: 10, received_count: 5}

      result = Stats.add_actor_stats(stats, :worker, actor_stats)

      assert result.actors[:worker] == actor_stats
      assert result.total_messages == 15
    end

    test "accumulates total messages across multiple actors" do
      stats = Stats.new()

      stats = Stats.add_actor_stats(stats, :producer, %{sent_count: 100, received_count: 0})
      stats = Stats.add_actor_stats(stats, :consumer, %{sent_count: 10, received_count: 100})

      assert stats.total_messages == 210
      assert map_size(stats.actors) == 2
    end

    test "overwrites stats when same actor added again" do
      stats = Stats.new()

      stats = Stats.add_actor_stats(stats, :worker, %{sent_count: 10, received_count: 5})
      stats = Stats.add_actor_stats(stats, :worker, %{sent_count: 20, received_count: 15})

      assert stats.actors[:worker].sent_count == 20
      assert stats.actors[:worker].received_count == 15
      # Total accumulates (15 + 35 = 50)
      assert stats.total_messages == 50
    end

    test "handles actors with zero message counts" do
      stats = Stats.new()
      actor_stats = %{sent_count: 0, received_count: 0}

      result = Stats.add_actor_stats(stats, :idle, actor_stats)

      assert result.total_messages == 0
      assert result.actors[:idle] == actor_stats
    end
  end

  describe "Stats.format/1" do
    test "formats stats with rate calculations" do
      stats = %Stats{
        actors: %{
          producer: %{sent_count: 100, received_count: 0},
          consumer: %{sent_count: 0, received_count: 100}
        },
        total_messages: 200,
        start_time: 0,
        end_time: 1000
      }

      formatted = Stats.format(stats)

      assert formatted.total_messages == 200
      assert formatted.duration_ms == 1000
      assert formatted.actors[:producer].sent == 100
      assert formatted.actors[:producer].received == 0
      assert formatted.actors[:producer].sent_rate == 100.0
      assert formatted.actors[:producer].received_rate == 0.0
      assert formatted.actors[:consumer].sent_rate == 0.0
      assert formatted.actors[:consumer].received_rate == 100.0
    end

    test "calculates rates as messages per second" do
      stats = %Stats{
        actors: %{
          worker: %{sent_count: 500, received_count: 250}
        },
        total_messages: 750,
        start_time: 0,
        # 5 seconds
        end_time: 5000
      }

      formatted = Stats.format(stats)

      # 500 messages in 5000ms = 100 msg/sec
      assert formatted.actors[:worker].sent_rate == 100.0
      # 250 messages in 5000ms = 50 msg/sec
      assert formatted.actors[:worker].received_rate == 50.0
    end

    test "handles zero duration without division by zero" do
      stats = %Stats{
        actors: %{
          instant: %{sent_count: 10, received_count: 5}
        },
        total_messages: 15,
        start_time: 100,
        end_time: 100
      }

      formatted = Stats.format(stats)

      assert formatted.duration_ms == 0
      assert formatted.actors[:instant].sent_rate == 0.0
      assert formatted.actors[:instant].received_rate == 0.0
    end

    test "rounds rates to two decimal places" do
      stats = %Stats{
        actors: %{
          worker: %{sent_count: 7, received_count: 3}
        },
        total_messages: 10,
        start_time: 0,
        # 3 seconds
        end_time: 3000
      }

      formatted = Stats.format(stats)

      # 7/3 = 2.333... should round to 2.33
      assert formatted.actors[:worker].sent_rate == 2.33
      # 3/3 = 1.0
      assert formatted.actors[:worker].received_rate == 1.0
    end

    test "formats empty stats" do
      stats = Stats.new()

      formatted = Stats.format(stats)

      assert formatted.actors == %{}
      assert formatted.total_messages == 0
      assert formatted.duration_ms == 0
    end

    test "preserves all actor data in formatted output" do
      stats = %Stats{
        actors: %{
          a: %{sent_count: 10, received_count: 20},
          b: %{sent_count: 30, received_count: 40},
          c: %{sent_count: 50, received_count: 60}
        },
        total_messages: 210,
        start_time: 1000,
        end_time: 2000
      }

      formatted = Stats.format(stats)

      assert Map.keys(formatted.actors) |> Enum.sort() == [:a, :b, :c]
      assert formatted.actors[:a].sent == 10
      assert formatted.actors[:b].sent == 30
      assert formatted.actors[:c].sent == 50
    end

    test "works with negative time range (edge case)" do
      stats = %Stats{
        actors: %{
          time_traveler: %{sent_count: 100, received_count: 50}
        },
        total_messages: 150,
        start_time: 5000,
        end_time: 3000
      }

      formatted = Stats.format(stats)

      # Negative duration still calculates (though unrealistic)
      assert formatted.duration_ms == -2000
      # Rates should handle negative duration without crashing
      assert is_float(formatted.actors[:time_traveler].sent_rate)
    end
  end

  describe "Stats integration" do
    test "typical simulation workflow produces correct stats" do
      # Simulate a pipeline: producer -> processor -> consumer
      stats = Stats.new()

      stats = Stats.add_actor_stats(stats, :producer, %{sent_count: 1000, received_count: 0})
      stats = Stats.add_actor_stats(stats, :processor, %{sent_count: 1000, received_count: 1000})
      stats = Stats.add_actor_stats(stats, :consumer, %{sent_count: 0, received_count: 1000})

      # 10 second simulation
      stats = %{stats | start_time: 0, end_time: 10_000}

      formatted = Stats.format(stats)

      assert formatted.total_messages == 4000
      assert formatted.duration_ms == 10_000
      assert formatted.actors[:producer].sent_rate == 100.0
      assert formatted.actors[:processor].sent_rate == 100.0
      assert formatted.actors[:processor].received_rate == 100.0
      assert formatted.actors[:consumer].received_rate == 100.0
    end
  end
end
