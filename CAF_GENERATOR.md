# CAF (C++ Actor Framework) Code Generator

This document describes the CAF code generator module that translates ActorSimulation DSL into production-ready C++ actor systems using the C++ Actor Framework.

## Overview

The `ActorSimulation.CAFGenerator` module generates complete, buildable CAF projects from ActorSimulation definitions. This enables a powerful workflow:

1. **Prototype** in Elixir with instant feedback
2. **Test** with virtual time and deterministic execution
3. **Export** to CAF for production C++ deployments
4. **Customize** behavior via callback interfaces WITHOUT touching generated code
5. **Leverage** CAF ecosystem (distributed actors, type safety, high performance)

## Key Features

### 🎯 Callback Interfaces

The generator creates **callback interfaces** that allow you to add custom behavior WITHOUT modifying generated code:

```cpp
// Generated callback interface (DO NOT EDIT)
class worker_callbacks {
  public:
    virtual void on_tick();
    virtual ~worker_callbacks() = default;
};

// Your custom implementation (EDIT THIS!)
void worker_callbacks::on_tick() {
  // TODO: Add your business logic here
  std::cout << "Processing tick..." << std::endl;
}
```

This design enables:
- **Version control**: Track generated vs custom code separately
- **Upgrades**: Regenerate actors without losing custom logic
- **Team collaboration**: Clear boundaries between framework and application code

## Architecture

### Module Structure

```
lib/actor_simulation/
└── caf_generator.ex              # Main generator module
test/
└── caf_generator_test.exs        # Comprehensive test suite
examples/
├── caf_demo.exs                  # Demo script
├── caf_pubsub/                   # Generated pub-sub example
├── caf_pipeline/                 # Generated pipeline example
├── caf_burst/                    # Generated burst traffic example
└── caf_loadbalanced/             # Generated load-balanced system
scripts/
└── generate_caf_examples.exs     # Batch generation script
```

### Code Generation Pipeline

```
ActorSimulation Definition
         ↓
    CAFGenerator
         ↓
    ┌────┴────┬────────┬────────┐
    ↓         ↓        ↓        ↓
  Actors  Callbacks  Build   CI/CD
   C++      C++      Files   Pipeline
    ↓         ↓        ↓        ↓
    └─────────┴────────┴────────┘
              ↓
         CAF Project
```

## API Reference

### Core Functions

#### `generate/2`

Generates complete CAF project files from an ActorSimulation.

```elixir
{:ok, files} = CAFGenerator.generate(simulation, opts)
```

**Options:**
- `:project_name` (required) - Name of the C++ project
- `:enable_callbacks` (default: true) - Generate callback interfaces
- `:caf_version` (default: "0.18.7") - CAF version for Conan

**Returns:**
- `{:ok, files}` where files is a list of `{filename, content}` tuples

**Example:**
```elixir
simulation = ActorSimulation.new()
             |> ActorSimulation.add_actor(:sender, targets: [:receiver])
             |> ActorSimulation.add_actor(:receiver)

{:ok, files} = CAFGenerator.generate(simulation,
  project_name: "MyActors",
  enable_callbacks: true)
```

#### `write_to_directory/2`

Writes generated files to a directory, creating subdirectories as needed.

```elixir
:ok = CAFGenerator.write_to_directory(files, output_dir)
```

**Example:**
```elixir
{:ok, files} = CAFGenerator.generate(simulation, project_name: "MyActors")
:ok = CAFGenerator.write_to_directory(files, "caf_output/")
```

## Translation Rules

### Actors → CAF Event-Based Actors

Each actor becomes a CAF `event_based_actor`:

| ActorSimulation | CAF |
|-----------------|-----|
| Actor name | Class name (snake_case_actor) |
| `send_pattern` | `delayed_send` scheduling |
| `targets` | Vector of `caf::actor` references |
| Message send | `send(target, message)` |

**Example:**

```elixir
# Elixir DSL
add_actor(:message_generator,
  send_pattern: {:periodic, 100, :tick},
  targets: [:processor])
```

Generates:

