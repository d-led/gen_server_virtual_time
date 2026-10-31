#!/usr/bin/env elixir

# Demo: Generate OMNeT++ code from ActorSimulation DSL
#
# Run this with: mix run examples/omnetpp_demo.exs

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║       OMNeT++ Code Generator Demo                         ║
║       Generate C++ Simulation from Elixir DSL             ║
╚═══════════════════════════════════════════════════════════╝
""")

# Example 1: Simple Pub-Sub System

IO.puts("📚 Example 1: Pub-Sub System")
IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

pubsub_simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:publisher,
    send_pattern: {:periodic, 100, :event},
    targets: [:subscriber1, :subscriber2, :subscriber3]
  )
  |> ActorSimulation.add_actor(:subscriber1)
  |> ActorSimulation.add_actor(:subscriber2)
  |> ActorSimulation.add_actor(:subscriber3)

{:ok, files} =
  ActorSimulation.Codegen.OMNeTPP.generate(pubsub_simulation,
    network_name: "PubSubNetwork",
    sim_time_limit: 10
  )

output_dir = "examples/omnetpp_pubsub"
ActorSimulation.Codegen.OMNeTPP.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

# Example 2: Message Pipeline

IO.puts("""

📚 Example 2: Message Pipeline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

pipeline_simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:source,
    send_pattern: {:rate, 50, :data},
    targets: [:stage1]
  )
  |> ActorSimulation.add_actor(:stage1,
    targets: [:stage2]
  )
  |> ActorSimulation.add_actor(:stage2,
    targets: [:stage3]
  )
  |> ActorSimulation.add_actor(:stage3,
    targets: [:sink]
  )
  |> ActorSimulation.add_actor(:sink)

{:ok, files} =
  ActorSimulation.Codegen.OMNeTPP.generate(pipeline_simulation,
    network_name: "PipelineNetwork",
    sim_time_limit: 5
  )

output_dir = "examples/omnetpp_pipeline"
ActorSimulation.Codegen.OMNeTPP.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

# Example 3: Bursty Traffic

IO.puts("""

📚 Example 3: Bursty Traffic Pattern
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

burst_simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:burst_generator,
    send_pattern: {:burst, 10, 1000, :batch},
    targets: [:processor]
  )
  |> ActorSimulation.add_actor(:processor)

{:ok, files} =
  ActorSimulation.Codegen.OMNeTPP.generate(burst_simulation,
    network_name: "BurstNetwork",
    sim_time_limit: 30
  )

output_dir = "examples/omnetpp_burst"
ActorSimulation.Codegen.OMNeTPP.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

# Example 4: Complex Network

IO.puts("""

📚 Example 4: Complex Network Topology
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

complex_simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:load_balancer,
    send_pattern: {:rate, 100, :request},
    targets: [:server1, :server2, :server3]
  )
  |> ActorSimulation.add_actor(:server1,
    targets: [:database]
  )
  |> ActorSimulation.add_actor(:server2,
    targets: [:database]
  )
  |> ActorSimulation.add_actor(:server3,
    targets: [:database]
  )
  |> ActorSimulation.add_actor(:database)

{:ok, files} =
  ActorSimulation.Codegen.OMNeTPP.generate(complex_simulation,
    network_name: "LoadBalancedSystem",
    sim_time_limit: 60
  )

output_dir = "examples/omnetpp_loadbalanced"
ActorSimulation.Codegen.OMNeTPP.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

IO.puts("""

╔═══════════════════════════════════════════════════════════╗
║  ✅ All Examples Generated!                                ║
║                                                            ║
║  To build and run with OMNeT++:                           ║
║    cd examples/omnetpp_pubsub                             ║
║    mkdir build && cd build                                ║
║    cmake ..                                               ║
║    make                                                   ║
║    ./PubSubNetwork -u Cmdenv                              ║
║                                                            ║
║  See https://github.com/omnetpp/omnetpp for installation  ║
╚═══════════════════════════════════════════════════════════╝
""")
