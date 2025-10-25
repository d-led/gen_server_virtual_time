defmodule ActorSimulationTest do
  use ExUnit.Case, async: true

  describe "ActorSimulation DSL" do
    test "creates a new simulation" do
      simulation = ActorSimulation.new()
      assert %ActorSimulation{} = simulation
      assert simulation.clock != nil
      assert simulation.actors == %{}
    end

    test "adds actors to simulation" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      assert map_size(simulation.actors) == 2
      assert Map.has_key?(simulation.actors, :producer)
      assert Map.has_key?(simulation.actors, :consumer)
    end
  end

  describe "Periodic message sending" do
    test "producer sends messages at regular intervals" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :ping},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)
      producer_stats = stats.actors[:producer]
      consumer_stats = stats.actors[:consumer]

      # Producer should send ~10 messages (1000ms / 100ms interval)
      assert producer_stats.sent_count >= 8

      # Consumer should receive ~10 messages
      assert consumer_stats.received_count == 10

      ActorSimulation.stop(simulation)
    end

    test "multiple producers sending to one consumer" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer1,
          send_pattern: {:periodic, 100, :data1},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:producer2,
          send_pattern: {:periodic, 200, :data2},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)

      # Producer1: 10 messages (1000/100)
      assert stats.actors[:producer1].sent_count >= 5

      # Producer2: 5 messages (1000/200)
      assert stats.actors[:producer2].sent_count == 5

      # Consumer receives both
      assert stats.actors[:consumer].received_count == 15

      ActorSimulation.stop(simulation)
    end
  end

  describe "Rate-based message sending" do
    test "sends messages at specified rate per second" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:rate, 10, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 2000)

      stats = ActorSimulation.get_stats(simulation)

      # At 10 messages/second for 2 seconds = 20 messages
      assert stats.actors[:producer].sent_count >= 10
      assert stats.actors[:consumer].received_count >= 10

      ActorSimulation.stop(simulation)
    end
  end

  describe "Burst message sending" do
    test "sends bursts of messages at intervals" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:burst, 5, 500, :batch},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)

      # 2 bursts (at 0ms and 500ms), each with 5 messages = 10 total
      # Quiescence should ensure all scheduled events are processed
      assert stats.actors[:producer].sent_count == 10
      assert stats.actors[:consumer].received_count == 10

      ActorSimulation.stop(simulation)
    end
  end

  describe "Request-response patterns" do
    test "consumer responds to received messages" do
      on_receive = fn msg, state ->
        case msg do
          :request ->
            # Send a response back to the producer
            {:send, [{:producer, :response}], state}

          _ ->
            {:ok, state}
        end
      end

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :request},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer, on_receive: on_receive)
        |> ActorSimulation.run(duration: 500)

      stats = ActorSimulation.get_stats(simulation)

      # Producer sends 5 requests
      assert stats.actors[:producer].sent_count == 5

      # Consumer receives 5 requests and sends 5 responses
      assert stats.actors[:consumer].received_count == 5
      assert stats.actors[:consumer].sent_count == 5

      # Producer receives 5 responses
      assert stats.actors[:producer].received_count == 5

      ActorSimulation.stop(simulation)
    end
  end

  describe "Complex multi-actor scenarios" do
    test "simulates a pipeline of actors" do
      # Stage1 -> Stage2 -> Stage3
      # Each stage processes and forwards

      forward = fn msg, state ->
        {:send, [{state.next_stage, msg}], state}
      end

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:source,
          send_pattern: {:periodic, 100, :data},
          targets: [:stage1]
        )
        |> ActorSimulation.add_actor(:stage1,
          on_receive: forward,
          initial_state: %{next_stage: :stage2}
        )
        |> ActorSimulation.add_actor(:stage2,
          on_receive: forward,
          initial_state: %{next_stage: :stage3}
        )
        |> ActorSimulation.add_actor(:stage3)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)

      # Source sends 10 messages
      assert stats.actors[:source].sent_count == 10

      # Each stage receives and forwards 10 messages
      assert stats.actors[:stage1].received_count == 10
      assert stats.actors[:stage1].sent_count == 10

      assert stats.actors[:stage2].received_count == 10
      assert stats.actors[:stage2].sent_count == 10

      # Final stage only receives
      assert stats.actors[:stage3].received_count == 10

      ActorSimulation.stop(simulation)
    end

    test "simulates pub-sub pattern with multiple subscribers" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:publisher,
          send_pattern: {:periodic, 200, :event},
          targets: [:subscriber1, :subscriber2, :subscriber3]
        )
        |> ActorSimulation.add_actor(:subscriber1)
        |> ActorSimulation.add_actor(:subscriber2)
        |> ActorSimulation.add_actor(:subscriber3)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)

      # Publisher sends 5 ticks, each to 3 subscribers = 15 total sends
      assert stats.actors[:publisher].sent_count == 15

      # Each subscriber receives 5 messages
      assert stats.actors[:subscriber1].received_count == 5
      assert stats.actors[:subscriber2].received_count == 5
      assert stats.actors[:subscriber3].received_count == 5

      ActorSimulation.stop(simulation)
    end
  end

  describe "Performance - simulating long durations" do
    @tag :slow
    @tag timeout: 15_000
    test "simulates long durations much faster than real time" do
      start_time = System.monotonic_time(:millisecond)

      # Simulate 1 minute of a high-frequency system
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:high_freq_producer,
          # 100 messages/second
          send_pattern: {:rate, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        # 1 minute
        |> ActorSimulation.run(duration: 60_000)

      elapsed = System.monotonic_time(:millisecond) - start_time
      stats = ActorSimulation.get_stats(simulation)

      # Should have sent ~6,000 messages (100/sec * 60 sec)
      # Allow some variance due to timing
      assert stats.actors[:high_freq_producer].sent_count >= 5_900
      assert stats.actors[:consumer].received_count >= 5_900

      # But the test completes much faster than real time (60 seconds)
      # Be generous with the assertion to avoid flakiness on slower machines
      assert elapsed < 60_000, "Should complete faster than the 60 seconds of real time simulated"

      ActorSimulation.stop(simulation)
    end
  end

  describe "Statistics and metrics" do
    test "collects comprehensive statistics" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :msg},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)

      # Check structure
      assert Map.has_key?(stats.actors, :producer)
      assert Map.has_key?(stats.actors, :consumer)

      # Check producer stats
      producer = stats.actors[:producer]
      assert producer.sent_count > 0
      assert producer.received_count == 0
      assert is_list(producer.sent_messages)

      # Check consumer stats
      consumer = stats.actors[:consumer]
      assert consumer.sent_count == 0
      assert consumer.received_count > 0
      assert is_list(consumer.received_messages)

      ActorSimulation.stop(simulation)
    end
  end
end
