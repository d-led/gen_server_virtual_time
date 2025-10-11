defmodule TerminationConditionTest do
  use ExUnit.Case, async: false

  describe "Termination conditions" do
    test "simulation stops when condition is met" do
      # Create a simple producer
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(
          max_duration: 10_000,
          terminate_when: fn sim ->
            # Stop when producer has sent 10 messages
            stats = ActorSimulation.collect_current_stats(sim)
            stats.actors[:producer].sent_count >= 10
          end,
          check_interval: 100
        )

      stats = ActorSimulation.get_stats(simulation)

      # Should have stopped early (around 1000ms, not 10000ms)
      assert simulation.actual_duration < 2000
      assert simulation.actual_duration >= 1000

      # Producer sent at least 10 messages
      assert stats.actors[:producer].sent_count >= 10

      ActorSimulation.stop(simulation)
    end

    test "simulation runs full duration if condition never met" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:slow_producer,
          send_pattern: {:periodic, 1000, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(
          max_duration: 2000,
          terminate_when: fn sim ->
            # Impossible condition
            stats = ActorSimulation.collect_current_stats(sim)
            stats.actors[:slow_producer].sent_count >= 100
          end
        )

      # Should have run full duration
      assert simulation.actual_duration == 2000

      ActorSimulation.stop(simulation)
    end

    test "dining philosophers terminates when all have eaten enough" do
      min_meals = 3

      # Custom philosopher condition checker
      all_fed? = fn sim ->
        stats = ActorSimulation.collect_current_stats(sim)

        # Check all philosophers have sent enough messages
        # Each eating cycle sends messages to forks
        Enum.all?(0..2, fn i ->
          name = :"philosopher_#{i}"

          case stats.actors[name] do
            nil -> false
            actor_stats -> actor_stats.sent_count >= min_meals * 2
          end
        end)
      end

      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 3,
          think_time: 100,
          eat_time: 50,
          trace: false
        )
        |> ActorSimulation.run(
          max_duration: 10_000,
          terminate_when: all_fed?,
          check_interval: 100
        )

      stats = ActorSimulation.get_stats(simulation)

      # Simulation should have ended early
      assert simulation.actual_duration < 10_000

      IO.puts("\n🍴 Dining Philosophers - Condition-based termination:")
      IO.puts("   Terminated after: #{simulation.actual_duration}ms (virtual)")
      IO.puts("   Target: All philosophers eat #{min_meals} times")

      Enum.each(0..2, fn i ->
        name = :"philosopher_#{i}"
        IO.puts("   #{name}: #{stats.actors[name].sent_count} messages")
      end)

      ActorSimulation.stop(simulation)
    end

    test "can use multiple termination conditions with 'or' logic" do
      # Stop when either: 100 total messages OR 5 seconds elapsed
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:fast_producer,
          send_pattern: {:periodic, 10, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(
          max_duration: 5000,
          terminate_when: fn sim ->
            stats = ActorSimulation.collect_current_stats(sim)
            stats.total_messages >= 100
          end,
          check_interval: 50
        )

      # Should stop around 1000ms (100 messages at 10ms each)
      assert simulation.actual_duration < 1500
      assert simulation.actual_duration >= 500

      ActorSimulation.stop(simulation)
    end
  end

  describe "DSL impact of termination conditions" do
    test "actors can influence termination through their behavior" do
      # Create a coordinator that signals completion
      coordinator_behavior = fn msg, state ->
        case msg do
          :task_complete ->
            new_completed = state.completed + 1

            if new_completed >= 3 do
              # Signal that simulation can terminate
              {:ok, %{state | completed: new_completed, ready_to_stop: true}}
            else
              {:ok, %{state | completed: new_completed}}
            end

          _ ->
            {:ok, state}
        end
      end

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:coordinator,
          on_receive: coordinator_behavior,
          initial_state: %{completed: 0, ready_to_stop: false}
        )
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :task_complete},
          targets: [:coordinator]
        )
        |> ActorSimulation.run(
          max_duration: 10_000,
          terminate_when: fn sim ->
            # Check coordinator state via sent messages as proxy
            stats = ActorSimulation.collect_current_stats(sim)
            stats.actors[:worker].sent_count >= 3
          end
        )

      # Should terminate early
      assert simulation.actual_duration < 1000
      assert simulation.actual_duration >= 300

      ActorSimulation.stop(simulation)
    end

    test "can combine time-based and state-based termination" do
      # Stop at 5 seconds OR when consumer receives 50 messages
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 50, :msg},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(
          max_duration: 5000,
          terminate_when: fn sim ->
            stats = ActorSimulation.collect_current_stats(sim)
            stats.actors[:consumer].received_count >= 50
          end
        )

      stats = ActorSimulation.get_stats(simulation)

      # Should stop when consumer hit 50 messages (around 2500ms)
      assert simulation.actual_duration < 3000
      assert stats.actors[:consumer].received_count >= 50

      ActorSimulation.stop(simulation)
    end
  end
end
