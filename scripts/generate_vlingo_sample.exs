#!/usr/bin/env elixir

# Script to generate a sample VLINGO XOOM Actors project
# Run: mix run scripts/generate_vlingo_sample.exs

alias ActorSimulation
alias ActorSimulation.VlingoGenerator

# Create a more complex simulation: Load Balanced Worker Pool
simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:load_balancer,
    send_pattern: {:periodic, 50, :distribute_work},
    targets: [:worker1, :worker2, :worker3]
  )
  |> ActorSimulation.add_actor(:worker1,
    send_pattern: {:periodic, 200, :process_task},
    targets: [:result_collector]
  )
  |> ActorSimulation.add_actor(:worker2,
    send_pattern: {:periodic, 200, :process_task},
    targets: [:result_collector]
  )
  |> ActorSimulation.add_actor(:worker3,
    send_pattern: {:periodic, 200, :process_task},
    targets: [:result_collector]
  )
  |> ActorSimulation.add_actor(:result_collector,
    send_pattern: {:rate, 2, :aggregate_results},
    targets: []
  )

IO.puts("Generating VLINGO XOOM Actors project: vlingo_loadbalanced_generated...")

{:ok, files} =
  VlingoGenerator.generate(simulation,
    project_name: "vlingo-loadbalanced",
    group_id: "com.example.actors",
    vlingo_version: "1.11.1",
    enable_callbacks: true
  )

output_dir = Path.join(__DIR__, "../generated/vlingo_loadbalanced")

# Clean up old directory if it exists
if File.exists?(output_dir) do
  File.rm_rf!(output_dir)
end

:ok = VlingoGenerator.write_to_directory(files, output_dir)

IO.puts("✓ Generated #{length(files)} files")
IO.puts("✓ Output directory: #{output_dir}")
IO.puts("")
IO.puts("To build and run:")
IO.puts("  cd #{output_dir}")
IO.puts("  mvn clean compile")
IO.puts("  mvn test")
IO.puts("  mvn exec:java")
