#!/usr/bin/env elixir

# Single-file Elixir script to generate Ractor (Rust) actor code
# Run with: elixir examples/single_file_ractor.exs
#
# This demonstrates generating Rust actor code using Ractor library with:
# - Gen_server-inspired actor model
# - OTP-style supervision trees
# - Tokio async runtime
# - Callback traits for customization
# - Integration tests
# All from one portable Elixir script!

Mix.install([
  # Use path for local development, or "~> 0.6.0" when published
  {:gen_server_virtual_time, path: Path.join(__DIR__, "..")}
])

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║  Single-File Ractor (Rust) Generator Example             ║
║  Generate Rust actor code in one script!                 ║
╚═══════════════════════════════════════════════════════════╝
""")

# Define a data pipeline system
simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:producer,
    send_pattern: {:rate, 100, :data},
    targets: [:transformer]
  )
  |> ActorSimulation.add_actor(:transformer,
    targets: [:sink]
  )
  |> ActorSimulation.add_actor(:sink)

# Generate Ractor (Rust) code with callback traits
{:ok, files} =
  ActorSimulation.RactorGenerator.generate(simulation,
    project_name: "pipeline_actors",
    enable_callbacks: true
  )

# Write to output directory
output_dir = "generated/ractor_pipeline"
ActorSimulation.RactorGenerator.write_to_directory(files, output_dir)

IO.puts("""

✅ Generated #{length(files)} files in #{output_dir}/

Key files:
  - src/actors/*.rs           Rust actors with Ractor
  - *Callbacks trait          Customize behavior
  - tests/integration_test.rs Integration tests
  - Cargo.toml                Package manifest

🎯 Why Ractor?
  ✓ Gen_server-inspired API (familiar to Elixir devs!)
  ✓ OTP-style supervision trees
  ✓ Type-safe message passing
  ✓ Tokio async runtime
  ✓ Named actor registry

To build and run:
  cd #{output_dir}
  cargo build --release
  cargo run --release

To run tests:
  cargo test

To run tests with output:
  cargo test -- --nocapture

📖 Prerequisites:
  Rust 1.70+ (https://rustup.rs/)
""")

