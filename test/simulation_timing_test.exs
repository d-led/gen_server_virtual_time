defmodule SimulationTimingTest do
  use ExUnit.Case, async: false

  describe "Simulation timing information" do
    test "returns virtual time and real time elapsed" do
      start_real_time = System.monotonic_time(:millisecond)

      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(
          max_duration: 10_000,
          terminate_when: fn sim ->
            stats = ActorSimulation.collect_current_stats(sim)
            stats.actors[:producer].sent_count >= 5
          end
        )

      end_real_time = System.monotonic_time(:millisecond)
      real_elapsed = end_real_time - start_real_time

      # Virtual time info
      assert simulation.actual_duration > 0
      assert simulation.actual_duration <= simulation.max_duration
      assert simulation.terminated_early == true

      # Real time info
      assert simulation.real_time_elapsed > 0
      assert simulation.real_time_elapsed < simulation.actual_duration  # Real time << virtual time

      IO.puts("\n📊 Timing Comparison:")
      IO.puts("  Virtual time elapsed: #{simulation.actual_duration}ms")
      IO.puts("  Real time elapsed: #{simulation.real_time_elapsed}ms")
      IO.puts("  Speedup: #{Float.round(simulation.actual_duration / simulation.real_time_elapsed, 1)}x")
      IO.puts("  Max virtual time: #{simulation.max_duration}ms")
      IO.puts("  Terminated early: #{simulation.terminated_early}")

      ActorSimulation.stop(simulation)
    end

    test "full duration simulation has correct timing" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:actor,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )
        |> ActorSimulation.run(duration: 1000)

      # Ran full duration
      assert simulation.actual_duration == 1000
      assert simulation.max_duration == 1000
      assert simulation.terminated_early == false

      # Real time should be much less
      assert simulation.real_time_elapsed < 100

      IO.puts("\n⏱️  Full Duration Run:")
      IO.puts("  Virtual: #{simulation.actual_duration}ms")
      IO.puts("  Real: #{simulation.real_time_elapsed}ms")

      ActorSimulation.stop(simulation)
    end
  end
end
