# loadbalanced_actors

Generated from ActorSimulation DSL using Pony.

## About

This project uses [Pony](https://www.ponylang.io/), a capabilities-secure,
actor-model language that provides:

- **Type Safety** - No null pointers, no buffer overruns
- **Memory Safety** - No dangling pointers, no memory leaks
- **Data-Race Freedom** - Guaranteed at compile time
- **Deadlock Freedom** - No locks, no deadlocks
- **High Performance** - Zero-cost abstractions

The code is generated from a high-level Elixir DSL and provides:
- Type-safe actor implementations
- Callback traits for custom behavior
- Built-in PonyTest tests
- Production-ready code

## Prerequisites

- **Ponyup** - Pony toolchain manager
- **Pony compiler** (installed via ponyup)
- **Corral** - Pony dependency manager (installed via ponyup)

### Installation

```bash
# Install ponyup
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh | sh

# Install pony compiler and corral
ponyup update ponyc release
ponyup update corral release
```

## Building

```bash
# Fetch dependencies
corral fetch

# Build the project
ponyc .

# Run
./loadbalanced_actors
```

## Testing

```bash
# Build and run tests
ponyc test
./test  # or ./test1 depending on directory name
```

## Customizing Behavior

The generated actor code uses callback traits to allow customization WITHOUT
modifying generated files:

1. Find the `*_callbacks.pony` files
2. Edit the `*CallbacksImpl` class implementations
3. Add your custom logic in the callback methods
4. Rebuild the project

The generated actor code will automatically call your callbacks.

## Project Structure

- `main.pony` - Entry point and actor system setup
- `*_actor.pony` - Generated actor implementations (DO NOT EDIT)
- `*_callbacks.pony` - Callback traits and implementations (EDIT IMPL CLASS!)
- `test/test.pony` - PonyTest test suite
- `corral.json` - Dependency configuration

## CI/CD

This project includes a GitHub Actions workflow that:
- Builds on Ubuntu and macOS
- Runs all PonyTest tests
- Validates the build with each commit

## Learn More

- [Pony Tutorial](https://tutorial.ponylang.io/)
- [Pony Standard Library](https://stdlib.ponylang.io/)
- [Pony GitHub](https://github.com/ponylang/ponyc)
- [ActorSimulation DSL](https://github.com/yourusername/gen_server_virtual_time)

## License

Generated code is provided as-is for your use.
