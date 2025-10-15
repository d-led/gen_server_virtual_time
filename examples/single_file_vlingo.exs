#!/usr/bin/env elixir

# Single-file Elixir script to generate VLINGO XOOM (Java) actor code
# Run with: elixir examples/single_file_vlingo.exs
#
# This demonstrates generating Java actor code using VLINGO XOOM with:
# - Type-safe protocol actors
# - Scheduler-based message delivery
# - Maven build configuration
# - JUnit 5 test suites
# - Callback interfaces for customization
# All from one portable Elixir script!

Mix.install([
  # Use path for local development, or "~> 0.4.0" when published
  {:gen_server_virtual_time, path: Path.join(__DIR__, "..")}
])

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║  Single-File VLINGO XOOM (Java) Generator Example        ║
║  Generate Java actor code in one script!                 ║
╚═══════════════════════════════════════════════════════════╝
""")

# Define a data pipeline system
simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:producer,
    send_pattern: {:rate, 100, :data},
    targets: [:processor]
  )
  |> ActorSimulation.add_actor(:processor,
    targets: [:consumer]
  )
  |> ActorSimulation.add_actor(:consumer)

# Generate VLINGO XOOM (Java) code with callback interfaces
{:ok, files} =
  ActorSimulation.VlingoGenerator.generate(simulation,
    project_name: "pipeline-actors",
    group_id: "com.example.actors",
    enable_callbacks: true
  )

# Write to output directory
output_dir = "generated/vlingo_pipeline"
ActorSimulation.VlingoGenerator.write_to_directory(files, output_dir)

IO.puts("""

✅ Generated #{length(files)} files in #{output_dir}/

Key files:
  - src/main/java/**/*Actor.java         Protocol actors
  - src/main/java/**/*Protocol.java      Actor interfaces
  - src/main/java/**/*CallbacksImpl.java YOUR CUSTOM CODE HERE!
  - src/test/java/**/*ActorTest.java     JUnit 5 tests
  - pom.xml                              Maven build configuration

🎯 Why VLINGO XOOM?
  ✓ Type-safe protocol-based actors
  ✓ Enterprise-ready Java framework
  ✓ Reactive foundation for distributed systems
  ✓ Scheduled message delivery
  ✓ Clean separation: generated code + user callbacks

To build and run:
  cd #{output_dir}
  mvn compile
  mvn exec:java

To run tests:
  mvn test

To run tests with output:
  mvn test -X

📖 Prerequisites:
  Java 11+ and Maven 3.6+ (https://maven.apache.org/)
""")
