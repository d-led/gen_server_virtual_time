#!/usr/bin/env elixir

# Demo: Generate Ractor (Rust) code from ActorSimulation DSL
#
# Run this with: mix run examples/ractor_demo.exs

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║       Ractor Code Generator Demo                         ║
║       Generate Rust Actor System from Elixir DSL         ║
╚═══════════════════════════════════════════════════════════╝
""")

# Example 1: Simple Pub-Sub System

IO.puts("📚 Example 1: Pub-Sub System with Ractor")
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
  ActorSimulation.RactorGenerator.generate(pubsub_simulation,
    project_name: "pubsub_actors",
    enable_callbacks: true
  )

output_dir = "examples/ractor_pubsub"
ActorSimulation.RactorGenerator.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

# Example 2: Message Pipeline

IO.puts("""

📚 Example 2: Message Pipeline with Ractor
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
  ActorSimulation.RactorGenerator.generate(pipeline_simulation,
    project_name: "pipeline_actors",
    enable_callbacks: true
  )

output_dir = "examples/ractor_pipeline"
ActorSimulation.RactorGenerator.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

# Example 3: Bursty Traffic

IO.puts("""

📚 Example 3: Bursty Traffic Pattern with Ractor
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
  ActorSimulation.RactorGenerator.generate(burst_simulation,
    project_name: "burst_actors",
    enable_callbacks: true
  )

output_dir = "examples/ractor_burst"
ActorSimulation.RactorGenerator.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

# Example 4: Complex Network

IO.puts("""

📚 Example 4: Load-Balanced System with Ractor
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
  ActorSimulation.RactorGenerator.generate(complex_simulation,
    project_name: "loadbalanced_actors",
    enable_callbacks: true
  )

output_dir = "examples/ractor_loadbalanced"
ActorSimulation.RactorGenerator.write_to_directory(files, output_dir)

IO.puts("✅ Generated #{length(files)} files:")
Enum.each(files, fn {filename, _} ->
  IO.puts("   - #{filename}")
end)
IO.puts("📁 Output directory: #{output_dir}")

IO.puts("""

╔═══════════════════════════════════════════════════════════╗
║  ✅ All Examples Generated!                                ║
║                                                            ║
║  To build and run with Ractor (Rust):                    ║
║    cd examples/ractor_pubsub                              ║
║    cargo build --release                                  ║
║    cargo run --release                                    ║
║                                                            ║
║  To run tests:                                            ║
║    cargo test                                             ║
║                                                            ║
║  Customize behavior by editing callback trait impls       ║
║  in src/actors/*.rs WITHOUT touching generated code!      ║
║                                                            ║
║  See https://github.com/slawlor/ractor for Ractor docs   ║
╚═══════════════════════════════════════════════════════════╝
""")

