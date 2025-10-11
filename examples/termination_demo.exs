#!/usr/bin/env elixir

# Demo: Condition-Based Simulation Termination
#
# Run this with: mix run examples/termination_demo.exs

IO.puts("""
╔══════════════════════════════════════════════════════════════╗
║          Condition-Based Simulation Termination               ║
║       Stop when goals are met, not at fixed time              ║
╚══════════════════════════════════════════════════════════════╝
""")

IO.puts("📚 Demo 1: Fixed Duration (Traditional)")
IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:producer,
      send_pattern: {:periodic, 100, :data},
      targets: [:consumer])
  |> ActorSimulation.add_actor(:consumer)
  |> ActorSimulation.run(duration: 1000)

stats = ActorSimulation.get_stats(simulation)
IO.puts("✅ Ran for exactly 1000ms")
IO.puts("📊 Producer sent: #{stats.actors[:producer].sent_count} messages")
IO.puts("📊 Consumer received: #{stats.actors[:consumer].received_count} messages")

ActorSimulation.stop(simulation)

IO.puts("""

📚 Demo 2: Terminate When Goal Achieved
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

start_time = System.monotonic_time(:millisecond)

simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:producer,
      send_pattern: {:periodic, 100, :data},
      targets: [:consumer])
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

elapsed = System.monotonic_time(:millisecond) - start_time
stats = ActorSimulation.get_stats(simulation)

IO.puts("✅ Terminated early when goal achieved!")
IO.puts("⏱️  Virtual time: #{simulation.actual_duration}ms (vs 10,000ms max)")
IO.puts("⏱️  Real time: #{elapsed}ms")
IO.puts("📊 Producer sent: #{stats.actors[:producer].sent_count} messages (goal: 10)")
IO.puts("💡 Saved: #{10_000 - simulation.actual_duration}ms of unnecessary simulation")

ActorSimulation.stop(simulation)

IO.puts("""

📚 Demo 3: Dining Philosophers - Feed All Philosophers
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

min_meals = 5

all_philosophers_fed = fn sim ->
  stats = ActorSimulation.collect_current_stats(sim)

  Enum.all?(0..4, fn i ->
    name = :"philosopher_#{i}"
    case stats.actors[name] do
      nil -> false
      actor_stats -> actor_stats.sent_count >= min_meals * 2
    end
  end)
end

start_time = System.monotonic_time(:millisecond)

simulation =
  DiningPhilosophers.create_simulation(
    num_philosophers: 5,
    think_time: 100,
    eat_time: 50,
    trace: false
  )
  |> ActorSimulation.run(
      max_duration: 30_000,
      terminate_when: all_philosophers_fed,
      check_interval: 100
    )

elapsed = System.monotonic_time(:millisecond) - start_time
stats = ActorSimulation.get_stats(simulation)

IO.puts("🍴 Goal: Ensure all 5 philosophers eat at least #{min_meals} times")
IO.puts("✅ All philosophers fed!")
IO.puts("⏱️  Virtual time: #{simulation.actual_duration}ms (vs 30,000ms max)")
IO.puts("⏱️  Real time: #{elapsed}ms")
IO.puts("")

Enum.each(0..4, fn i ->
  name = :"philosopher_#{i}"
  phil_stats = stats.actors[name]
  meals_estimate = div(phil_stats.sent_count, 2)
  IO.puts("   #{name}: ~#{meals_estimate} meals (#{phil_stats.sent_count} fork operations)")
end)

IO.puts("\n💡 Simulation stopped as soon as goal was met, not at fixed time!")

ActorSimulation.stop(simulation)

IO.puts("""

📚 Demo 4: Complex Condition - Convergence Detection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

# Stop when system reaches steady state
simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:producer,
      send_pattern: {:rate, 50, :msg},
      targets: [:consumer])
  |> ActorSimulation.add_actor(:consumer)
  |> ActorSimulation.run(
      max_duration: 10_000,
      terminate_when: fn sim ->
        # Stop when we've processed 250 total messages
        stats = ActorSimulation.collect_current_stats(sim)
        stats.total_messages >= 250
      end,
      check_interval: 50
    )

stats = ActorSimulation.get_stats(simulation)

IO.puts("✅ Stopped when system reached 250 total messages")
IO.puts("⏱️  Virtual time: #{simulation.actual_duration}ms")
IO.puts("📊 Total messages: #{stats.total_messages}")
IO.puts("📊 Producer sent: #{stats.actors[:producer].sent_count}")
IO.puts("📊 Consumer received: #{stats.actors[:consumer].received_count}")

ActorSimulation.stop(simulation)

IO.puts("""

╔══════════════════════════════════════════════════════════════╗
║  ✅ Condition-Based Termination Demo Complete!                ║
║                                                               ║
║  Benefits:                                                    ║
║  • Stop when goals are achieved                              ║
║  • Avoid over-simulation                                     ║
║  • More realistic test scenarios                             ║
║  • Better resource utilization                               ║
║  • Fully backward compatible                                 ║
║                                                               ║
║  Impact on DSL:                                              ║
║  • Optional terminate_when parameter                         ║
║  • collect_current_stats for condition checking              ║
║  • actual_duration field in simulation result                ║
║  • Existing code works unchanged                             ║
╚══════════════════════════════════════════════════════════════╝
""")
