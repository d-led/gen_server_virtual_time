#!/usr/bin/env elixir

# Single-file Elixir script to generate Pony actor code
# Run with: elixir examples/single_file_pony.exs
#
# This demonstrates generating capabilities-secure Pony actor code with:
# - Type-safe, memory-safe actors
# - Data-race freedom guaranteed at compile time
# - Callback traits for customization
# - PonyTest tests
# All from one portable Elixir script!

Mix.install([
  # Use path for local development, or "~> 0.2.0" when generators are published
  {:gen_server_virtual_time, path: Path.join(__DIR__, "..")}
])

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║  Single-File Pony Generator Example                       ║
║  Generate capabilities-secure actor code in one script!   ║
╚═══════════════════════════════════════════════════════════╝
""")

# Define a load-balanced system
simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:load_balancer,
    send_pattern: {:rate, 100, :request},
    targets: [:server1, :server2, :server3]
  )
  |> ActorSimulation.add_actor(:server1, targets: [:database])
  |> ActorSimulation.add_actor(:server2, targets: [:database])
  |> ActorSimulation.add_actor(:server3, targets: [:database])
  |> ActorSimulation.add_actor(:database)

# Generate Pony code with callback traits
{:ok, files} =
  ActorSimulation.PonyGenerator.generate(simulation,
    project_name: "loadbalanced_actors",
    enable_callbacks: true
  )

# Write to output directory
output_dir = "generated/pony_loadbalanced"
ActorSimulation.PonyGenerator.write_to_directory(files, output_dir)

IO.puts("""

✅ Generated #{length(files)} files in #{output_dir}/

Key files:
  - *.pony                     Pony actors
  - *_callbacks.pony           Callback traits
  - test/test.pony             PonyTest tests
  - Makefile                   Build targets

🎯 Why Pony?
  ✓ Type safe + Memory safe
  ✓ Data-race free (guaranteed!)
  ✓ Deadlock free (no locks!)
  ✓ Zero-cost abstractions

To build and run:
  cd #{output_dir}
  make build
  ./loadbalanced_actors

To run tests:
  make test

📖 Prerequisites:
  curl --proto '=https' --tlsv1.2 -sSf \\
    https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh | sh
  ponyup update ponyc release
  ponyup update corral release
""")

