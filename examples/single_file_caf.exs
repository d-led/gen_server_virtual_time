#!/usr/bin/env elixir

# Single-file Elixir script to generate CAF actor code
# Run with: elixir examples/single_file_caf.exs
#
# This demonstrates generating production C++ Actor Framework code with:
# - Callback interfaces for customization
# - Catch2 tests
# - CI/CD pipeline
# All from one portable Elixir script!

Mix.install([
  # Use path for local development, or "~> 0.2.0" when generators are published
  {:gen_server_virtual_time, path: Path.join(__DIR__, "..")}
])

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║  Single-File CAF Generator Example                        ║
║  Generate actor system C++ code in one script!            ║
╚═══════════════════════════════════════════════════════════╝
""")

# Define a message pipeline
simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:source,
    send_pattern: {:rate, 50, :data},
    targets: [:stage1]
  )
  |> ActorSimulation.add_actor(:stage1, targets: [:stage2])
  |> ActorSimulation.add_actor(:stage2, targets: [:sink])
  |> ActorSimulation.add_actor(:sink)

# Generate CAF C++ code with callbacks and tests
{:ok, files} =
  ActorSimulation.CAFGenerator.generate(simulation,
    project_name: "PipelineActors",
    enable_callbacks: true
  )

# Write to output directory
output_dir = "generated/caf_pipeline"
ActorSimulation.CAFGenerator.write_to_directory(files, output_dir)

IO.puts("""

✅ Generated #{length(files)} files in #{output_dir}/

Key files:
  - *_actor.hpp/cpp              CAF actors (DO NOT EDIT)
  - *_callbacks_impl.cpp         YOUR CUSTOM CODE HERE!
  - test_actors.cpp              Catch2 tests
  - .github/workflows/ci.yml     CI pipeline

🎯 Key Feature: Callback Customization!
  Edit *_callbacks_impl.cpp to add your business logic
  WITHOUT touching the generated actor code!

To build and run:
  cd #{output_dir}
  mkdir build && cd build
  conan install .. --build=missing
  cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
  cmake --build .
  ./PipelineActors

To run tests:
  ctest --output-on-failure
  ./PipelineActors_test

📖 See CAF_GENERATOR.md for more details
""")

