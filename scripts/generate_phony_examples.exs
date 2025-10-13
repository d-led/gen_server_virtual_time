#!/usr/bin/env elixir

# Script to generate all Phony (Go) example projects
# Usage: mix run scripts/generate_phony_examples.exs

defmodule PhonyExampleGenerator do
  @moduledoc """
  Generates all Phony (Go actor library) example projects for testing and validation.
  """

  def run do
    IO.puts("""
    ╔═══════════════════════════════════════════════════════════╗
    ║  Generating Phony (Go) Example Projects                   ║
    ╚═══════════════════════════════════════════════════════════╝
    """)

    examples = [
      {:pubsub, &create_pubsub_simulation/0, "pubsub_actors"},
      {:pipeline, &create_pipeline_simulation/0, "pipeline_actors"},
      {:burst, &create_burst_simulation/0, "burst_actors"},
      {:loadbalanced, &create_loadbalanced_simulation/0, "loadbalanced_actors"}
    ]

    results =
      Enum.map(examples, fn {name, sim_fn, project_name} ->
        generate_example(name, sim_fn.(), project_name)
      end)

    # Summary
    IO.puts("""

    ╔═══════════════════════════════════════════════════════════╗
    ║  Generation Summary                                        ║
    ╚═══════════════════════════════════════════════════════════╝
    """)

    total_files = Enum.sum(Enum.map(results, fn {_, count, _} -> count end))
    success_count = Enum.count(results, fn {status, _, _} -> status == :ok end)

    IO.puts("Total examples: #{length(results)}")
    IO.puts("Successful: #{success_count}")
    IO.puts("Total files generated: #{total_files}")

    if success_count == length(results) do
      IO.puts("\n✅ All examples generated successfully!")
      exit({:shutdown, 0})
    else
      IO.puts("\n❌ Some examples failed to generate")
      exit({:shutdown, 1})
    end
  end

  defp generate_example(name, simulation, project_name) do
    IO.puts("\n📚 Generating: #{name}")
    IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    try do
      {:ok, files} =
        ActorSimulation.PhonyGenerator.generate(simulation,
          project_name: project_name,
          enable_callbacks: true
        )

      output_dir = "examples/phony_#{name}"
      :ok = ActorSimulation.PhonyGenerator.write_to_directory(files, output_dir)

      file_count = length(files)
      IO.puts("✅ Generated #{file_count} files in #{output_dir}/")

      # List key files
      go_count = Enum.count(files, fn {fname, _} -> String.ends_with?(fname, ".go") end)
      IO.puts("   - #{go_count} Go source files")
      IO.puts("   - go.mod, CI pipeline")
      IO.puts("   - README.md with build instructions")

      {:ok, file_count, output_dir}
    rescue
      e ->
        IO.puts("❌ Failed: #{inspect(e)}")
        {:error, 0, nil}
    end
  end

  # Simulation definitions

  defp create_pubsub_simulation do
    ActorSimulation.new()
    |> ActorSimulation.add_actor(:publisher,
      send_pattern: {:periodic, 100, :event},
      targets: [:subscriber1, :subscriber2, :subscriber3]
    )
    |> ActorSimulation.add_actor(:subscriber1)
    |> ActorSimulation.add_actor(:subscriber2)
    |> ActorSimulation.add_actor(:subscriber3)
  end

  defp create_pipeline_simulation do
    ActorSimulation.new()
    |> ActorSimulation.add_actor(:source,
      send_pattern: {:rate, 50, :data},
      targets: [:stage1]
    )
    |> ActorSimulation.add_actor(:stage1, targets: [:stage2])
    |> ActorSimulation.add_actor(:stage2, targets: [:stage3])
    |> ActorSimulation.add_actor(:stage3, targets: [:sink])
    |> ActorSimulation.add_actor(:sink)
  end

  defp create_burst_simulation do
    ActorSimulation.new()
    |> ActorSimulation.add_actor(:burst_generator,
      send_pattern: {:burst, 10, 1000, :batch},
      targets: [:processor]
    )
    |> ActorSimulation.add_actor(:processor)
  end

  defp create_loadbalanced_simulation do
    ActorSimulation.new()
    |> ActorSimulation.add_actor(:load_balancer,
      send_pattern: {:rate, 100, :request},
      targets: [:server1, :server2, :server3]
    )
    |> ActorSimulation.add_actor(:server1, targets: [:database])
    |> ActorSimulation.add_actor(:server2, targets: [:database])
    |> ActorSimulation.add_actor(:server3, targets: [:database])
    |> ActorSimulation.add_actor(:database)
  end
end

# Run the generator
PhonyExampleGenerator.run()
