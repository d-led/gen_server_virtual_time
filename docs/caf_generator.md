# CAF Actor Framework Code Generation

Export ActorSimulation DSL to production-grade
[C++ Actor Framework (CAF)](https://actor-framework.org/) code with **callback
interfaces** for customization.

## Quick Example

```elixir
# Define your simulation in Elixir
simulation = ActorSimulation.new()
  |> ActorSimulation.add_actor(:publisher,
      send_pattern: {:periodic, 100, :event},
      targets: [:subscriber1, :subscriber2, :subscriber3])
  |> ActorSimulation.add_actor(:subscriber1)
  |> ActorSimulation.add_actor(:subscriber2)
  |> ActorSimulation.add_actor(:subscriber3)

# Generate CAF project with callback interfaces
{:ok, files} = ActorSimulation.CAFGenerator.generate(simulation,
  project_name: "PubSubActors",
  enable_callbacks: true)

ActorSimulation.CAFGenerator.write_to_directory(files, "caf_output/")
```

## Generated Files

- `*_actor.hpp/cpp` - CAF actor implementations (DO NOT EDIT)
- `*_callbacks.hpp` - Callback interfaces (DO NOT EDIT)
- `*_callbacks_impl.cpp` - **Your custom code goes here!**
- `test_actors.cpp` - [Catch2](https://github.com/catchorg/Catch2) tests
- `CMakeLists.txt` - CMake with test target
- `conanfile.txt` - CAF + Catch2 dependencies
- `.github/workflows/ci.yml` - CI pipeline

## Key Feature: Customize WITHOUT touching generated code!

```cpp
// publisher_callbacks_impl.cpp (EDIT THIS!)
void publisher_callbacks::on_event() {
  // Add your business logic here!
  std::cout << "Custom behavior!" << std::endl;
  log_to_database();
  send_metrics();
}
```

## Why CAF?

- Production-ready actor systems in C++
- Type-safe message passing
- Distributed actors across networks
- **Callback interfaces for clean customization**
- Built-in Catch2 tests with CI validation

## Try the Demos

```bash
mix run examples/caf_demo.exs
cd examples/caf_pubsub
# See generated C++ code with tests!
```

## Building Generated Code

```bash
cd caf_output/

# Install dependencies with Conan
mkdir build && cd build
conan install .. --build=missing

# Configure with CMake
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build .

# Run tests
./test_actors
```

## Installation Requirements

- **CMake 3.15+**
- **C++17 compiler** (GCC 7+, Clang 5+, MSVC 2017+)
- **Conan 1.x or 2.x** - For CAF and Catch2 dependencies

Install Conan:

```bash
pip install conan
```

## Development Workflow

1. **Define** actors in Elixir DSL
2. **Generate** CAF code with callbacks
3. **Implement** custom logic in `*_callbacks_impl.cpp`
4. **Test** with generated Catch2 tests
5. **CI** validates on every push

## Example: Pipeline Pattern

```elixir
simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:source,
      send_pattern: {:rate, 100, :data},
      targets: [:processor])
  |> ActorSimulation.add_actor(:processor,
      targets: [:sink])
  |> ActorSimulation.add_actor(:sink)

{:ok, files} = ActorSimulation.CAFGenerator.generate(simulation,
  project_name: "PipelineActors",
  enable_callbacks: true)
```

Generated structure:

```
caf_output/
├── source_actor.hpp/cpp       # CAF actor (generated)
├── source_callbacks.hpp        # Interface (generated)
├── source_callbacks_impl.cpp   # YOUR CODE HERE
├── processor_actor.hpp/cpp     # CAF actor (generated)
├── processor_callbacks.hpp     # Interface (generated)
├── processor_callbacks_impl.cpp # YOUR CODE HERE
├── sink_actor.hpp/cpp          # CAF actor (generated)
├── sink_callbacks.hpp          # Interface (generated)
├── sink_callbacks_impl.cpp     # YOUR CODE HERE
├── test_actors.cpp             # Catch2 tests
├── CMakeLists.txt
├── conanfile.txt
└── .github/workflows/ci.yml
```

## Callback Pattern Details

**Generated Interface (DO NOT EDIT):**

```cpp
// processor_callbacks.hpp
class processor_callbacks {
public:
  virtual void on_data_received() = 0;
  virtual void on_timer_tick() = 0;
  virtual ~processor_callbacks() = default;
};
```

**Your Implementation (EDIT THIS):**

```cpp
// processor_callbacks_impl.cpp
void processor_callbacks::on_data_received() {
  // Transform data
  auto result = process(input);

  // Log metrics
  metrics.increment("processed");

  // Forward to next stage
  forward_to_sink(result);
}

void processor_callbacks::on_timer_tick() {
  flush_buffers();
}
```

## Generated Tests

The generator creates Catch2 tests:

```cpp
TEST_CASE("Source actor sends messages", "[source]") {
  auto sys = caf::actor_system{cfg};
  auto source = sys.spawn<source_actor>();

  // Test message generation
  self->send(source, start_atom::value);
  self->receive(
    [&](data_msg msg) {
      REQUIRE(msg.id > 0);
    }
  );
}
```

Run tests:

```bash
./test_actors
```

## CI Integration

Generated `.github/workflows/ci.yml` validates:

- ✅ Code compiles on Linux, macOS, Windows
- ✅ All tests pass
- ✅ Multiple compiler versions (GCC, Clang, MSVC)

## Limitations

Currently supports:

- ✅ Basic send patterns (periodic, rate, burst)
- ✅ Point-to-point messaging
- ✅ Callback interfaces
- ✅ Catch2 test generation
- ✅ CI pipeline

Not yet supported:

- ❌ Complex state machines
- ❌ Dynamic topology
- ❌ Custom message types
- ❌ Distributed deployment configs

## Contributing

Extend the generator:

- Add custom message type generation
- Implement state machine translation
- Support distributed configurations
- Add more test patterns

See `lib/actor_simulation/caf_generator.ex` and tests.
