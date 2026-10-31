# Pony Generator

Generate capabilities-secure Pony actor code with type safety and data-race
freedom guaranteed at compile time.

## Quick Start

```elixir
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

## Why Pony?

Pony is a capabilities-secure, actor-model language that provides:

✅ **Type Safety** - No null pointers, no buffer overruns  
✅ **Memory Safety** - No dangling pointers, no memory leaks  
✅ **Data-Race Freedom** - Guaranteed at compile time  
✅ **Deadlock Freedom** - No locks, no deadlocks  
✅ **High Performance** - Zero-cost abstractions

## Generated Files

- **Actor files** (`*.pony`) - Pony actor implementations
- **Callback traits** (`*_callbacks.pony`) - Trait definitions & implementations
- **Tests** (`test/test.pony`) - PonyTest test suite
- **Build files** (`Makefile`, `corral.json`) - Make + Corral
- **CI pipeline** (`.github/workflows/ci.yml`) - GitHub Actions

## Features

✅ Type-safe actor behaviors  
✅ Callback traits (Notifier pattern)  
✅ PonyTest automated tests  
✅ Timer-based scheduling  
✅ CI/CD pipeline included

## Examples

See the complete generated project in the repository at `examples/pony_pubsub/`.

Try the single-file script: `examples/single_file_pony.exs`

## Building Generated Code

### Prerequisites

```bash
# Install ponyup
curl --proto '=https' --tlsv1.2 -sSf \
  https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh | sh

# Install pony compiler and corral
ponyup update ponyc release
ponyup update corral release
```

### Build and Run

```bash
cd pony_output/

# Build
make build

# Run
./my_actors

# Test
make test
```

## Learn More

- [Pony Tutorial](https://tutorial.ponylang.io/)
- [Pony Patterns](https://patterns.ponylang.io/)
- [Pony Standard Library](https://stdlib.ponylang.io/)
- [Generator Comparison](generators.md#comparison)
