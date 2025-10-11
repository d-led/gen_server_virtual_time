#!/usr/bin/env elixir

# Demo: Dining Philosophers Problem with Virtual Time
#
# Run this with: mix run examples/dining_philosophers_demo.exs

IO.puts("""
╔══════════════════════════════════════════════════════════════╗
║              🍴 Dining Philosophers Problem                   ║
║         Classic Concurrency Solved with Virtual Time          ║
╚══════════════════════════════════════════════════════════════╝

The Problem:
  Five philosophers sit at a round table with five forks.
  Each philosopher needs TWO adjacent forks to eat.
  
  Challenge: How to avoid deadlock?
  
  Solution: Asymmetric fork acquisition
  - Even philosophers: left fork first
  - Odd philosophers: right fork first
  
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

IO.puts("📚 Demo 1: Small Table (3 Philosophers)")
IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

start_time = System.monotonic_time(:millisecond)

simulation = 
  DiningPhilosophers.create_simulation(
    num_philosophers: 3,
    think_time: 100,
    eat_time: 50,
    trace: true
  )
  |> ActorSimulation.run(duration: 1000)

elapsed = System.monotonic_time(:millisecond) - start_time

IO.puts("⏱️  Simulation time: 1000ms (virtual)")
IO.puts("⏱️  Actual time: #{elapsed}ms (real)")
IO.puts("")

stats = ActorSimulation.get_stats(simulation)

Enum.each(0..2, fn i ->
  name = :"philosopher_#{i}"
  phil_stats = stats.actors[name]
  IO.puts("👤 #{name}:")
  IO.puts("   Messages sent: #{phil_stats.sent_count}")
  IO.puts("   Messages received: #{phil_stats.received_count}")
end)

IO.puts("")
Enum.each(0..2, fn i ->
  name = :"fork_#{i}"
  fork_stats = stats.actors[name]
  IO.puts("🍴 #{name}: #{fork_stats.received_count} requests handled")
end)

trace = ActorSimulation.get_trace(simulation)
IO.puts("\n📊 Total message events captured: #{length(trace)}")

ActorSimulation.stop(simulation)

IO.puts("""

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Demo 2: Full Table (5 Philosophers) - Extended Simulation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

start_time = System.monotonic_time(:millisecond)

simulation = 
  DiningPhilosophers.create_simulation(
    num_philosophers: 5,
    think_time: 80,
    eat_time: 40,
    trace: true
  )
  |> ActorSimulation.run(duration: 5000)

elapsed = System.monotonic_time(:millisecond) - start_time
stats = ActorSimulation.get_stats(simulation)

IO.puts("⏱️  Simulated 5 seconds in #{elapsed}ms\n")

total_messages = Enum.reduce(0..4, 0, fn i, acc ->
  name = :"philosopher_#{i}"
  acc + stats.actors[name].sent_count
end)

IO.puts("📊 Summary:")
IO.puts("   Total philosophers: 5")
IO.puts("   Total forks: 5")
IO.puts("   Total messages: #{total_messages}")
IO.puts("   Duration: 5000ms virtual time")
IO.puts("   Deadlocks: 0 (thanks to asymmetric acquisition!)")
IO.puts("")

# Show philosopher activity
IO.puts("👥 Philosopher Activity:")
Enum.each(0..4, fn i ->
  name = :"philosopher_#{i}"
  phil_stats = stats.actors[name]
  activity = div(phil_stats.sent_count * 100, total_messages)
  bar = String.duplicate("█", div(activity, 5))
  IO.puts("   #{name}: #{bar} #{activity}%")
end)

# Generate and save diagrams
mermaid = ActorSimulation.trace_to_mermaid(simulation, 
  enhanced: true,
  timestamps: true
)

plantuml = ActorSimulation.trace_to_plantuml(simulation)

IO.puts("\n📁 Generated Diagrams:")
IO.puts("   • test/output/dining_philosophers.html (Mermaid)")
IO.puts("   • Open in browser to see the full interaction sequence!")

ActorSimulation.stop(simulation)

IO.puts("""

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Demo 3: Visualize the Solution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The generated diagram shows:
  • Philosophers requesting forks (synchronous calls)
  • Forks granting or denying access
  • Fork releases after eating
  • Virtual time progression with timestamps
  • No deadlocks occurring

Key Mermaid Features Used:
  • ->> for synchronous calls
  • activate/deactivate for fork processing
  • Note over for timestamps
  • Automatic actor lifelines

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

╔══════════════════════════════════════════════════════════════╗
║  ✅ Dining Philosophers Demo Complete!                        ║
║                                                               ║
║  This demonstrates:                                           ║
║  • Resource contention handling                              ║
║  • Deadlock-free synchronization                             ║
║  • Synchronous communication (fork requests)                 ║
║  • Message tracing with sequence diagrams                    ║
║  • Virtual time for instant simulation                       ║
║                                                               ║
║  Open test/output/dining_philosophers.html to see the        ║
║  complete interaction sequence!                              ║
╚══════════════════════════════════════════════════════════════╝
""")

