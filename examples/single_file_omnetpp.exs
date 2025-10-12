#!/usr/bin/env elixir

# Single-file Elixir script to generate OMNeT++ code
# Run with: elixir examples/single_file_omnetpp.exs
#
# This demonstrates using Mix.install to generate production C++ simulation code
# from a simple ActorSimulation DSL - all in one portable script!

Mix.install([
  # Use path for local development, or "~> 0.2.0" when generators are published
  {:gen_server_virtual_time, path: Path.join(__DIR__, "..")}
])

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║  Single-File OMNeT++ Generator Example                    ║
║  Generate network simulation C++ code in one script!      ║
╚═══════════════════════════════════════════════════════════╝
""")

# Define a simple pub-sub system
simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:publisher,
    send_pattern: {:periodic, 100, :event},
    targets: [:subscriber1, :subscriber2, :subscriber3]
  )
  |> ActorSimulation.add_actor(:subscriber1)
  |> ActorSimulation.add_actor(:subscriber2)
  |> ActorSimulation.add_actor(:subscriber3)

# Generate OMNeT++ C++ code
{:ok, files} =
  ActorSimulation.OMNeTPPGenerator.generate(simulation,
    network_name: "PubSubNetwork",
    sim_time_limit: 10
  )

# Write to output directory
output_dir = "generated/omnetpp_pubsub"
ActorSimulation.OMNeTPPGenerator.write_to_directory(files, output_dir)

IO.puts("""

✅ Generated #{length(files)} files in #{output_dir}/

Key files:
  - PubSubNetwork.ned     Network topology
  - Publisher.h/cc        C++ simple modules
  - Subscriber*.h/cc      Receivers
  - CMakeLists.txt        Build configuration
  - omnetpp.ini          Simulation parameters

To build and run:
  cd #{output_dir}
  mkdir build && cd build
  cmake ..
  make
  ./PubSubNetwork -u Cmdenv

📖 See OMNETPP_GENERATOR.md for more details
""")

