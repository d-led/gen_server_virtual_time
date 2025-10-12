# GenServerVirtualTime

Test time-based GenServers instantly. Simulate actor systems with virtual time.
Model, simulate, analyze actor systems and generate boilerplate in various Actor
Model implementations: in Java, Pony, Go and C++.

[![Hex.pm](https://img.shields.io/hexpm/v/gen_server_virtual_time.svg)](https://hex.pm/packages/gen_server_virtual_time)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/gen_server_virtual_time)
[![CI](https://github.com/d-led/gen_server_virtual_time/workflows/CI/badge.svg)](https://github.com/d-led/gen_server_virtual_time/actions)
[![Coverage Status](https://coveralls.io/repos/github/d-led/gen_server_virtual_time/badge.svg?branch=main)](https://coveralls.io/github/d-led/gen_server_virtual_time?branch=main)

> **🎬
> [View Live Examples & Reports](https://d-led.github.io/gen_server_virtual_time/examples/)**
> • **📊
> [Interactive Flowchart Reports](https://d-led.github.io/gen_server_virtual_time/examples/reports/)**
> (NEW!)

## 🚀 Code Generators

Generate production-ready actor system implementations from high-level DSL:

| Generator   | Language | Framework                                               | Output                                       |
| ----------- | -------- | ------------------------------------------------------- | -------------------------------------------- |
| **CAF**     | C++      | [C++ Actor Framework](https://www.actor-framework.org/) | Typed actors, CMake build, Conan deps, tests |
| **Phony**   | Go       | [Phony](https://github.com/Arceliar/phony)              | Zero-alloc actors, Go modules, tests         |
| **Pony**    | Pony     | [Pony Language](https://www.ponylang.io/)               | Type-safe actors, Corral deps, PonyTest      |
| **VLINGO**  | Java     | [VLINGO XOOM](https://docs.vlingo.io/)                  | Protocol actors, Maven, JUnit 5              |
| **OMNeT++** | C++      | [OMNeT++](https://omnetpp.org/)                         | Discrete-event simulation, NED files, CMake  |

All generators include:

- ✅ Complete build configuration (CMake/Maven/Go modules/Corral)
- ✅ CI/CD pipeline definitions (GitHub Actions)
- ✅ Callback interfaces for custom behavior
- ✅ Comprehensive test suites
- ✅ Production-ready project structure

## Show Me The Code

### Test 100 seconds of behavior in milliseconds

```elixir
defmodule MyServer do
  use VirtualTimeGenServer  # <-- Drop-in replacement for GenServer

  def init(state) do
    VirtualTimeGenServer.send_after(self(), :work, 1000)
    {:ok, state}
  end

  def handle_info(:work, state) do
    VirtualTimeGenServer.send_after(self(), :work, 1000)
    {:noreply, %{state | count: state.count + 1}}
  end
end

test "100 seconds completes instantly" do
  {:ok, clock} = VirtualClock.start_link()
  VirtualTimeGenServer.set_virtual_clock(clock)

  {:ok, server} = MyServer.start_link(%{count: 0})
  VirtualClock.advance(clock, 100_000)  # 100s virtual, ~10ms real ⚡

  assert GenServer.call(server, :get_count) == 100
end
```

### Simulate message-passing systems

```elixir
import ActorSimulation

# Pipeline: producer → consumer
simulation = new(trace: true)
|> add_actor(:producer,
    send_pattern: {:rate, 100, :data},  # 100 msgs/sec
    targets: [:consumer])
|> add_actor(:consumer,
    on_receive: fn :data, s -> {:ok, %{s | count: s.count + 1}} end,
    initial_state: %{count: 0})
|> run(duration: 10_000)  # 10s virtual in milliseconds

stats = get_stats(simulation)
# producer sent ~1000, consumer received ~1000
```

### Export to production C++

**OMNeT++ Network Simulations:**

```elixir
simulation = ActorSimulation.new()
|> ActorSimulation.add_actor(:publisher,
    send_pattern: {:periodic, 100, :event},
    targets: [:sub1, :sub2, :sub3])
|> ActorSimulation.add_actor(:sub1)
|> ActorSimulation.add_actor(:sub2)
|> ActorSimulation.add_actor(:sub3)

# Generate complete OMNeT++ C++ project
{:ok, files} = ActorSimulation.OMNeTPPGenerator.generate(simulation,
  network_name: "PubSub",
  sim_time_limit: 10)
ActorSimulation.OMNeTPPGenerator.write_to_directory(files, "omnetpp_output/")
```

**C++ Actor Framework (CAF) with Callbacks:**

```elixir
# Generate CAF project with callback interfaces
{:ok, files} = ActorSimulation.CAFGenerator.generate(simulation,
  project_name: "PubSubActors",
  enable_callbacks: true)
ActorSimulation.CAFGenerator.write_to_directory(files, "caf_output/")
```

**VLINGO XOOM Actors (Java):**

```elixir
# Generate type-safe Java actor system
{:ok, files} = ActorSimulation.VlingoGenerator.generate(simulation,
  project_name: "pubsub-actors",
  group_id: "com.example",
  enable_callbacks: true)
ActorSimulation.VlingoGenerator.write_to_directory(files, "vlingo_output/")

# Then build and test with Maven:
# cd vlingo_output && mvn test
```

**Pony (Capabilities-Secure Actors):**

```elixir
# Generate Pony actor system
{:ok, files} = ActorSimulation.PonyGenerator.generate(simulation,
  project_name: "pubsub",
  enable_callbacks: true)
ActorSimulation.PonyGenerator.write_to_directory(files, "pony_output/")

# Then build and test:
# cd pony_output && make test
```

**Phony (Go Actors):**

```elixir
# Generate Go actor system with Phony
{:ok, files} = ActorSimulation.PhonyGenerator.generate(simulation,
  project_name: "pubsub",
  enable_callbacks: true)
ActorSimulation.PhonyGenerator.write_to_directory(files, "phony_output/")

# Then build and test:
# cd phony_output && go test ./...
```

Customize WITHOUT touching generated code:

```cpp
// CAF: publisher_callbacks_impl.cpp
void publisher_callbacks::on_event() {
  log_to_database();
  send_metrics();
}
```

```java
// VLINGO: PublisherCallbacksImpl.java
public void onEvent() {
  logger.info("Publishing event");
  metrics.increment("events.published");
}
```

### Visualize with sequence diagrams

```elixir
simulation = ActorSimulation.new(trace: true)
|> ActorSimulation.add_actor(:client,
    send_pattern: {:periodic, 100, :ping},
    targets: [:server])
|> ActorSimulation.add_actor(:server,
    on_match: [{:ping, fn s -> {:reply, :pong, s} end}])
|> ActorSimulation.run(duration: 1000)

# Generate Mermaid sequence diagram
mermaid = ActorSimulation.trace_to_mermaid(simulation, enhanced: true)
File.write!("diagram.html", ActorSimulation.wrap_mermaid_html(mermaid))
# Open in browser to see message flows!
```

### Generate flowchart reports with statistics

```elixir
simulation = ActorSimulation.new()
|> ActorSimulation.add_actor(:producer,
    send_pattern: {:rate, 100, :data},
    targets: [:stage1, :stage2])
|> ActorSimulation.add_actor(:stage1,
    on_receive: fn msg, s -> {:send, [{:sink, msg}], s} end)
|> ActorSimulation.add_actor(:stage2,
    on_receive: fn msg, s -> {:send, [{:sink, msg}], s} end)
|> ActorSimulation.add_actor(:sink)
|> ActorSimulation.run(duration: 5000)

# Generate flowchart with embedded statistics
html = ActorSimulation.generate_flowchart_report(simulation,
  title: "Pipeline System",
  layout: "TB",           # Top-to-bottom (or "LR", "RL", "BT")
  show_stats_on_nodes: true,
  style_by_activity: true  # Color-code by message activity
)

File.write!("report.html", html)
# Open in browser to see:
# • Actor topology as Mermaid flowchart
# • Message counts and rates on nodes
# • Activity-based color coding
# • Detailed statistics table
# • Virtual time speedup metrics
```

## Installation

```elixir
def deps do
  [
    {:gen_server_virtual_time, "~> 0.1.0"}
  ]
end
```

## Why Virtual Time?

| Problem              | Real Time   | Virtual Time |
| -------------------- | ----------- | ------------ |
| Test 1 hour behavior | 1 hour wait | ~10 seconds  |
| Flaky timing issues  | Common      | None         |
| Precise assertions   | `>= 10`     | `== 10`      |
| Deterministic        | No          | Yes          |
| Speedup              | 1x          | 10-100x      |

## Core Features

**VirtualTimeGenServer** - Test real GenServers with virtual time

- Drop-in replacement: `use VirtualTimeGenServer` instead of `use GenServer`
- All standard callbacks: `handle_call`, `handle_cast`, `handle_info`
- Fast: simulate hours in seconds

**Actor Simulation DSL** - Prototype distributed systems

- Pattern matching: declarative message handlers
- Send patterns: periodic, rate-based, burst
- Process-in-the-loop: mix real GenServers with simulated actors
- Statistics & tracing built-in

**Code Generation** - Export to production

- **OMNeT++**: Industry-standard network simulation in C++
- **CAF**: Production actor systems with callback interfaces
- **Pony**: Capabilities-secure, data-race free actors
- **Phony**: Pony-inspired Go actor library
- **VLINGO XOOM**: Type-safe Java actors with scheduling
- **Tests included**: Catch2, PonyTest, Go tests, JUnit 5 with CI pipelines
- **Fast prototyping**: 10-100x faster in Elixir, then scale in production

## Quick API Reference

```elixir
# Virtual Clock
{:ok, clock} = VirtualClock.start_link()
VirtualClock.advance(clock, 5000)          # Jump 5 seconds
VirtualClock.advance_to_next(clock)        # Jump to next event
VirtualClock.now(clock)                    # Current virtual time

# Virtual Time GenServer
use VirtualTimeGenServer
VirtualTimeGenServer.set_virtual_clock(clock)
VirtualTimeGenServer.send_after(pid, msg, delay)

# Actor Simulation (import for clean DSL)
import ActorSimulation

new(trace: true)
|> add_actor(name, opts)
|> add_process(name, module: M, args: args)  # Real GenServer!
|> run(duration: ms)
|> get_stats()
|> trace_to_mermaid()
```

### Send Patterns

```elixir
send_pattern: {:periodic, 100, :tick}      # Every 100ms
send_pattern: {:rate, 50, :event}          # 50 messages/second
send_pattern: {:burst, 10, 500, :batch}    # 10 msgs every 500ms
```

### Message Handlers

```elixir
# Pattern matching (declarative)
on_match: [
  {:ping, fn s -> {:reply, :pong, s} end},
  {:get, fn s -> {:reply, s.value, s} end}
]

# Function handler (imperative)
on_receive: fn msg, state ->
  case msg do
    :increment -> {:ok, %{state | count: state.count + 1}}
    {:set, val} -> {:send, [{:logger, :updated}], %{state | value: val}}
  end
end
```

## More Examples

### Request-Response Pattern

```elixir
ActorSimulation.new()
|> ActorSimulation.add_actor(:client,
    send_pattern: {:periodic, 100, :get_data},
    targets: [:server])
|> ActorSimulation.add_actor(:server,
    on_match: [
      {:get_data, fn s -> {:reply, {:data, 42}, s} end},
      {:save, fn s -> {:reply, :saved, %{s | saved: true}} end}
    ])
|> ActorSimulation.run(duration: 1000)
```

### Pipeline Architecture

```elixir
forward = fn msg, s -> {:send, [{s.next, msg}], s} end

ActorSimulation.new()
|> ActorSimulation.add_actor(:input,
    send_pattern: {:rate, 50, :data},
    targets: [:stage1])
|> ActorSimulation.add_actor(:stage1,
    on_receive: forward,
    initial_state: %{next: :stage2})
|> ActorSimulation.add_actor(:stage2,
    on_receive: forward,
    initial_state: %{next: :output})
|> ActorSimulation.add_actor(:output)
|> ActorSimulation.run(duration: 10_000)
```

### Process-in-the-Loop (Mix Real & Simulated)

```elixir
defmodule MyRealServer do
  use VirtualTimeGenServer

  def handle_call(:get, _from, state) do
    {:reply, state.requests, %{state | requests: state.requests + 1}}
  end
end

# Test real GenServer alongside simulated actors
ActorSimulation.new()
|> ActorSimulation.add_process(:real_server,           # ← Real GenServer
    module: MyRealServer, args: nil)
|> ActorSimulation.add_actor(:client,                  # ← Simulated actor
    send_pattern: {:periodic, 100, {:call, :get}},
    targets: [:real_server])
|> ActorSimulation.run(duration: 1000)
```

Similar to hardware-in-the-loop testing, but for processes.

## Code Generation Demos

```bash
# OMNeT++ network simulations
mix run examples/omnetpp_demo.exs
cd examples/omnetpp_pubsub
# View the generated network topology in PubSubNetwork.ned

# CAF actor systems (C++)
mix run examples/caf_demo.exs
cd examples/caf_pubsub
# Edit publisher_callbacks_impl.cpp to add your custom code

# VLINGO XOOM Actors (Java)
mix run scripts/generate_vlingo_sample.exs
cd generated/vlingo_loadbalanced
mvn test  # Run JUnit 5 tests

# Pony (capabilities-secure)
mix run examples/pony_demo.exs
cd generated/pony_loadbalanced

# Phony (Go)
mix run examples/phony_demo.exs
cd generated/phony_burst
```

## Documentation

- [OMNeT++ Code Generation](docs/omnetpp_generation.md) - Export to OMNeT++ C++
- [CAF Code Generation](docs/caf_generation.md) - Export to CAF with callbacks
- [Pony Generator](docs/pony_generator.md) - Capabilities-secure actors
- [Phony Generator](docs/phony_generator.md) - Go actor systems
- [VLINGO XOOM Generator](docs/vlingo_generator.md) - Type-safe Java actors
  (NEW!)
- [API Documentation](https://hexdocs.pm/gen_server_virtual_time) - Complete API
  reference
- [Contributing Guide](CONTRIBUTING.md) - How to contribute
- [Development Docs](docs/development/) - Development notes

## Performance

Processing rate: ~6,000 virtual events per real second (M1 MacBook Pro)

| Simulated Time | Real Time | Speedup |
| -------------- | --------- | ------- |
| 1 second       | ~10ms     | 100x    |
| 10 seconds     | ~100ms    | 100x    |
| 1 minute       | ~6s       | 10x     |
| 10 minutes     | ~60s      | 10x     |
| 1 hour         | ~6 min    | 10x     |

## Inspiration

- [RxJS TestScheduler](https://rxjs.dev/api/testing/TestScheduler) - Virtual
  time for reactive programming
- [Don't Wait Forever for Tests](https://github.com/d-led/dont_wait_forever_for_the_tests) -
  Testing philosophy

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License - See [LICENSE](LICENSE) file for details.
