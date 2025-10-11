# GenServerVirtualTime

An extension to the GenServer behavior that allows testing time-based behavior of GenServers and simulating actor systems with a virtual time scheduler and simulator.

[![Tests](https://img.shields.io/badge/tests-63%20passing-brightgreen)]()
[![Coverage](https://img.shields.io/badge/coverage-70.5%25-yellow)]()

## Overview

### The Problem

```elixir
# Traditional approach: wait for real time to pass
test "heartbeat works over 10 seconds" do
  {:ok, server} = HeartbeatServer.start_link(interval: 1000)
  Process.sleep(10_000)
  assert get_beat_count(server) >= 10
end
# Takes 10 seconds to run
```

### The Solution

```elixir
# With virtual time: deterministic and fast
test "heartbeat works over 10 seconds" do
  {:ok, clock} = VirtualClock.start_link()
  VirtualTimeGenServer.set_virtual_clock(clock)
  
  {:ok, server} = HeartbeatServer.start_link(interval: 1000)
  VirtualClock.advance(clock, 10_000)
  
  assert get_beat_count(server) == 10
end
# Completes in milliseconds
```

## Quick Start

### 1. Define Your GenServer

```elixir
defmodule MyServer do
  use VirtualTimeGenServer
  
  def init(interval) do
    schedule_tick(interval)
    {:ok, %{interval: interval, count: 0}}
  end
  
  def handle_info(:tick, state) do
    schedule_tick(state.interval)
    {:noreply, %{state | count: state.count + 1}}
  end
  
  defp schedule_tick(interval) do
    VirtualTimeGenServer.send_after(self(), :tick, interval)
  end
end
```

### 2. Test With Virtual Time

```elixir
test "ticks 100 times in 10 seconds" do
  {:ok, clock} = VirtualClock.start_link()
  VirtualTimeGenServer.set_virtual_clock(clock)
  
  {:ok, server} = MyServer.start_link(100)
  VirtualClock.advance(clock, 10_000)
  
  assert get_count(server) == 100
end
```

## Actor System Simulation

Simulate distributed systems with message patterns, rates, and statistics:

```elixir
# Define a pub-sub system simulation
simulation = 
  ActorSimulation.new(trace: true)
  |> ActorSimulation.add_actor(:publisher,
      send_pattern: {:rate, 100, :event},  # 100 events/second
      targets: [:subscriber1, :subscriber2, :subscriber3])
  |> ActorSimulation.add_actor(:subscriber1)
  |> ActorSimulation.add_actor(:subscriber2)
  |> ActorSimulation.add_actor(:subscriber3)
  |> ActorSimulation.run(duration: 60_000)  # Simulate 1 minute

# Get statistics
stats = ActorSimulation.get_stats(simulation)
IO.inspect(stats.actors[:publisher].sent_count)  # 6000 messages

# Generate sequence diagram
plantuml = ActorSimulation.trace_to_plantuml(simulation)
File.write!("sequence.puml", plantuml)
```

## Generate OMNeT++ Simulations 🎯

**NEW!** Export your ActorSimulation DSL to production-grade [OMNeT++](https://github.com/omnetpp/omnetpp) C++ code:

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

**Generated files:**
- `PubSubNetwork.ned` - Network topology (NED language)
- `Publisher.h/cc` - C++ simple modules for each actor
- `Subscriber*.h/cc` - Receiver implementations
- `CMakeLists.txt` - CMake build configuration
- `conanfile.txt` - Package dependencies
- `omnetpp.ini` - Simulation parameters

**Why OMNeT++?**
- **Prototype Fast** - Develop and test in Elixir (REPL, instant feedback)
- **Scale Out** - Export to OMNeT++ for large-scale C++ simulations
- **Rich Ecosystem** - Access INET framework, network protocols, visualization tools
- **Industry Standard** - Battle-tested for communication networks, IoT, distributed systems

**Try the demos:**
```bash
mix run examples/omnetpp_demo.exs
cd examples/omnetpp_pubsub
# See generated C++ code!
```

Learn more in [OMNeT++ Code Generation](#omnet-code-generation) section.

## More Examples

### Request-Response Pattern with Pattern Matching

```elixir
# Define actors with pattern matching responses
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:client,
      send_pattern: {:periodic, 100, :get_data},
      targets: [:server])
  |> ActorSimulation.add_actor(:server,
      on_match: [
        {:get_data, fn _state -> {:reply, {:data, 42}, _state} end},
        {:save, fn state -> {:reply, :saved, %{state | saved: true}} end}
      ])
  |> ActorSimulation.run(duration: 1000)
```

### Sync and Async Communication

```elixir
ActorSimulation.add_actor(:requester,
  send_pattern: {:periodic, 100, {:call, :get_status}},  # Synchronous
  targets: [:responder])

ActorSimulation.add_actor(:notifier,
  send_pattern: {:periodic, 50, {:cast, :notify}},  # Asynchronous
  targets: [:listener])
```

### Pipeline Architecture

```elixir
forward = fn msg, state ->
  {:send, [{state.next, msg}], state}
end

ActorSimulation.new()
|> add_actor(:input, 
    send_pattern: {:rate, 50, :data},
    targets: [:stage1])
|> add_actor(:stage1,
    on_receive: forward,
    initial_state: %{next: :stage2})
|> add_actor(:stage2,
    on_receive: forward,
    initial_state: %{next: :output})
|> add_actor(:output)
|> run(duration: 10_000)
```

### Process-in-the-Loop (Test Real GenServers)

Inject actual GenServer implementations into simulations to test them alongside simulated actors:

```elixir
defmodule MyRealServer do
  use VirtualTimeGenServer
  
  def init(_), do: {:ok, %{requests: 0}}
  
  def handle_call(:get, _from, state) do
    {:reply, state.requests, %{state | requests: state.requests + 1}}
  end
end

# Mix real and simulated actors
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_process(:real_server,  # ← Real GenServer
      module: MyRealServer,
      args: nil)
  |> ActorSimulation.add_actor(:client,  # ← Simulated actor
      send_pattern: {:periodic, 100, {:call, :get}},
      targets: [:real_server])
  |> ActorSimulation.run(duration: 1000)
```

Similar to hardware-in-the-loop testing, but for processes.

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:gen_server_virtual_time, "~> 0.1.0"}
  ]
end
```

## Features

- **Fast Testing** - Simulate hours of behavior in seconds
- **Deterministic** - Precise, repeatable results without timing issues
- **Drop-in Replacement** - Compatible with existing GenServers
- **Statistics & Tracing** - Built-in metrics and sequence diagram generation
- **Actor Simulation DSL** - Define and test complex distributed systems
- **Process-in-the-Loop** - Mix real and simulated processes
- **Pattern Matching** - Declarative response definitions
- **Sync/Async Support** - Handle both call and cast operations

## API Quick Reference

### VirtualClock

```elixir
{:ok, clock} = VirtualClock.start_link()
VirtualClock.now(clock)                    # Get current time
VirtualClock.advance(clock, 5000)          # Advance by 5 seconds
VirtualClock.advance_to_next(clock)        # Jump to next event
VirtualClock.send_after(clock, pid, msg, delay)
```

### VirtualTimeGenServer

```elixir
use VirtualTimeGenServer  # In your module

VirtualTimeGenServer.set_virtual_clock(clock)  # Use virtual time
VirtualTimeGenServer.use_real_time()           # Use real time
VirtualTimeGenServer.send_after(pid, msg, delay)
```

### ActorSimulation

```elixir
ActorSimulation.new(trace: true)
|> ActorSimulation.add_actor(name, opts)
|> ActorSimulation.add_process(name, module: M, args: args)
|> ActorSimulation.run(duration: ms)
|> ActorSimulation.get_stats()
|> ActorSimulation.get_trace()
|> ActorSimulation.trace_to_plantuml()
|> ActorSimulation.trace_to_mermaid()
```

### Send Patterns

```elixir
# Periodic: every N milliseconds
send_pattern: {:periodic, 100, :tick}

# Rate: X messages per second
send_pattern: {:rate, 50, :event}

# Burst: N messages every interval
send_pattern: {:burst, 10, 500, :batch}
```

### Message Handling

```elixir
# Pattern matching (declarative)
on_match: [
  {:ping, fn state -> {:reply, :pong, state} end},
  {:get, fn state -> {:reply, state.value, state} end}
]

# Function handler (imperative)
on_receive: fn msg, state ->
  case msg do
    :increment -> {:ok, %{state | count: state.count + 1}}
    :get -> {:reply, state.count, state}
    {:set, val} -> {:send, [{:logger, :updated}], %{state | value: val}}
  end
end
```

### Message Types

```elixir
# Regular send (fire and forget)
{:target, :message}

# Synchronous call (wait for reply)
{:target, {:call, :get_value}}

# Asynchronous cast
{:target, {:cast, :notify}}
```

## Why Virtual Time?

Traditional time-dependent testing has three problems:

1. **Slow** - Tests take as long as the behavior they're testing
2. **Flaky** - Race conditions and timing issues
3. **Imprecise** - Can only assert `>=` not `==`

Virtual time solves all three:

| Problem | Real Time | Virtual Time |
|---------|-----------|--------------|
| Test 1 hour of behavior | 1 hour | ~10 seconds |
| Flaky timing issues | Common | None |
| Precise assertions | `>= 10` | `== 10` |
| Deterministic | No | Yes |

## Performance Benchmarks

Tested on M1 MacBook Pro:

| Simulated Time | Real Time | Virtual Time | Speedup |
|----------------|-----------|--------------|---------|
| 1 second | 1000ms | ~10ms | 100x |
| 10 seconds | 10s | ~100ms | 100x |
| 1 minute | 60s | ~6s | 10x |
| 10 minutes | 10 min | ~60s | 10x |
| 1 hour | 60 min | ~6 min | 10x |

Processing rate: ~6,000 virtual events per real second

## Message Tracing

Enable tracing to capture inter-actor communication:

```elixir
simulation = 
  ActorSimulation.new(trace: true)
  |> add_actors_and_patterns()
  |> run(duration: 5000)

# Get trace
trace = ActorSimulation.get_trace(simulation)
# => [
#   %{timestamp: 100, from: :client, to: :server, message: :ping, type: :send},
#   %{timestamp: 200, from: :server, to: :client, message: :pong, type: :send},
#   ...
# ]

# Generate PlantUML sequence diagram
plantuml = ActorSimulation.trace_to_plantuml(simulation)
File.write!("diagram.puml", plantuml)
```

The generated PlantUML can be rendered into sequence diagrams:

```
@startuml

client ->> server: :ping
server ->> client: :pong
client ->> server: :request
server ->> database: :query
database ->> server: {:ok, data}
server ->> client: {:response, data}

@enduml
```

## Viewing Generated Diagrams

During testing, HTML files with rendered diagrams are generated in `test/output/`:

```bash
# Run tests to generate diagrams
mix test test/diagram_generation_test.exs

# Open the index page
open test/output/index.html
```

The generated HTML files include:
- **Mermaid diagrams** - Self-contained with CDN-based MermaidJS
- **PlantUML diagrams** - Rendered via PlantUML server
- **Interactive viewing** - No build step required

## Performance

| Simulated Time | Real Time | Virtual Time | Speedup |
|------|-------------|
| `NetworkName.ned` | Network topology in NED language |
| `ActorName.h` | C++ header files for each actor module |
| `ActorName.cc` | C++ implementation with message handling |
| `CMakeLists.txt` | CMake build configuration |
| `conanfile.txt` | Conan package manager configuration |
| `omnetpp.ini` | Simulation parameters and settings |

### DSL to OMNeT++ Mapping

| ActorSimulation DSL | OMNeT++ Equivalent |
|---------------------|-------------------|
| `ActorSimulation.add_actor/2` | `cSimpleModule` class |
| `send_pattern: {:periodic, ms, msg}` | `scheduleAt(simTime() + interval)` |
| `send_pattern: {:rate, per_sec, msg}` | `scheduleAt(simTime() + 1/rate)` |
| `send_pattern: {:burst, n, ms, msg}` | Loop sending n messages per interval |
| `targets: [...]` | Output gates + NED connections |
| VirtualClock time | `simTime()` |
| Message passing | `send(msg, "out", gateIndex)` |

### Send Pattern Examples

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

### Building Generated Code

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

### Installation Requirements

To build and run generated code, you need:

1. **OMNeT++ 6.0+** - Install from [omnetpp.org](https://omnetpp.org/)
2. **CMake 3.15+** - For build configuration
3. **C++17 compiler** - GCC 7+, Clang 5+, or MSVC 2017+
4. **Conan (optional)** - For dependency management

See [OMNeT++ Installation Guide](https://doc.omnetpp.org/omnetpp/InstallGuide.pdf) for platform-specific instructions.

### Example: Pub-Sub System

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

### Advanced Options

```elixir
{:ok, files} = ActorSimulation.OMNeTPPGenerator.generate(simulation,
  network_name: "MyNetwork",      # Network name (required)
  sim_time_limit: 60.0,           # Simulation duration in seconds
  output_dir: "custom/path/"      # Custom output path (documentation only)
)
```

### Demo Scripts

Run the included demos to see complete examples:

```bash
# Generate multiple OMNeT++ projects
mix run examples/omnetpp_demo.exs

# Explore generated code
cd examples/omnetpp_pubsub
ls -la  # See all generated files
cat PubSubNetwork.ned  # View network topology
cat Publisher.cc  # View C++ implementation
```

### Why Use OMNeT++ Generation?

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

### Limitations

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

### Contributing to Generator

The generator is extensible and contributions are welcome:
- Add support for custom message types
- Implement state machine translation
- Add network delay/loss models
- Support INET framework integration

See `lib/actor_simulation/omnetpp_generator.ex` and `test/omnetpp_generator_test.exs`.

## Examples

Run the demo:

```bash
mix run examples/demo.exs
mix run examples/omnetpp_demo.exs  # OMNeT++ generation demo
```

Check the test directory for more examples:
- `test/virtual_clock_test.exs` - Virtual clock basics
- `test/virtual_time_gen_server_test.exs` - GenServer testing
- `test/actor_simulation_test.exs` - Actor system simulation

## Inspiration

Inspired by:
- [RxJS TestScheduler](https://rxjs.dev/api/testing/TestScheduler) - Virtual time for reactive programming
- [Don't Wait Forever for Tests](https://github.com/d-led/dont_wait_forever_for_the_tests) - Testing philosophy

## Contributing

Contributions welcome! Please open an issue or PR.

## License

MIT License - See LICENSE file for details
