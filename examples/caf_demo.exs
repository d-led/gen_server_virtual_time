#!/usr/bin/env elixir

# Demo: Generate CAF (C++ Actor Framework) code from ActorSimulation DSL
#
# Run this with: mix run examples/caf_demo.exs

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║       CAF Code Generator Demo                             ║
║       Generate C++ Actor System from Elixir DSL           ║
╚═══════════════════════════════════════════════════════════╝
""")

# Example 1: Simple Pub-Sub System

IO.puts("📚 Example 1: Pub-Sub System with CAF")
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
  ActorSimulation.Codegen.CAF.generate(pubsub_simulation,
    project_name: "PubSubActors",
    enable_callbacks: true
  )

output_dir = "examples/caf_pubsub"
ActorSimulation.Codegen.CAF.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

# Example 2: Message Pipeline

IO.puts("""

📚 Example 2: Message Pipeline with CAF
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
  ActorSimulation.Codegen.CAF.generate(pipeline_simulation,
    project_name: "PipelineActors",
    enable_callbacks: true
  )

output_dir = "examples/caf_pipeline"
ActorSimulation.Codegen.CAF.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

# Example 3: Bursty Traffic

IO.puts("""

📚 Example 3: Bursty Traffic Pattern with CAF
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
  ActorSimulation.Codegen.CAF.generate(burst_simulation,
    project_name: "BurstActors",
    enable_callbacks: true
  )

output_dir = "examples/caf_burst"
ActorSimulation.Codegen.CAF.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

# Example 4: Complex Network

IO.puts("""

📚 Example 4: Load-Balanced System with CAF
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
  ActorSimulation.Codegen.CAF.generate(complex_simulation,
    project_name: "LoadBalancedActors",
    enable_callbacks: true
  )

output_dir = "examples/caf_loadbalanced"
ActorSimulation.Codegen.CAF.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

IO.puts("""

╔═══════════════════════════════════════════════════════════╗
║  ✅ All Examples Generated!                                ║
║                                                            ║
║  To build and run with CAF:                               ║
║    cd examples/caf_pubsub                                 ║
║    mkdir build && cd build                                ║
║    conan install .. --build=missing                       ║
║    cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake  ║
║    cmake --build .                                        ║
║    ./PubSubActors                                         ║
║                                                            ║
║  Customize behavior by editing *_callbacks_impl.cpp       ║
║  WITHOUT touching the generated actor code!               ║
║                                                            ║
║  See https://actor-framework.org/ for CAF docs            ║
╚═══════════════════════════════════════════════════════════╝
""")

