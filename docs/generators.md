# Code Generators - Quick Start Guide

This library includes **four production-ready code generators** that translate
ActorSimulation DSL into different languages and frameworks.

## Single-File Script Examples

Following
[Fly.io's single-file Elixir pattern](https://fly.io/phoenix-files/single-file-elixir-scripts/),
you can generate complete projects with just `Mix.install`!

### OMNeT++ (Network Simulation)

```elixir
#!/usr/bin/env elixir
Mix.install([{:gen_server_virtual_time, "~> 0.2.0"}])

simulation = ActorSimulation.new()
  |> ActorSimulation.add_actor(:sender,
      send_pattern: {:periodic, 100, :msg},
      targets: [:receiver])
  |> ActorSimulation.add_actor(:receiver)

{:ok, files} = ActorSimulation.OMNeTPPGenerator.generate(simulation,
  network_name: "SimpleNetwork")

ActorSimulation.OMNeTPPGenerator.write_to_directory(files, "omnetpp_out/")
```

### CAF (C++ Actor Framework)

```elixir
#!/usr/bin/env elixir
Mix.install([{:gen_server_virtual_time, "~> 0.2.0"}])

simulation = ActorSimulation.new()
  |> ActorSimulation.add_actor(:worker,
      send_pattern: {:rate, 50, :task},
      targets: [:processor])
  |> ActorSimulation.add_actor(:processor)

{:ok, files} = ActorSimulation.CAFGenerator.generate(simulation,
  project_name: "MyActors",
  enable_callbacks: true)  # Callback interfaces!

ActorSimulation.CAFGenerator.write_to_directory(files, "caf_out/")
```

### Pony (Capabilities-Secure)

```elixir
#!/usr/bin/env elixir
Mix.install([{:gen_server_virtual_time, "~> 0.2.0"}])

simulation = ActorSimulation.new()
  |> ActorSimulation.add_actor(:sender,
      send_pattern: {:burst, 10, 1000, :batch},
      targets: [:receiver])
  |> ActorSimulation.add_actor(:receiver)

{:ok, files} = ActorSimulation.PonyGenerator.generate(simulation,
  project_name: "my_actors",
  enable_callbacks: true)

ActorSimulation.PonyGenerator.write_to_directory(files, "pony_out/")
```

### Phony (Go Actors)

```elixir
#!/usr/bin/env elixir
Mix.install([{:gen_server_virtual_time, "~> 0.2.0"}])

simulation = ActorSimulation.new()
  |> ActorSimulation.add_actor(:worker,
      send_pattern: {:periodic, 100, :tick},
      targets: [:processor])
  |> ActorSimulation.add_actor(:processor)

{:ok, files} = ActorSimulation.PhonyGenerator.generate(simulation,
  project_name: "my_actors",
  enable_callbacks: true)

ActorSimulation.PhonyGenerator.write_to_directory(files, "phony_out/")
```

## Complete Examples

See the [`examples/`](../examples/) directory for complete single-file scripts:

- [`single_file_omnetpp.exs`](../examples/single_file_omnetpp.exs)
- [`single_file_caf.exs`](../examples/single_file_caf.exs)
- [`single_file_pony.exs`](../examples/single_file_pony.exs)
- [`single_file_phony.exs`](../examples/single_file_phony.exs)

## Comparison

| Generator   | Purpose            | Output           | Key Feature               |
| ----------- | ------------------ | ---------------- | ------------------------- |
| **OMNeT++** | Network simulation | NED + C++        | GUI tools, INET framework |
| **CAF**     | Production actors  | C++ + Catch2     | Callback interfaces       |
| **Pony**    | Safe concurrency   | Type-safe actors | Data-race freedom         |
| **Phony**   | Go actors          | Go + tests       | Zero-allocation messaging |

## Development Workflow

1. **Prototype** in Elixir (fast iteration)
2. **Test** with virtual time (deterministic)
3. **Visualize** with sequence diagrams
4. **Generate** to your target language
5. **Deploy** to production

## Why Single-File Scripts?

Benefits of using `Mix.install` for code generation:

✅ **Portable** - One file, no setup required  
✅ **Reproducible** - Same input = same output  
✅ **Shareable** - GitHub gist, email, anywhere  
✅ **Isolated** - No impact on your main projects  
✅ **Fast** - Generate code in seconds

Perfect for:

- Bug reports with minimal examples
- Quick prototyping
- CI/CD pipelines
- Teaching and demos

## Learn More

- [OMNeT++ Generator](omnetpp_generator.md)
- [CAF Generator](caf_generator.md)
- [Pony Generator](pony_generator.md)
- [Phony Generator](phony_generator.md)
- [Implementation Details](implementation_summary.md)

## Next Steps

1. Try a single-file example
2. Choose your target framework
3. Generate production code
4. Customize via callbacks
5. Deploy with confidence!