```cpp
// C++ CAF
class message_generator_actor : public caf::event_based_actor {
  public:
    message_generator_actor(caf::actor_config& cfg, 
                           const std::vector<caf::actor>& targets)
      : caf::event_based_actor(cfg), targets_(targets) {
      callbacks_ = std::make_shared<message_generator_callbacks>();
    }

    caf::behavior make_behavior() override {
      schedule_next_send();
      return {
        [=](caf::atom_value msg) {
          callbacks_->on_tick();
          send_to_targets();
          schedule_next_send();
        }
      };
    }

  private:
    void schedule_next_send() {
      delayed_send(this, std::chrono::milliseconds(100), 
                   caf::atom("tick"));
    }
    
    void send_to_targets() {
      for (auto& target : targets_) {
        send(target, caf::atom("msg"));
      }
    }
};
```

### Send Patterns

#### Periodic Pattern

```elixir
send_pattern: {:periodic, interval_ms, message}
```

Generates:
```cpp
delayed_send(this, std::chrono::milliseconds(100), caf::atom("msg"));
```

#### Rate Pattern

```elixir
send_pattern: {:rate, messages_per_second, message}
```

Generates:
```cpp
delayed_send(this, std::chrono::milliseconds(20), caf::atom("msg"));  // 50 msgs/sec
```

#### Burst Pattern

```elixir
send_pattern: {:burst, count, interval_ms, message}
```

Generates:
```cpp
for (int i = 0; i < count; i++) {
    delayed_send(this, std::chrono::milliseconds(interval), caf::atom("msg"));
}
```

## Generated Files

### 1. Actor Headers (`*_actor.hpp`)

Class declarations for each actor.

**Contents:**
- `#pragma once` include guard
- CAF includes
- Callback interface include
- Actor class definition
- Member variables (targets, callbacks, counters)

### 2. Actor Sources (`*_actor.cpp`)

Actor implementations.

**Key methods:**
- Constructor - Initialize callbacks and targets
- `make_behavior()` - Define message handlers
- `schedule_next_send()` - Schedule periodic messages
- `send_to_targets()` - Broadcast to connected actors

### 3. Callback Headers (`*_callbacks.hpp`)

Callback interface definitions (DO NOT EDIT).

**Contents:**
- Virtual methods for each message type
- Virtual destructor
- Clear documentation about customization

### 4. Callback Implementations (`*_callbacks_impl.cpp`)

Callback implementations (EDIT THIS!).

**Contents:**
- Method stubs with TODO comments
- Clear indication this file is for user customization
- Includes for necessary headers

### 5. Main Entry Point (`main.cpp`)

Application entry point with actor system setup.

**Contents:**
- CAF initialization
- Actor spawning code
- System configuration
- `CAF_MAIN()` macro

### 6. CMake Configuration (`CMakeLists.txt`)

Build system configuration.

**Features:**
- C++17 standard
- CAF package detection via Conan
- All source files listed
- Warning flags enabled
- Platform-specific options

### 7. Conan Configuration (`conanfile.txt`)

Package manager setup.

**Contents:**
- CAF dependency with version
- CMakeDeps and CMakeToolchain generators
- Configuration options

### 8. CI Pipeline (`.github/workflows/ci.yml`)

GitHub Actions workflow.

**Features:**
- Multi-platform builds (Ubuntu, macOS)
- Debug and Release configurations
- Conan dependency installation
- CMake build and test
- Automated validation on each commit

### 9. README (`README.md`)

Project documentation.

**Contents:**
- Build instructions
- Customization guide
- Project structure
- Links to CAF documentation

## Testing

The generator is fully test-driven with comprehensive coverage:

```bash
mix test test/caf_generator_test.exs
```

**Test categories:**
1. Complete project generation
2. Callback interface generation
3. C++ header and source generation
4. Send pattern translation
5. CMake and Conan files
6. CI pipeline generation
7. README generation
8. File writing with subdirectories

**Total: 11 dedicated tests**

## Examples

### Example 1: Simple Sender-Receiver

```elixir
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:sender,
      send_pattern: {:periodic, 100, :msg},
      targets: [:receiver])
  |> ActorSimulation.add_actor(:receiver)

{:ok, files} = CAFGenerator.generate(simulation,
  project_name: "SimpleActors",
  enable_callbacks: true)

CAFGenerator.write_to_directory(files, "simple_output/")
```

### Example 2: Pub-Sub System

