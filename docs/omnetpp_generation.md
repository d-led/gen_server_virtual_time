# OMNeT++ Code Generation

Export ActorSimulation DSL to production-grade [OMNeT++](https://github.com/omnetpp/omnetpp) C++ code.

## Quick Example

```elixir
# Define your simulation in Elixir
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:publisher,
      send_pattern: {:periodic, 100, :event},
      targets: [:subscriber1, :subscriber2, :subscriber3])
  |> ActorSimulation.add_actor(:subscriber1)
  |> ActorSimulation.add_actor(:subscriber2)
  |> ActorSimulation.add_actor(:subscriber3)

# Generate complete OMNeT++ project
{:ok, files} = ActorSimulation.OMNeTPPGenerator.generate(simulation,
  network_name: "PubSubNetwork",
  sim_time_limit: 10)

ActorSimulation.OMNeTPPGenerator.write_to_directory(files, "omnetpp_output/")
```

## Generated Files

| File | Description |
|------|-------------|
| `NetworkName.ned` | Network topology in NED language |
| `ActorName.h` | C++ header files for each actor module |
| `ActorName.cc` | C++ implementation with message handling |
| `CMakeLists.txt` | CMake build configuration |
| `conanfile.txt` | Conan package manager configuration |
| `omnetpp.ini` | Simulation parameters and settings |

## DSL to OMNeT++ Mapping

| ActorSimulation DSL | OMNeT++ Equivalent |
|---------------------|-------------------|
| `ActorSimulation.add_actor/2` | `cSimpleModule` class |
| `send_pattern: {:periodic, ms, msg}` | `scheduleAt(simTime() + interval)` |
| `send_pattern: {:rate, per_sec, msg}` | `scheduleAt(simTime() + 1/rate)` |
| `send_pattern: {:burst, n, ms, msg}` | Loop sending n messages per interval |
| `targets: [...]` | Output gates + NED connections |
| VirtualClock time | `simTime()` |
| Message passing | `send(msg, "out", gateIndex)` |

## Send Pattern Examples

**Periodic Messages:**
```elixir
send_pattern: {:periodic, 100, :tick}
# Generates: scheduleAt(simTime() + 0.1, selfMsg)
```

**Rate-Based:**
```elixir
send_pattern: {:rate, 50, :data}
# Generates: scheduleAt(simTime() + 0.02, selfMsg)  # 50/sec = 0.02s interval
```

**Burst Pattern:**
```elixir
send_pattern: {:burst, 10, 1000, :batch}
# Generates: for loop sending 10 messages every 1 second
```

## Building Generated Code

After generating the files, build and run with OMNeT++:

```bash
# Navigate to output directory
cd omnetpp_output/

# Create build directory
mkdir build && cd build

# Configure with CMake
cmake ..

# Build
make

# Run simulation (command-line interface)
./NetworkName -u Cmdenv

# Or run with GUI
./NetworkName
```

## Installation Requirements

To build and run generated code, you need:

1. **OMNeT++ 6.0+** - Install from [omnetpp.org](https://omnetpp.org/)
2. **CMake 3.15+** - For build configuration
3. **C++17 compiler** - GCC 7+, Clang 5+, or MSVC 2017+
4. **Conan (optional)** - For dependency management

See [OMNeT++ Installation Guide](https://doc.omnetpp.org/omnetpp/InstallGuide.pdf) for platform-specific instructions.

## Example: Pub-Sub System

```elixir
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:publisher,
      send_pattern: {:periodic, 100, :event},
      targets: [:sub1, :sub2, :sub3])
  |> ActorSimulation.add_actor(:sub1)
  |> ActorSimulation.add_actor(:sub2)
  |> ActorSimulation.add_actor(:sub3)

{:ok, files} = ActorSimulation.OMNeTPPGenerator.generate(simulation,
  network_name: "PubSubNetwork",
  sim_time_limit: 10)

ActorSimulation.OMNeTPPGenerator.write_to_directory(files, "omnetpp_pubsub/")
```

**Generated NED topology:**
```ned
simple Publisher {
    gates:
        output out[3];
}

simple Sub1 {
    gates:
        input in;
}

network PubSubNetwork {
    submodules:
        publisher: Publisher;
        sub1: Sub1;
        sub2: Sub2;
        sub3: Sub3;
    connections:
        publisher.out[0] --> sub1.in;
        publisher.out[1] --> sub2.in;
        publisher.out[2] --> sub3.in;
}
```

**Generated C++ (Publisher.cc excerpt):**
```cpp
void Publisher::initialize() {
    sendCount = 0;
    selfMsg = new cMessage("selfMsg");
    scheduleAt(simTime() + 0.1, selfMsg);  // 100ms interval
}

void Publisher::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // Send to all subscribers
        for (int i = 0; i < 3; i++) {
            cMessage *outMsg = new cMessage("msg");
            send(outMsg, "out", i);
            sendCount++;
        }
        scheduleAt(simTime() + 0.1, msg);  // Reschedule
    }
}
```

## Advanced Options

```elixir
{:ok, files} = ActorSimulation.OMNeTPPGenerator.generate(simulation,
  network_name: "MyNetwork",      # Network name (required)
  sim_time_limit: 60.0,           # Simulation duration in seconds
  output_dir: "custom/path/"      # Custom output path (documentation only)
)
```

## Demo Scripts

Run the included demos to see complete examples:

```bash
# Generate multiple OMNeT++ projects
mix run examples/omnetpp_demo.exs

# Explore generated code
cd examples/omnetpp_pubsub
ls -la  # See all generated files
# View the network topology in PubSubNetwork.ned
# View the C++ implementation in Publisher.cc
```

## Why Use OMNeT++ Generation?

**Development Workflow:**
1. 🚀 **Prototype** - Rapid iteration in Elixir with instant feedback
2. 🧪 **Test** - Validate with virtual time and fast simulations  
3. 📊 **Visualize** - Generate PlantUML sequence diagrams
4. ⚡ **Scale** - Export to OMNeT++ for large-scale C++ simulations
5. 🎯 **Deploy** - Leverage OMNeT++ ecosystem and performance

**Benefits:**
- **10-100x faster prototyping** in Elixir vs writing C++
- **Type safety** - Catch errors at compile time in generated C++
- **Maintainability** - Single source of truth (your DSL)
- **Cross-validation** - Compare Elixir vs C++ simulation results
- **Industry tools** - Access OMNeT++ GUI, analysis, and visualization

## Limitations

The generator currently supports:
- ✅ Simple module actors with send patterns
- ✅ Point-to-point message passing
- ✅ Periodic, rate, and burst patterns
- ✅ Basic statistics collection

Not yet supported:
- ❌ Complex state machines (on_receive/on_match functions)
- ❌ Dynamic topology changes
- ❌ Custom message types beyond cMessage
- ❌ Network delays and channel models
- ❌ Parameter sweeps and configurations

For these advanced features, use OMNeT++ directly or extend the generator.

## Contributing to Generator

The generator is extensible and contributions are welcome:
- Add support for custom message types
- Implement state machine translation
- Add network delay/loss models
- Support INET framework integration

See `lib/actor_simulation/omnetpp_generator.ex` and `test/omnetpp_generator_test.exs`.

