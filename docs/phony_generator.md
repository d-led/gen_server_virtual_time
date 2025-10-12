# Phony (Go) Generator

Generate high-performance Go actor code using the Phony actor library.

## Quick Start

```elixir
simulation = ActorSimulation.new()
  |> ActorSimulation.add_actor(:worker,
      send_pattern: {:rate, 100, :task},
      targets: [:processor])
  |> ActorSimulation.add_actor(:processor)

{:ok, files} = ActorSimulation.PhonyGenerator.generate(simulation,
  project_name: "my_actors",
  enable_callbacks: true)

ActorSimulation.PhonyGenerator.write_to_directory(files, "phony_out/")
```

## Why Phony?

[Phony](https://github.com/Arceliar/phony) is a Pony-inspired actor library for
Go that provides:

✅ **Zero-allocation messaging** - Efficient lock-free message passing  
✅ **Automatic goroutine management** - No goroutine leaks  
✅ **Backpressure support** - Built-in flow control  
✅ **Lock-free operations** - No mutexes or channels needed  
✅ **Causal messaging** - Message ordering guarantees

## Generated Files

- **Actor files** (`*.go`) - Phony actor implementations with callbacks
- **Main** (`main.go`) - Entry point and actor spawning
- **Tests** (`actor_test.go`) - Go test suite
- **Module** (`go.mod`) - Go module with Phony dependency
- **Build** (`Makefile`) - Build targets
- **CI** (`.github/workflows/ci.yml`) - GitHub Actions

## Features

✅ Phony inbox embedding  
✅ Callback interfaces for customization  
✅ Go tests with `testing` package  
✅ Timer-based scheduling  
✅ Multi-platform CI (Linux, macOS, Windows)  
✅ Multiple Go versions tested

## Examples

See [`examples/phony_pubsub/`](../examples/phony_pubsub/) for a complete
generated project.

Try the single-file script:
[`examples/single_file_phony.exs`](../examples/single_file_phony.exs)

## Building Generated Code

```bash
cd phony_output/

# Download dependencies
go mod download

# Build
go build -o my_actors .

# Run
./my_actors

# Test
go test -v ./...
```

## Learn More

- [Phony GitHub](https://github.com/Arceliar/phony)
- [Go Modules](https://go.dev/blog/using-go-modules)
- [Generator Comparison](generators.md#comparison)
