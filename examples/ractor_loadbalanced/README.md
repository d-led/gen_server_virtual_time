# loadbalanced_actors

Generated from ActorSimulation DSL using Ractor (Rust actor library).

## About

This project uses [Ractor](https://github.com/slawlor/ractor), a pure-Rust actor
framework inspired by Erlang's gen_server that provides:

- **Supervision trees** - OTP-style supervision and fault tolerance
- **Actor registry** - Named actor lookup
- **RPC support** - Call and cast patterns like gen_server
- **Timers** - Built-in timer support
- **Runtime-agnostic** - Works with Tokio

The code is generated from a high-level Elixir DSL and provides:
- Ractor actor implementations
- Callback traits for customization
- Integration test suites
- Production-ready code

## Prerequisites

- **Rust 1.70+** (stable toolchain recommended)
- **Cargo** (comes with Rust)

## Building

```bash
# Build in debug mode
cargo build

# Build optimized release
cargo build --release

# Run
cargo run --release
```

## Testing

```bash
# Run all tests
cargo test

# Run tests with output
cargo test -- --nocapture

# Run specific test
cargo test test_actor_system
```

## Customizing Behavior

The generated actor code uses callback traits to allow customization WITHOUT
modifying generated files:

1. Find the `*_callbacks.rs` files in `src/actors/`
2. Modify the `Default*Callbacks` implementation
3. Add your custom logic in the callback methods
4. Rebuild

Example:
```rust
impl WorkerCallbacks for DefaultWorkerCallbacks {
    fn on_tick(&self) {
        // Your custom logic here
        println!("Custom tick handler!");
    }
}
```

## Project Structure

- `src/main.rs` - Entry point and actor spawning
- `src/actors/*.rs` - Generated actor implementations (DO NOT EDIT)
- `src/actors/*_callbacks.rs` - Callback implementations (EDIT THIS!)
- `tests/` - Integration test suite
- `Cargo.toml` - Package configuration

## CI/CD

This project includes a GitHub Actions workflow that:
- Builds on Ubuntu, macOS, and Windows
- Tests with stable and beta Rust
- Runs clippy and formatting checks
- Validates the build with each commit

## Learn More

- [Ractor GitHub](https://github.com/slawlor/ractor)
- [Rust Async Book](https://rust-lang.github.io/async-book/)
- [ActorSimulation DSL](https://github.com/d-led/gen_server_virtual_time)

## License

Generated code is provided as-is for your use.
