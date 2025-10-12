#!/usr/bin/env elixir

# Single-file Elixir script to generate Phony (Go) actor code
# Run with: elixir examples/single_file_phony.exs
#
# This demonstrates generating Go actor code using Phony library with:
# - Zero-allocation message passing
# - Automatic goroutine management
# - Callback interfaces for customization
# - Go tests
# All from one portable Elixir script!

Mix.install([
  # Use path for local development, or "~> 0.2.0" when generators are published
  {:gen_server_virtual_time, path: Path.join(__DIR__, "..")}
])

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║  Single-File Phony (Go) Generator Example                 ║
║  Generate Go actor code in one script!                    ║
╚═══════════════════════════════════════════════════════════╝
""")

# Define a burst traffic system
simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:burst_generator,
    send_pattern: {:burst, 10, 1000, :batch},
    targets: [:processor]
  )
  |> ActorSimulation.add_actor(:processor)

# Generate Phony (Go) code with callback interfaces
{:ok, files} =
  ActorSimulation.PhonyGenerator.generate(simulation,
    project_name: "burst_actors",
    enable_callbacks: true
  )

# Write to output directory
output_dir = "generated/phony_burst"
ActorSimulation.PhonyGenerator.write_to_directory(files, output_dir)

IO.puts("""

✅ Generated #{length(files)} files in #{output_dir}/

Key files:
  - *.go                      Go actors with Phony
  - *Callbacks interface      Customize behavior
  - actor_test.go             Go tests
  - go.mod                    Module definition

🎯 Why Phony?
  ✓ Zero-allocation messaging
  ✓ No goroutine leaks
  ✓ Backpressure built-in
  ✓ Lock-free operations

To build and run:
  cd #{output_dir}
  go mod download
  go build -o burst_actors .
  ./burst_actors

To run tests:
  go test -v ./...

📖 Prerequisites:
  Go 1.21+ (https://go.dev/dl/)
""")

