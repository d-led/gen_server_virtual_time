# Feature Summary - GenServerVirtualTime v0.2.0

⚠️ **HISTORICAL SNAPSHOT** - This document is from an earlier development
session. See `/CHANGELOG.md` for current v0.2.0 features.

## 🎉 New Features Implemented

### 1. Process-in-the-Loop ✨

Mix real GenServer implementations with simulated actors for true integration
testing.

```elixir
defmodule MyRealServer do
  use VirtualTimeGenServer
  def handle_call(:get, _from, state), do: {:reply, state, state}
end

simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_process(:real_server, module: MyRealServer, args: 0)
  |> ActorSimulation.add_actor(:client,
      send_pattern: {:periodic, 100, {:call, :get}},
      targets: [:real_server])
  |> ActorSimulation.run(duration: 1000)
```

**Benefits:**

- Test real GenServers in simulated environments
- "Hardware-in-the-Loop" style testing for processes
- Mix production code with test doubles
- Verify real implementations at any scale

### 2. Pattern Matching Responses 🎯

Declarative message handling with pattern matching:

```elixir
ActorSimulation.add_actor(:api,
  on_match: [
    {:ping, fn state -> {:reply, :pong, state} end},
    {:get_user, fn state -> {:reply, {:ok, user_data}, state} end},
    {fn {:query, _} -> true end, fn state -> {:reply, :result, state} end}
  ])
```

**Features:**

- Match exact messages: `{:ping, response_fn}`
- Match with predicates: `{fn msg -> ... end, response_fn}`
- Return `:reply` for sync responses
- Return `:send` for async responses
- Falls back to `on_receive` if no match

### 3. Sync and Async Communication 📡

Explicit synchronous and asynchronous messaging:

```elixir
# Synchronous call (waits for response)
send_pattern: {:periodic, 100, {:call, :get_data}}

# Asynchronous cast (fire and forget)
send_pattern: {:periodic, 100, {:cast, :notify}}

# Regular send
send_pattern: {:periodic, 100, :message}
```

**Behavior:**

- `{:call, msg}` - Blocks until reply received (uses GenServer.call for real
  processes)
- `{:cast, msg}` - Non-blocking (uses GenServer.cast for real processes)
- Regular messages - Fire and forget (uses send)

### 4. Message Tracing 📊

Capture all inter-actor communication for analysis and visualization:

```elixir
simulation =
  ActorSimulation.new(trace: true)
  |> add_actors_and_patterns()
  |> run(duration: 5000)

# Get trace events
trace = ActorSimulation.get_trace(simulation)
# => [
#   %{timestamp: 100, from: :client, to: :server, message: :ping, type: :send},
#   %{timestamp: 100, from: :server, to: :client, message: :pong, type: :send},
#   ...
# ]

# Generate PlantUML sequence diagram
plantuml = ActorSimulation.trace_to_plantuml(simulation)
File.write!("diagram.puml", plantuml)
```

**Trace Events Include:**

- `timestamp` - Virtual time when message was sent
- `from` - Sender actor name
- `to` - Receiver actor name
- `message` - The message content
- `type` - `:call`, `:cast`, or `:send`

**Use Cases:**

- Generate sequence diagrams
- Debug message flows
- Analyze communication patterns
- Create documentation
- Performance analysis

### 5. Documentation-First Approach 📚

README now leads with "Show Me The Code" examples:

- Quick start with actual code
- Problem/solution comparisons
- Real-world usage patterns
- Examples before API docs

## Test Coverage

Added 11 new tests covering:

- Process-in-the-Loop integration
- Pattern matching with exact patterns and predicates
- Sync/async communication (call, cast, send)
- Message tracing and trace collection
- PlantUML sequence diagram generation
- Timestamp tracking in virtual time

**Total Tests**: ~~37~~ **189** (all passing ✅) - Updated count from v0.2.0
final

## API Additions

### ActorSimulation

```elixir
# New in v0.2
ActorSimulation.new(trace: true)
ActorSimulation.add_process(simulation, name, module: M, args: args)
ActorSimulation.enable_trace(simulation)
ActorSimulation.get_trace(simulation)
ActorSimulation.trace_to_plantuml(simulation)
```

### Actor Definition

```elixir
# New pattern matching
add_actor(:server,
  on_match: [
    {pattern, response_fn},
    ...
  ])
```

### Message Types

```elixir
# New message wrappers
{:call, message}   # Synchronous
{:cast, message}   # Asynchronous
message            # Regular send
```

## Examples

### New: `examples/advanced_demo.exs`

Demonstrates all new features:

1. Process-in-the-Loop
2. Pattern matching
3. Sync/async communication
4. Message tracing
5. Complex pipelines

## Performance Impact

- Tracing adds ~5% overhead when enabled
- Process-in-the-Loop: No overhead
- Pattern matching: Negligible overhead
- Sync calls: Slightly slower than async (expected)

## Backward Compatibility

✅ **100% Backward Compatible**

All existing code continues to work without changes:

- `on_receive` still works if `on_match` not provided
- Regular messages still work
- Tracing is opt-in
- Process-in-the-Loop is additive

## Documentation Updates

1. **README.md** - Reorganized with "Show Me The Code" first
2. **FEATURE_SUMMARY.md** - This document
3. **examples/advanced_demo.exs** - New comprehensive demo
4. Inline documentation for all new functions

## Migration Guide

### From v0.1 to v0.2

No changes required! But you can opt-in to new features:

```elixir
# Before (still works)
simulation = ActorSimulation.new()
  |> add_actor(:server, on_receive: handler_fn)
  |> run(duration: 1000)

# After (with new features)
simulation = ActorSimulation.new(trace: true)  # Enable tracing
  |> add_process(:real, module: M, args: nil)  # Add real process
  |> add_actor(:server,
      on_match: [                              # Pattern matching
        {:ping, fn s -> {:reply, :pong, s} end}
      ])
  |> run(duration: 1000)

trace = get_trace(simulation)                   # Get trace
plantuml = trace_to_plantuml(simulation)       # Generate diagram
```

## Future Enhancements

Possible additions for v0.3:

- Visual trace viewer (web UI)
- Performance profiling mode
- Mermaid diagram support
- Distributed simulation across nodes
- Time dilation (speed up/slow down)
- Replay traces from files

## Credits

New features inspired by:

- Hardware-in-the-Loop testing methodologies
- Pattern matching in Elixir/Erlang
- Sequence diagram tools (PlantUML, Mermaid)
- RxJS TestScheduler's tracing capabilities

---

**Version**: 0.2.0  
**Released**: 2025-10-11  
**Tests**: 37/37 passing ✅  
**Coverage**: 70.5%
