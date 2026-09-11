# GenServerVirtualTime

Test time-based GenServers instantly — no waiting, no flaky timing. Simulate
actor systems with virtual time, then generate the same system in C++, Go, Pony,
Rust, Java or OMNeT++.

[![Hex.pm](https://img.shields.io/hexpm/v/gen_server_virtual_time.svg)](https://hex.pm/packages/gen_server_virtual_time)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/gen_server_virtual_time)
[![CI](https://github.com/d-led/gen_server_virtual_time/workflows/CI/badge.svg)](https://github.com/d-led/gen_server_virtual_time/actions)
[![Coverage Status](https://coveralls.io/repos/github/d-led/gen_server_virtual_time/badge.svg?branch=main&kill_cache=1)](https://coveralls.io/github/d-led/gen_server_virtual_time?branch=main)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fd-led%2Fgen_server_virtual_time.svg?type=shield&issueType=license)](https://app.fossa.com/projects/git%2Bgithub.com%2Fd-led%2Fgen_server_virtual_time?ref=badge_shield&issueType=license)

> **🎬 [Live examples & reports](https://d-led.github.io/gen_server_virtual_time/)**
> • **📊 [Flowchart reports](https://d-led.github.io/gen_server_virtual_time/reports/)**

## ⚡ Start here

1. Add the dependency:

   ```elixir
   def deps do
     [{:gen_server_virtual_time, "~> 0.5.0"}]
   end
   ```

2. Swap `use GenServer` for `use VirtualTimeGenServer` — nothing else changes.

3. Point a clock at it, then jump time:

   ```elixir
   {:ok, clock} = VirtualClock.start_link()
   {:ok, server} = VirtualTimeGenServer.start_link(MyServer, :ok, virtual_clock: clock)

   VirtualClock.advance(clock, 10_000)   # 10 virtual seconds, ~10ms real
   ```

4. Run the century demo to see it end to end (~2 seconds) —
   [source](scripts/century_backup_demo.exs),
   [sample run](https://github.com/d-led/gen_server_virtual_time/actions/workflows/century-backup-demo.yml):

   ```bash
   elixir scripts/century_backup_demo.exs
   ```

## 🧭 Which page do I need?

| I want to…                                      | Go to                                                                        |
| ----------------------------------------------- | ---------------------------------------------------------------------------- |
| Test a GenServer with timers                    | [100 seconds in milliseconds](#test-100-seconds-of-behavior-in-milliseconds) |
| Test a state machine with timeouts               | [State machine example](#test-state-machines-with-virtual-time)              |
| Simulate actors talking to each other           | [Actor simulation](#simulate-message-passing-systems)                        |
| Draw a sequence diagram of the message flow     | [Visualize with sequence diagrams](#visualize-with-sequence-diagrams)        |
| Generate C++ / Go / Pony / Rust / Java / OMNeT++ | [Code generators](#-code-generators)                                          |
| Understand how the clock works                  | [VirtualClock design](docs/virtual_clock_design.md)                          |

## 🚀 Code Generators

Generate a working actor system, with build files, CI and tests, from the DSL:

| Generator   | Language | Framework                                               | Output                                       |
| ----------- | -------- | ------------------------------------------------------- | -------------------------------------------- |
| **CAF**     | C++      | [C++ Actor Framework](https://www.actor-framework.org/) | Typed actors, CMake build, Conan deps, tests |
| **Phony**   | Go       | [Phony](https://github.com/Arceliar/phony)              | Zero-alloc actors, Go modules, tests         |
| **Pony**    | Pony     | [Pony Language](https://www.ponylang.io/)               | Type-safe actors, Corral deps, PonyTest      |
| **Ractor**  | Rust     | [Ractor](https://github.com/slawlor/ractor)             | Gen_server-inspired, Cargo, async/await      |
| **VLINGO**  | Java     | [VLINGO XOOM](https://docs.vlingo.io/)                  | Protocol actors, Maven, JUnit 5              |
| **OMNeT++** | C++      | [OMNeT++](https://omnetpp.org/)                         | Discrete-event simulation, NED files, CMake  |

Every generator emits the same five things: build config, a CI workflow,
callback interfaces for your code, a test suite, and a runnable project layout.

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

### Test state machines with virtual time

```elixir
defmodule SwitchStateMachine do
  use VirtualTimeGenStateMachine, callback_mode: :handle_event_function

  def start_link(opts) do
    GenStateMachine.start_link(__MODULE__, :off, opts)
  end

  def init(_) do
    {:ok, :off, %{flip_count: 0}}
  end

  def handle_event(:cast, :flip, :off, data) do
    # Schedule timeout for 100ms
    VirtualTimeGenStateMachine.send_after(self(), :timeout, 100)
    {:next_state, :on, %{data | flip_count: data.flip_count + 1}}
  end

  def handle_event(:cast, :flip, :on, data) do
    {:next_state, :off, data}
  end

  def handle_event(:info, :timeout, state, data) do
    {:keep_state, %{data | timeout_fired: true}}
  end
end

test "state machine transitions and timers" do
  {:ok, clock} = VirtualClock.start_link()
  VirtualTimeGenStateMachine.set_virtual_clock(clock)

  {:ok, sm} = SwitchStateMachine.start_link([])

  # Trigger transition and schedule timeout
  GenStateMachine.cast(sm, :flip)

  # Advance virtual time - timeout fires instantly
  VirtualClock.advance(clock, 100)  # ~10ms real time ⚡

  # Check timeout fired
  assert get_state(sm).timeout_fired == true
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

**Ractor (Rust Actors):**

```elixir
# Generate Rust actor system with Ractor
{:ok, files} = ActorSimulation.RactorGenerator.generate(simulation,
  project_name: "pubsub",
  enable_callbacks: true)
ActorSimulation.RactorGenerator.write_to_directory(files, "ractor_output/")

# Then build and test:
# cd ractor_output && cargo test
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

```rust
// Ractor: publisher.rs
impl PublisherCallbacks for MyPublisherCallbacks {
    fn on_event(&self) {
        println!("Publishing event with custom handler");
        // Add your custom logic here
    }
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
    targets: [:sink],  # Define targets for flowchart edges
    on_receive: fn msg, s -> {:send, [{:sink, msg}], s} end)
|> ActorSimulation.add_actor(:stage2,
    targets: [:sink],
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

# 💡 Tip: For dynamic sends without targets, enable tracing:
# simulation = ActorSimulation.new(trace: true)
```

## Why virtual time?

| Problem              | Real time   | Virtual time |
| -------------------- | ----------- | ------------ |
| Test 1 hour behavior | 1 hour wait | ~10 seconds  |
| Flaky timing issues  | Common      | None         |
| Precise assertions   | `>= 10`     | `== 10`      |
| Deterministic        | No          | Yes          |
| Speedup              | 1x          | 10-100x      |

## What you get

| Module                        | Use it to                                            |
| ----------------------------- | ---------------------------------------------------- |
| `VirtualTimeGenServer`        | Test real GenServers with timers                     |
| `VirtualTimeGenStateMachine`  | Test state machines with timeouts                    |
| `ActorSimulation`             | Prototype distributed systems, with stats and traces |
| `ActorSimulation.*Generator`  | Export the same system to another language           |

Both wrappers are drop-in replacements: `use VirtualTimeGenServer` instead of
`use GenServer`, `use VirtualTimeGenStateMachine` instead of
`use GenStateMachine`. Every standard callback keeps working — `handle_call`,
`handle_cast`, `handle_info`, `handle_continue`, `handle_event`, timeouts.

The simulation DSL gives you send patterns (`:periodic`, `:rate`, `:burst`),
declarative `on_match` handlers, process-in-the-loop (mix real GenServers with
simulated actors), and built-in statistics and tracing.

Generators ship the tests too: Catch2, PonyTest, Go tests, Cargo tests, and
JUnit 5, each with a CI workflow. Prototype in Elixir at 10-100x speed, then
scale in production.

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

# Virtual Time GenStateMachine
use VirtualTimeGenStateMachine, callback_mode: :handle_event_function
VirtualTimeGenStateMachine.set_virtual_clock(clock)
VirtualTimeGenStateMachine.send_after(pid, msg, delay)

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

## Generate a project

1. Generate the example projects for the language you want:

   ```bash
   mix run scripts/generate_omnetpp_examples.exs   # C++ / OMNeT++
   mix run scripts/generate_caf_examples.exs       # C++ / CAF
   mix run scripts/generate_pony_examples.exs      # Pony
   mix run scripts/generate_phony_examples.exs     # Go / Phony
   mix run examples/ractor_demo.exs                # Rust / Ractor
   mix run scripts/generate_vlingo_sample.exs      # Java / VLINGO XOOM
   ```

2. Build the output with its own toolchain. Each generated project ships a
   `README.md` with the exact commands:

   | Generated project               | Toolchain     |
   | ------------------------------- | ------------- |
   | `examples/omnetpp_pubsub`       | CMake + Conan |
   | `examples/caf_pubsub`           | CMake + Conan |
   | `examples/pony_pubsub`          | Pony + Corral |
   | `examples/phony_pubsub`         | Go modules    |
   | `examples/ractor_pipeline`      | Cargo         |
   | `generated/vlingo_loadbalanced` | Maven         |

## Documentation

- [Generators overview](docs/generators.md) — links every generator guide
  ([OMNeT++](docs/omnetpp_generator.md),
  [CAF](docs/caf_generator.md),
  [Pony](docs/pony_generator.md),
  [Phony](docs/phony_generator.md),
  [Ractor](docs/ractor_generator.md),
  [VLINGO XOOM](docs/vlingo_generator.md))
- [VirtualClock design](docs/virtual_clock_design.md) — how the clock schedules
  and orders events
- [Local clock injection](docs/local_clock_injection_feature.md) — isolated,
  race-free tests
- [Flowchart reports](docs/flowchart_reports.md) — topology diagrams with stats
- [API reference](https://hexdocs.pm/gen_server_virtual_time) ·
  [Contributing guide](CONTRIBUTING.md)

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

Contributions welcome! Please see the [Contributing Guide](CONTRIBUTING.md).

## License

MIT License - See the [LICENSE](LICENSE) file for details.

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fd-led%2Fgen_server_virtual_time.svg?type=large&issueType=license)](https://app.fossa.com/projects/git%2Bgithub.com%2Fd-led%2Fgen_server_virtual_time?ref=badge_large&issueType=license)
