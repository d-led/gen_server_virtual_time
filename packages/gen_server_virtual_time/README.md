# GenServerVirtualTime

Test time-based GenServers instantly — no waiting, no flaky timing.

This is the [RxJS TestScheduler](https://rxjs.dev/api/testing/TestScheduler)
idea applied to the BEAM: the clock is yours to advance, so a test describes the
timeline it wants instead of sleeping through it. It does the same for
`GenServer` and `:gen_statem`, and nothing else — modelling whole actor systems
and generating code in other languages are separate packages.

[![Hex.pm](https://img.shields.io/hexpm/v/gen_server_virtual_time.svg)](https://hex.pm/packages/gen_server_virtual_time)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/gen_server_virtual_time)
[![CI](https://github.com/d-led/gen_server_virtual_time/workflows/CI/badge.svg)](https://github.com/d-led/gen_server_virtual_time/actions)
[![Coverage Status](https://coveralls.io/repos/github/d-led/gen_server_virtual_time/badge.svg?branch=main&kill_cache=1)](https://coveralls.io/github/d-led/gen_server_virtual_time?branch=main)

## The family

The library is published as packages that share one version. A module keeps its
name wherever it lives, so choosing what you need is a dependency, not a
rewrite.

| Package                                                                                                                                  | What it is for                                                                                              | Add it when                                       |
| ---------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| **`gen_server_virtual_time`** (this one)                                                                                                 | virtual clock, `GenServer`/`gen_statem` wrappers, time backends                                             | you test code with timers                         |
| [`gen_server_virtual_time_migrate`](https://github.com/d-led/gen_server_virtual_time/tree/main/packages/gen_server_virtual_time_migrate) | `mix virtual_time.migrate` rewrites `GenServer` code for the virtual clock (repository tool, not a package) | you already have servers and want to keep them    |
| [`actor_simulation`](https://hexdocs.pm/actor_simulation)                                                                                | actor-system DSL, statistics, sequence diagrams                                                             | you model parts of a system talking to each other |
| [`actor_simulation_codegen`](https://hexdocs.pm/actor_simulation_codegen)                                                                | generate runnable C++, Go, Pony, Rust, Java, OMNeT++ projects from a simulation                             | you want the same model in another runtime        |

## ⚡ Start here

1. Add the dependency:

   ```elixir
   def deps do
     [{:gen_server_virtual_time, "~> 1.1.1"}]
   end
   ```

2. Swap `use GenServer` for `use VirtualTimeGenServer` — nothing else changes.

3. Point a clock at it, then jump time:

   ```elixir
   {:ok, clock} = VirtualClock.start_link()
   {:ok, server} = VirtualTimeGenServer.start_link(MyServer, :ok, virtual_clock: clock)

   VirtualClock.advance(clock, 10_000)   # 10 virtual seconds, ~10ms real
   ```

4. Run the century demo — 100 years of daily backups in seconds (a minute or two
   on a busy machine) —
   [source](https://github.com/d-led/gen_server_virtual_time/blob/main/scripts/century_backup_demo.exs),
   [sample run](https://github.com/d-led/gen_server_virtual_time/actions/workflows/century-backup-demo.yml):

   ```bash
   elixir scripts/century_backup_demo.exs
   ```

## Which page do I need?

| I want to…                             | Go to                                                                        |
| -------------------------------------- | ---------------------------------------------------------------------------- |
| Test a GenServer with timers           | [100 seconds in milliseconds](#test-100-seconds-of-behavior-in-milliseconds) |
| Test a state machine with timeouts     | [State machine example](#test-state-machines-with-virtual-time)              |
| Measure a server's traffic             | [Observing a server](#observing-a-server)                                    |
| Upgrade from 0.7                       | [Upgrading and the doctor](#upgrading-and-the-doctor)                        |
| Understand how the clock works         | [VirtualClock design](docs/virtual_clock_design.md)                          |
| Keep tests isolated from each other    | [Local clock injection](docs/local_clock_injection_feature.md)               |
| Simulate actors talking to each other  | [`actor_simulation`](https://hexdocs.pm/actor_simulation)                    |
| Generate C++ / Go / Pony / Rust / Java | [`actor_simulation_codegen`](https://hexdocs.pm/actor_simulation_codegen)    |

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
    VirtualTimeGenStateMachine.start_link(__MODULE__, :off, opts)
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

  def timeout_fired?(server) do
    VirtualTimeGenStateMachine.call(server, :timeout_fired?)
  end
end

test "state machine transitions and timers" do
  {:ok, clock} = VirtualClock.start_link()

  {:ok, sm} = SwitchStateMachine.start_link(virtual_clock: clock)

  # Trigger transition and schedule timeout
  VirtualTimeGenStateMachine.cast(sm, :flip)

  # Advance virtual time - timeout fires instantly
  VirtualClock.advance(clock, 100)

  # Check timeout fired
  assert SwitchStateMachine.timeout_fired?(sm)
end
```

## What you get

| Module                                 | Use it to                                     |
| -------------------------------------- | --------------------------------------------- |
| `VirtualTimeGenServer`                 | Test real GenServers with timers              |
| `VirtualTimeGenStateMachine`           | Test state machines with timeouts             |
| `VirtualTimeGenServer.Instrumentation` | Measure a server's traffic — counters, traces |
| `VirtualClock`                         | Drive time yourself, for anything else        |

Both wrappers are drop-in replacements: `use VirtualTimeGenServer` instead of
`use GenServer`, `use VirtualTimeGenStateMachine` instead of
`use GenStateMachine`. Every standard callback keeps working — `handle_call`,
`handle_cast`, `handle_info`, `handle_continue`, `handle_event`, timeouts.

## Quick API Reference

```elixir
# Virtual Clock
{:ok, clock} = VirtualClock.start_link()
VirtualClock.advance(clock, 5000)          # Jump 5 seconds
VirtualClock.advance_to_next(clock)        # Jump to next event
VirtualClock.now(clock)                    # Current virtual time
VirtualClock.scheduled_count(clock)        # How much is pending
VirtualClock.wait_for_quiescence(clock)    # Wait until nothing is pending

# Virtual Time GenServer
use VirtualTimeGenServer
VirtualTimeGenServer.set_virtual_clock(clock)
VirtualTimeGenServer.send_after(pid, msg, delay)
VirtualTimeGenServer.send_immediately(pid, msg)
VirtualTimeGenServer.call(pid, request)
VirtualTimeGenServer.cast(pid, request)

# Virtual Time GenStateMachine
use VirtualTimeGenStateMachine, callback_mode: :handle_event_function
VirtualTimeGenStateMachine.set_virtual_clock(clock)
VirtualTimeGenStateMachine.send_after(pid, msg, delay)
```

The clock can be configured three ways, in priority order: a local
`virtual_clock: clock` option on `start_link`, a global
`VirtualTimeGenServer.set_virtual_clock/1`, or real time (`real_time: true`, the
production default). Local clocks are how tests stay independent — see
[Local clock injection](docs/local_clock_injection_feature.md).

## Observing a server

Counting messages, tracing them and drawing diagrams belong to whoever is
measuring, not to the clock. The library offers a port rather than an opinion: a
module implementing `VirtualTimeGenServer.Instrumentation` is told about every
message a server receives and sends, and keeps whatever state it likes — the
callbacks run inside the process they observe.

```elixir
defmodule MessageCounter do
  @behaviour VirtualTimeGenServer.Instrumentation

  def on_receive({_kind, _message}, _meta), do: bump(:received)
  def on_send({_kind, _message}, _meta), do: bump(:sent)

  def snapshot(_context), do: counters()

  defp bump(counter) do
    Process.put(:counters, Map.update!(counters(), counter, &(&1 + 1)))
    :ok
  end

  defp counters, do: Process.get(:counters, %{sent: 0, received: 0})
end

{:ok, clock} = VirtualClock.start_link()

{:ok, server} =
  VirtualTimeGenServer.start_link(MyServer, :ok,
    virtual_clock: clock,
    instrumentation: MessageCounter)

VirtualTimeGenServer.call(server, :get_count)
VirtualTimeGenServer.snapshot(server)   # => {:ok, %{sent: 0, received: 1}}
```

`actor_simulation` is built on this port. The library's own queries are never
reported, so reading a server's numbers cannot change them.

## Upgrading and the doctor

`mix virtual_time.doctor` reads your project's own code and says what to change:

```bash
mix virtual_time.doctor           # report
mix virtual_time.doctor --check   # exit non-zero when there is something to fix, for CI
```

It reports calls that no longer exist together with what to write instead, and
modules that live in another package of the library together with the dependency
line that fixes the build. It only reads — it never rewrites your code. A file
that does not parse is reported and skipped, because a project that does not
compile is when this is most useful.

```
The code refers to modules this project does not have.

Add to your deps:

    {:actor_simulation, "~> 1.1.1"}
```

To move existing servers onto the virtual clock, the
[`gen_server_virtual_time_migrate`](https://github.com/d-led/gen_server_virtual_time/tree/main/packages/gen_server_virtual_time_migrate)
task does the edits (it is a repository tool, not a package):

```bash
mix virtual_time.migrate           # what it would change, and what needs a human
mix virtual_time.migrate --write   # apply it
```

## Why virtual time?

| Problem              | Real time   | Virtual time                           |
| -------------------- | ----------- | -------------------------------------- |
| Test 1 hour behavior | 1 hour wait | ~33 ms (measured)                      |
| Flaky timing issues  | Common      | None: the clock is a value you advance |
| Precise assertions   | `>= 10`     | `== 10`                                |
| Deterministic        | No          | Yes                                    |
| Throughput           | 1x          | ~60,000 virtual events per real second |

The clock is what is deterministic: the same run produces the same message
counts and the same timestamps. Tracing is an observation of a run rather than
part of that guarantee, so when several messages fall on the same instant, a
sequence diagram may record them in the order the actors happened to be
scheduled.

## Documentation

- [VirtualClock design](docs/virtual_clock_design.md) — how the clock schedules
  and orders events
- [Local clock injection](docs/local_clock_injection_feature.md) — isolated,
  race-free tests
- [API reference](https://hexdocs.pm/gen_server_virtual_time) ·
  [Changelog](https://github.com/d-led/gen_server_virtual_time/blob/main/CHANGELOG.md)
  ·
  [Contributing guide](https://github.com/d-led/gen_server_virtual_time/blob/main/CONTRIBUTING.md)

## Inspiration

- [RxJS TestScheduler](https://rxjs.dev/api/testing/TestScheduler) - Virtual
  time for reactive programming
- [Don't Wait Forever for Tests](https://github.com/d-led/dont_wait_forever_for_the_tests) -
  Testing philosophy

## License

MIT License - See the [LICENSE](LICENSE) file for details.