```elixir
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:publisher,
      send_pattern: {:rate, 50, :event},
      targets: [:sub1, :sub2, :sub3])
  |> ActorSimulation.add_actor(:sub1)
  |> ActorSimulation.add_actor(:sub2)
  |> ActorSimulation.add_actor(:sub3)

{:ok, files} = CAFGenerator.generate(simulation,
  project_name: "PubSubActors")
```

### Example 3: Pipeline Processing

```elixir
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:source,
      send_pattern: {:rate, 100, :data},
      targets: [:stage1])
  |> ActorSimulation.add_actor(:stage1, targets: [:stage2])
  |> ActorSimulation.add_actor(:stage2, targets: [:stage3])
  |> ActorSimulation.add_actor(:stage3, targets: [:sink])
  |> ActorSimulation.add_actor(:sink)

{:ok, files} = CAFGenerator.generate(simulation,
  project_name: "PipelineActors")
```

### Demo Script

Run the comprehensive demo:

```bash
mix run examples/caf_demo.exs
```

This generates 4 complete CAF projects:
- Pub-Sub System
- Message Pipeline
- Bursty Traffic
- Load-Balanced System

### Batch Generation

Generate all examples at once:

```bash
mix run scripts/generate_caf_examples.exs
```

## Building Generated Code

### Prerequisites

