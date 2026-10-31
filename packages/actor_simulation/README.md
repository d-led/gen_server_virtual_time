# ActorSimulation

Model a system of actors talking to each other, run it in virtual time, and look
at what happened: who sent what, how much, and when. A simulated hour takes
milliseconds, so a design question is answered by a test rather than by a
whiteboard.

This package is the simulation DSL, its statistics and its diagrams. The clock
it runs on is
[`gen_server_virtual_time`](https://hexdocs.pm/gen_server_virtual_time); turning
a model into a runnable C++, Go, Pony, Rust or Java project is
[`actor_simulation_codegen`](https://hexdocs.pm/actor_simulation_codegen).

[![Hex.pm](https://img.shields.io/hexpm/v/actor_simulation.svg)](https://hex.pm/packages/actor_simulation)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/actor_simulation)

## The family

| Package                                                                                 | What it is for                                                | Add it when                                        |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------------- | -------------------------------------------------- |
| [`gen_server_virtual_time`](https://hexdocs.pm/gen_server_virtual_time)                 | virtual clock, `GenServer`/`gen_statem` wrappers              | you test code with timers (this package brings it) |
| [`gen_server_virtual_time_migrate`](https://hexdocs.pm/gen_server_virtual_time_migrate) | `mix virtual_time.migrate` rewrites `GenServer` code          | you already have servers and want to keep them     |
| **`actor_simulation`** (this one)                                                       | actor-system DSL, statistics, sequence diagrams               | you model parts of a system talking to each other  |
| [`actor_simulation_codegen`](https://hexdocs.pm/actor_simulation_codegen)               | generate runnable C++, Go, Pony, Rust, Java, OMNeT++ projects | you want the same model in another runtime         |

## Install

```elixir
def deps do
  [{:actor_simulation, "~> 1.1.1"}]
end
```

## Simulate message-passing systems

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

### Send patterns

```elixir
send_pattern: {:periodic, 100, :tick}      # Every 100ms
send_pattern: {:rate, 50, :event}          # 50 messages/second
send_pattern: {:burst, 10, 500, :batch}    # 10 msgs every 500ms
send_pattern: {:self_message, 250, :wake}  # One message, later
```

### Message handlers

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

## More examples

### Request-response pattern

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

### Pipeline architecture

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

### Process-in-the-loop (mix real and simulated)

A real `VirtualTimeGenServer` is counted by `ActorSimulation.Observer`, so its
statistics look like a simulated actor's.

```elixir
defmodule MyRealServer do
  use VirtualTimeGenServer

  def handle_call(:get, _from, state) do
    {:reply, state.requests, %{state | requests: state.requests + 1}}
  end
end

ActorSimulation.new()
|> ActorSimulation.add_process(:real_server,           # ← Real GenServer
    module: MyRealServer, args: nil)
|> ActorSimulation.add_actor(:client,                  # ← Simulated actor
    send_pattern: {:periodic, 100, {:call, :get}},
    targets: [:real_server])
|> ActorSimulation.run(duration: 1000)
```

## Visualize with sequence diagrams

```elixir
simulation = ActorSimulation.new(trace: true)
|> ActorSimulation.add_actor(:client,
    send_pattern: {:periodic, 100, :ping},
    targets: [:server])
|> ActorSimulation.add_actor(:server,
    on_match: [{:ping, fn s -> {:reply, :pong, s} end}])
|> ActorSimulation.run(duration: 1000)

# The message flow as a Mermaid sequence diagram
mermaid = ActorSimulation.trace_to_mermaid(simulation, enhanced: true)
File.write!("diagram.mmd", mermaid)

# Or a standalone HTML report: topology, stats and the model source
{:ok, _path} = ActorSimulation.write_flowchart_report(simulation, "report.html",
  title: "Client / server")
```

## Flowchart reports with statistics

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

html = ActorSimulation.generate_flowchart_report(simulation,
  title: "Pipeline System",
  layout: "TB",              # Top-to-bottom (or "LR", "RL", "BT")
  show_stats_on_nodes: true,
  style_by_activity: true    # Color-code by message activity
)

File.write!("report.html", html)
```

The report shows the actor topology, message counts and rates on the nodes,
activity-based colouring, a statistics table and the virtual-time speedup.
[Flowchart reports](docs/flowchart_reports.md) describes the options.

## Documentation

- [Flowchart reports](docs/flowchart_reports.md) — topology diagrams with stats
- [API reference](https://hexdocs.pm/actor_simulation)
- [Changelog](https://github.com/d-led/gen_server_virtual_time/blob/main/CHANGELOG.md)

## License

MIT License - See the [LICENSE](LICENSE) file for details.
