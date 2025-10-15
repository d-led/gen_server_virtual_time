# Ractor (Rust) Generator

Generate production-ready Rust actor code using the Ractor actor library.

## Quick Start

```elixir
simulation = ActorSimulation.new()
  |> ActorSimulation.add_actor(:worker,
      send_pattern: {:rate, 100, :task},
      targets: [:processor])
  |> ActorSimulation.add_actor(:processor)

{:ok, files} = ActorSimulation.RactorGenerator.generate(simulation,
  project_name: "my_actors",
  enable_callbacks: true)

ActorSimulation.RactorGenerator.write_to_directory(files, "ractor_out/")
```

## Why Ractor?

[Ractor](https://github.com/slawlor/ractor) is a pure-Rust actor framework
explicitly inspired by Erlang's gen_server that provides:

✅ **Supervision trees** - OTP-style supervision and fault tolerance  
✅ **Actor registry** - Named actor lookup like Erlang  
✅ **RPC support** - Call and cast patterns (gen_server semantics)  
✅ **Built-in timers** - Native scheduling support  
✅ **Runtime-agnostic** - Tokio-based but flexible  
✅ **Type safety** - Leverages Rust's type system

## Generated Files

- **Actor files** (`src/actors/*.rs`) - Ractor actor implementations with
  callbacks
- **Module** (`src/actors/mod.rs`) - Module declarations
- **Main** (`src/main.rs`) - Entry point and actor spawning
- **Tests** (`tests/integration_test.rs`) - Integration test suite
- **Cargo** (`Cargo.toml`) - Package manifest with Ractor dependency
- **CI** (`.github/workflows/ci.yml`) - GitHub Actions

## Features

✅ Ractor `Actor` trait implementation  
✅ Callback traits for customization  
✅ Tokio async runtime integration  
✅ Integration tests with `#[tokio::test]`  
✅ Multi-platform CI (Linux, macOS, Windows)  
✅ Stable and beta Rust channels tested  
✅ Clippy and rustfmt checks

## Code Structure

### Actor Implementation

```rust
pub struct Worker;

#[ractor::async_trait]
impl Actor for Worker {
    type Msg = WorkerMessage;
    type State = WorkerState;
    type Arguments = ();

    async fn pre_start(
        &self,
        myself: ActorRef<Self::Msg>,
        _: Self::Arguments,
    ) -> Result<Self::State, ActorProcessingErr> {
        // Initialize state and spawn timers
        Ok(WorkerState { /* ... */ })
    }

    async fn handle(
        &self,
        myself: ActorRef<Self::Msg>,
        message: Self::Msg,
        state: &mut Self::State,
    ) -> Result<(), ActorProcessingErr> {
        // Handle messages
        Ok(())
    }
}
```

### Callback Traits

Customize behavior without modifying generated code:

```rust
pub trait WorkerCallbacks: Send + Sync {
    fn on_task(&self);
}

pub struct DefaultWorkerCallbacks;

impl WorkerCallbacks for DefaultWorkerCallbacks {
    fn on_task(&self) {
        // Your custom logic here
        println!("Processing task!");
    }
}
```

## Examples

See the complete generated project in the repository at
`examples/ractor_pubsub/`.

Try the single-file script: `examples/single_file_ractor.exs`

## Building Generated Code

```bash
cd ractor_output/

# Build in debug mode
cargo build

# Build optimized release
cargo build --release

# Run
cargo run --release

# Test
cargo test

# Test with output
cargo test -- --nocapture

# Run clippy
cargo clippy

# Format code
cargo fmt
```

## Patterns

### Periodic Messages

```elixir
send_pattern: {:periodic, 100, :tick}
```

Generates a timer that sends `:tick` every 100ms using `tokio::time::interval`.

### Rate-Based Messages

```elixir
send_pattern: {:rate, 50, :event}
```

Generates 50 messages per second (20ms interval).

### Burst Messages

```elixir
send_pattern: {:burst, 10, 500, :batch}
```

Sends 10 messages every 500ms in a burst.

### Self Messages

```elixir
send_pattern: {:self_message, 1000, :timeout}
```

One-shot delayed message (1 second delay) using `tokio::time::sleep`.

## Configuration

```elixir
{:ok, files} = ActorSimulation.RactorGenerator.generate(simulation,
  project_name: "my_actors",      # Cargo package name
  enable_callbacks: true,          # Generate callback traits
  rust_edition: "2021",            # Rust edition (2015, 2018, 2021)
  ractor_version: "0.12"           # Ractor crate version
)
```

## Learn More

- [Ractor GitHub](https://github.com/slawlor/ractor)
- [Rust Async Book](https://rust-lang.github.io/async-book/)
- [Tokio Tutorial](https://tokio.rs/tokio/tutorial)
- [Generator Comparison](generators.md#comparison)