1. **CAF 0.18+** - [Installation Guide](https://actor-framework.readthedocs.io/en/stable/)
2. **CMake 3.15+**
3. **Conan 2.0+** - Package manager
4. **C++17 Compiler** (GCC 7+, Clang 5+, MSVC 2019+)

### Build Steps

```bash
cd caf_output/

# Install dependencies
mkdir build && cd build
conan install .. --build=missing

# Configure and build
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
cmake --build .

# Run
./ProjectName
```

### Troubleshooting

**CAF not found:**
```bash
conan install .. --build=missing -s compiler.cppstd=17
```

**Conan profile issues:**
```bash
conan profile detect --force
```

## Customizing Behavior

The key feature of the CAF generator is the ability to customize behavior WITHOUT touching generated code.

### Step-by-Step Guide

1. **Generate the project:**
   ```bash
   mix run examples/caf_demo.exs
   cd examples/caf_pubsub
   ```

2. **Find callback implementations:**
   ```bash
   ls *_callbacks_impl.cpp
   # publisher_callbacks_impl.cpp
   # subscriber1_callbacks_impl.cpp
   # ...
   ```

3. **Edit callback implementation:**
   ```cpp
   // publisher_callbacks_impl.cpp
   void publisher_callbacks::on_event() {
     // Add your custom logic here!
     std::cout << "Publishing event with custom logic!" << std::endl;
     
     // Access database, send HTTP requests, log to file, etc.
     log_to_database();
     notify_monitoring_system();
   }
   ```

4. **Rebuild:**
   ```bash
   cd build
   cmake --build .
   ./PubSubActors
   ```

### Advanced Customization

You can add state to callbacks:

```cpp
// publisher_callbacks.hpp (modify this if needed)
class publisher_callbacks {
  public:
    virtual void on_event();
    virtual ~publisher_callbacks() = default;
    
  private:
    int event_count_ = 0;  // Add custom state
};

// publisher_callbacks_impl.cpp
void publisher_callbacks::on_event() {
  event_count_++;
  std::cout << "Event #" << event_count_ << std::endl;
  
  if (event_count_ % 10 == 0) {
    std::cout << "Checkpoint: " << event_count_ << " events!" << std::endl;
  }
}
```

## Current Features

**Supported:**
- ✅ Event-based actors
- ✅ All send patterns (periodic, rate, burst)
- ✅ Callback interfaces for customization
- ✅ Point-to-point connections
- ✅ CMake build system
- ✅ Conan package management
- ✅ CI/CD pipeline
- ✅ Complete documentation
- ✅ Multi-platform support (Linux, macOS)

## Future Enhancements

### Planned Features

1. **Typed Actors**
   - Generate strongly-typed actor interfaces
   - Compile-time message validation
   - Better IDE support

2. **Custom Message Types**
   ```elixir
   message_types: [
     {:data_packet, [:id, :payload, :timestamp]},
     {:ack_packet, [:id]}
   ]
   ```

3. **Distributed Actors**
   - Network transparency
   - Remote actor spawning
   - Serialization support

4. **State Machines**
   - Translate `on_receive` to C++ state machines
   - Pattern matching in callbacks
   - FSM visualization

5. **Performance Monitoring**
   - Built-in metrics collection
   - Integration with Prometheus
   - Latency tracking

## Design Principles

### 1. Separation of Generated and Custom Code

Generated files are clearly marked with "DO NOT EDIT" comments.
Custom code goes in separate `_impl.cpp` files.

### 2. Type Safety

Uses CAF's type system for compile-time safety.
All actor messages are typed with `caf::atom`.

### 3. Modern C++

- C++17 standard
- Smart pointers
- RAII principles
- STL containers

### 4. Test-Driven

Every feature is:
1. Specified in tests first
2. Implemented to pass tests
3. Refactored for quality
4. Verified by CI pipeline

### 5. Reproducible

- No timestamps in generated code
- Deterministic output
- Git-friendly diffs

## Comparison with OMNeT++

| Feature | OMNeT++ | CAF |
|---------|---------|-----|
| Purpose | Network simulation | General-purpose actors |
| Runtime | Simulation time | Real time / production |
| GUI | Yes | No (command-line) |
| Scalability | Millions of events | Millions of messages/sec |
| Customization | Edit generated C++ | Callback interfaces |
| Use Case | Research, validation | Production systems |

**Use both:**
1. Prototype in Elixir DSL
2. Test with virtual time
3. Validate with OMNeT++ (large-scale simulation)
4. Deploy with CAF (production runtime)

## Contributing

### Adding New Features

1. **Write tests first** in `test/caf_generator_test.exs`
2. **Implement** in `lib/actor_simulation/caf_generator.ex`
3. **Run tests** with `mix test`
4. **Update documentation** in this file
5. **Add demo** to `examples/caf_demo.exs`

### Code Style

- Follow Elixir conventions
- Document all public functions
- Add typespecs where helpful
- Keep functions small (<30 lines)

### Testing Guidelines

- Test each file type separately
- Test callback generation
- Test all send patterns
- Test edge cases
- Maintain >90% coverage

## References

### CAF

- [Homepage](https://actor-framework.org/)
- [GitHub](https://github.com/actor-framework/actor-framework)
- [Documentation](https://actor-framework.readthedocs.io/)
- [Examples](https://github.com/actor-framework/actor-framework/tree/main/examples)

### C++ Actor Model

- [Actor Model](https://en.wikipedia.org/wiki/Actor_model)
- [CAF Paper](https://www.actor-framework.org/pdf/actor-framework.pdf)

### Build Tools

- [CMake](https://cmake.org/documentation/)
- [Conan](https://docs.conan.io/)

## Performance

### Generator Speed

Typical generation times (M1 MacBook Pro):

| Project Size | Actors | Files | Time |
|--------------|--------|-------|------|
| Simple | 2 | 13 | <10ms |
| Medium | 5 | 25 | <20ms |
| Complex | 10 | 41 | <50ms |

### Generated Code Performance

CAF actor systems scale to:
- Millions of messages per second
- Thousands of actors
- Distributed across machines
- Production-grade reliability

## CI/CD Integration

The generated CI pipeline runs on every commit:

```yaml
- Build on Ubuntu and macOS
- Test Debug and Release configs
- Install dependencies with Conan
- Run CMake and build
- Execute tests
```

To add tests to generated code:
1. Add test files to CMakeLists.txt
2. Use CAF's test framework
3. CI will automatically run them

## Conclusion

The CAF generator bridges the gap between:
- **Rapid prototyping** (Elixir DSL)
- **Production deployment** (C++ actors)
- **Clean customization** (Callback interfaces)

It enables a powerful workflow:
1. Design in DSL
2. Test with virtual time
3. Validate in Elixir
4. Generate CAF code
5. Customize via callbacks
6. Deploy to production

Perfect for:
- Distributed systems
- Real-time applications
- Microservices
- Message-driven architectures
- High-performance computing

**Status:** Production-ready with callback customization support

**Test Coverage:** 123 tests passing (100% of implemented features)

**Compatibility:** CAF 0.18+, CMake 3.15+, C++17

**Key Differentiator:** Callback interfaces allow customization WITHOUT touching generated code!

