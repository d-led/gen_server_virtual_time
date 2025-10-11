# GenServerVirtualTime

A powerful Elixir library for testing time-dependent GenServers and simulating actor systems using virtual time. Stop waiting forever for your tests!

## Features

- **Virtual Time GenServer**: Drop-in replacement for GenServer that supports both real and virtual time
- **Fast Testing**: Simulate hours of behavior in seconds
- **Actor Simulation DSL**: Define and simulate complex actor systems with message rates and patterns
- **Comprehensive Statistics**: Track message counts, rates, and interactions
- **Zero Wait Time**: No more `Process.sleep` in tests

## Installation

Add `gen_server_virtual_time` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gen_server_virtual_time, "~> 0.1.0"}
  ]
end
```

## Quick Start

### 1. Basic VirtualTimeGenServer

Replace `use GenServer` with `use VirtualTimeGenServer` and use `VirtualTimeGenServer.send_after/3` instead of `Process.send_after/3`:

```elixir
defmodule MyTickerServer do
  use VirtualTimeGenServer
  
  def start_link(interval) do
    VirtualTimeGenServer.start_link(__MODULE__, interval, [])
  end
  
  @impl true
  def init(interval) do
    schedule_tick(interval)
    {:ok, %{interval: interval, count: 0}}
  end
  
  @impl true
  def handle_info(:tick, state) do
    new_count = state.count + 1
    schedule_tick(state.interval)
    {:noreply, %{state | count: new_count}}
  end
  
  defp schedule_tick(interval) do
    VirtualTimeGenServer.send_after(self(), :tick, interval)
  end
end
```

### 2. Testing with Virtual Time

```elixir
test "server ticks correctly with virtual time" do
  # Create a virtual clock
  {:ok, clock} = VirtualClock.start_link()
  VirtualTimeGenServer.set_virtual_clock(clock)
  
  # Start your server
  {:ok, server} = MyTickerServer.start_link(1000)
  
  # Advance virtual time by 5 seconds - happens instantly!
  VirtualClock.advance(clock, 5000)
  
  # Server has ticked 5 times
  assert get_count(server) == 5
end
```

### 3. Comparing Real Time vs Virtual Time

```elixir
# ❌ With real time - takes actual time to run
test "slow real-time test" do
  {:ok, server} = MyTickerServer.start_link(100)
  Process.sleep(500)  # Actually wait 500ms
  assert get_count(server) >= 5
end

# ✅ With virtual time - instant!
test "fast virtual-time test" do
  {:ok, clock} = VirtualClock.start_link()
  VirtualTimeGenServer.set_virtual_clock(clock)
  
  {:ok, server} = MyTickerServer.start_link(100)
  VirtualClock.advance(clock, 500)  # Instant
  assert get_count(server) == 5  # Precise!
end
```

## Actor Simulation DSL

Simulate complex actor systems with message patterns and collect statistics:

### Basic Simulation

```elixir
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:producer, 
      send_pattern: {:periodic, 100, :data},
      targets: [:consumer])
  |> ActorSimulation.add_actor(:consumer)
  |> ActorSimulation.run(duration: 1000)

stats = ActorSimulation.get_stats(simulation)
IO.inspect(stats)
# => %{
#   actors: %{
#     producer: %{sent_count: 10, received_count: 0},
#     consumer: %{sent_count: 0, received_count: 10}
#   }
# }

ActorSimulation.stop(simulation)
```

### Send Patterns

```elixir
# Periodic: Send every N milliseconds
send_pattern: {:periodic, 100, :ping}

# Rate: Send at specific rate per second
send_pattern: {:rate, 50, :event}  # 50 messages/second

# Burst: Send N messages every interval
send_pattern: {:burst, 10, 500, :batch}  # 10 messages every 500ms
```

### Request-Response Pattern

```elixir
on_receive = fn msg, state ->
  case msg do
    :request ->
      # Send response back to sender
      {:send, [{:producer, :response}], state}
    _ ->
      {:ok, state}
  end
end

simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:producer, 
      send_pattern: {:periodic, 100, :request},
      targets: [:consumer])
  |> ActorSimulation.add_actor(:consumer, on_receive: on_receive)
  |> ActorSimulation.run(duration: 1000)
```

### Pipeline Pattern

```elixir
forward = fn msg, state ->
  {:send, [{state.next_stage, msg}], state}
end

simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:source, 
      send_pattern: {:periodic, 100, :data},
      targets: [:stage1])
  |> ActorSimulation.add_actor(:stage1, 
      on_receive: forward,
      initial_state: %{next_stage: :stage2})
  |> ActorSimulation.add_actor(:stage2, 
      on_receive: forward,
      initial_state: %{next_stage: :stage3})
  |> ActorSimulation.add_actor(:stage3)
  |> ActorSimulation.run(duration: 1000)
```

### Pub-Sub Pattern

```elixir
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:publisher, 
      send_pattern: {:periodic, 200, :event},
      targets: [:sub1, :sub2, :sub3])
  |> ActorSimulation.add_actor(:sub1)
  |> ActorSimulation.add_actor(:sub2)
  |> ActorSimulation.add_actor(:sub3)
  |> ActorSimulation.run(duration: 1000)

stats = ActorSimulation.get_stats(simulation)
# Publisher sends to all 3 subscribers
# stats.actors[:publisher].sent_count == 15  # 5 ticks * 3 subscribers
```

### High-Frequency Simulations

Simulate hours of behavior in seconds:

```elixir
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:high_freq_producer, 
      send_pattern: {:rate, 1000, :tick},  # 1000 messages/second
      targets: [:consumer])
  |> ActorSimulation.add_actor(:consumer)
  |> ActorSimulation.run(duration: 3_600_000)  # 1 hour

stats = ActorSimulation.get_stats(simulation)
# Simulated 3.6 million messages in under a minute!
```

## API Reference

### VirtualClock

- `VirtualClock.start_link/1` - Start a virtual clock
- `VirtualClock.now/1` - Get current virtual time
- `VirtualClock.advance/2` - Advance time by milliseconds
- `VirtualClock.advance_to_next/1` - Advance to next scheduled event
- `VirtualClock.send_after/4` - Schedule a message
- `VirtualClock.cancel_timer/2` - Cancel a scheduled timer

### VirtualTimeGenServer

- `VirtualTimeGenServer.set_virtual_clock/1` - Use virtual time
- `VirtualTimeGenServer.use_real_time/0` - Use real time (default)
- `VirtualTimeGenServer.send_after/3` - Schedule message (auto-delegates)
- `VirtualTimeGenServer.start_link/3` - Start a VirtualTimeGenServer

### ActorSimulation

- `ActorSimulation.new/0` - Create new simulation
- `ActorSimulation.add_actor/3` - Add actor to simulation
- `ActorSimulation.run/2` - Run simulation for duration
- `ActorSimulation.get_stats/1` - Get statistics
- `ActorSimulation.stop/1` - Stop and cleanup simulation

## Inspiration

This library was inspired by:
- [RxJS TestScheduler](https://rxjs.dev/api/testing/TestScheduler) - Virtual time for reactive programming
- [Don't Wait Forever for Tests](https://github.com/d-led/dont_wait_forever_for_the_tests) - Testing time-dependent behavior

## Why Virtual Time?

### Problem
```elixir
# ❌ This test takes 10 seconds to run!
test "heartbeat every second for 10 seconds" do
  {:ok, server} = HeartbeatServer.start_link(1000)
  Process.sleep(10_000)
  assert get_heartbeat_count(server) == 10
end
```

### Solution
```elixir
# ✅ This test completes instantly!
test "heartbeat every second for 10 seconds" do
  {:ok, clock} = VirtualClock.start_link()
  VirtualTimeGenServer.set_virtual_clock(clock)
  
  {:ok, server} = HeartbeatServer.start_link(1000)
  VirtualClock.advance(clock, 10_000)
  
  assert get_heartbeat_count(server) == 10
end
```

## Benefits

1. **⚡ Fast Tests**: Simulate hours in seconds
2. **🎯 Precise**: No flaky timing issues
3. **🔬 Deterministic**: Repeatable results
4. **📊 Statistics**: Built-in metrics collection
5. **🧪 Easy Testing**: Simple API, drop-in replacement

## Examples

See the `test/` directory for comprehensive examples:
- `test/virtual_clock_test.exs` - Virtual clock basics
- `test/virtual_time_gen_server_test.exs` - GenServer with virtual time
- `test/actor_simulation_test.exs` - Actor system simulation

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please open an issue or PR.

## Acknowledgments

Built with ❤️ for the Elixir community. Special thanks to the RxJS team for inspiration.
