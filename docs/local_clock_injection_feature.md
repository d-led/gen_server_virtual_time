# Feature Summary: Local Virtual Clock Injection API

## What Was Added

A new **local virtual clock injection API** that allows passing virtual clocks directly to individual `VirtualTimeGenServer` processes, enabling isolated simulations while maintaining full backwards compatibility.

## Changes Made

### 1. Implementation (`lib/virtual_time_gen_server.ex`)

Added support for two new options in `start_link/3` and `start/3`:

```elixir
# Option 1: Inject a specific virtual clock
VirtualTimeGenServer.start_link(MyActor, :ok, virtual_clock: clock_pid)

# Option 2: Force real time (override global clock)
VirtualTimeGenServer.start_link(MyActor, :ok, real_time: true)
```

**Priority Order:**
1. Local options (`virtual_clock:` or `real_time:`) - Highest
2. Global Process dictionary (`set_virtual_clock/1`)
3. Real time (default)

### 2. Tests (`test/virtual_time_gen_server_test.exs`)

Added comprehensive test coverage:

- ✅ Local clock injection with isolated simulations
- ✅ Local clock overrides global clock settings
- ✅ Multiple isolated simulations running concurrently
- ✅ Child processes inherit parent's local clock
- ✅ `real_time: true` option forces real time backend
- ✅ Documentation examples for all three modes

**Test Results:** All 150 tests pass, including existing tests (backwards compatible)

### 3. Documentation

#### Development README (`docs/development/README.md`)

Added comprehensive section explaining:
- Why we use global virtual time (coordinated actor systems)
- When isolation is needed (multiple independent systems)
- How local clock injection works
- Priority order for clock selection
- When to use global vs local vs real time
- Implementation details

#### Module Documentation (`lib/virtual_time_gen_server.ex`)

Updated `@moduledoc` with:
- Examples of both global and local clock usage
- Clear explanation of the three configuration options
- Priority order documentation
- Links to development docs for detailed explanations

#### Design Document (`VIRTUAL_CLOCK_DESIGN.md`)

Created comprehensive design documentation covering:
- The design philosophy
- Why global virtual time is the default
- When and why to use local injection
- Detailed usage examples for all modes
- Implementation details
- Testing strategy

### 4. Examples (`examples/clock_modes_demo.exs`)

Created a comprehensive demonstration showing:

**Scenario 1: Global Clock (Coordinated Simulation)**
- Multiple components sharing one timeline
- All actors advance together
- Essential for distributed systems

**Scenario 2: Local Clock (Isolated Simulations)**
- Independent systems with separate timelines
- Testing components in isolation
- Parallel test scenarios

**Scenario 3: Mixed Mode (Virtual + Real Time)**
- Virtual time for business logic (fast testing)
- Real time for external integrations
- Best of both worlds

Run with: `mix run examples/clock_modes_demo.exs`

## Why This Design?

### Global Virtual Time (Default)

**Rationale:** Actor systems require coordinated time. When testing distributed systems, all components must operate in the same timeframe to preserve timing relationships and maintain realistic behavior.

**Benefits:**
- ✅ Timing relationships preserved (request/response patterns work correctly)
- ✅ Message ordering matches production
- ✅ Simulations remain deterministic
- ✅ Convenient API (set once, applies everywhere)
- ✅ Natural inheritance (children use parent's clock)

### Local Clock Injection (Advanced)

**Rationale:** Real BEAM applications often have multiple independent subsystems, integration tests mixing virtual and real time, or parallel test scenarios requiring isolation.

**Benefits:**
- ✅ Multiple independent simulations in one node
- ✅ Component isolation for unit testing
- ✅ Parallel test scenarios
- ✅ Mix virtual and real time as needed

## Backwards Compatibility

**100% backwards compatible:**
- ✅ All existing tests pass unchanged
- ✅ No breaking API changes
- ✅ Local options are additive
- ✅ Default behavior unchanged

## Use Cases

### Use Global Clock For:
- Chat systems (message ordering)
- Trading platforms (order matching)
- Game servers (synchronized state)
- Workflow engines (step coordination)
- Any system where actors interact with timing dependencies

### Use Local Clock For:
- Parallel test scenarios
- Multiple independent systems in one node
- Component isolation tests
- Different time scales for different systems
- Microservices that shouldn't share state

### Use Mixed Mode For:
- Integration tests with databases
- Testing with external APIs
- Performance benchmarking
- Business logic (virtual) + I/O (real)

## Code Examples

### Before (Global Only)

```elixir
test "coordinated simulation" do
  {:ok, clock} = VirtualClock.start_link()
  VirtualTimeGenServer.set_virtual_clock(clock)
  
  {:ok, actor1} = MyActor.start_link()
  {:ok, actor2} = MyActor.start_link()
  
  VirtualClock.advance(clock, 1000)  # Both advance together
end
```

### After (Global + Local)

```elixir
# Still works exactly the same
test "coordinated simulation" do
  {:ok, clock} = VirtualClock.start_link()
  VirtualTimeGenServer.set_virtual_clock(clock)
  
  {:ok, actor1} = MyActor.start_link()
  {:ok, actor2} = MyActor.start_link()
  
  VirtualClock.advance(clock, 1000)
end

# NEW: Isolated simulations
test "independent simulations" do
  {:ok, clock1} = VirtualClock.start_link()
  {:ok, clock2} = VirtualClock.start_link()
  
  {:ok, actor1} = VirtualTimeGenServer.start_link(
    MyActor, :ok, virtual_clock: clock1
  )
  {:ok, actor2} = VirtualTimeGenServer.start_link(
    MyActor, :ok, virtual_clock: clock2
  )
  
  VirtualClock.advance(clock1, 1000)  # Only actor1 advances
  VirtualClock.advance(clock2, 500)   # Only actor2 advances
end

# NEW: Mixed mode
test "virtual + real time" do
  {:ok, clock} = VirtualClock.start_link()
  
  {:ok, virtual_actor} = VirtualTimeGenServer.start_link(
    MyActor, :ok, virtual_clock: clock
  )
  {:ok, real_actor} = VirtualTimeGenServer.start_link(
    MyActor, :ok, real_time: true
  )
  
  VirtualClock.advance(clock, 1000)  # Only virtual_actor advances
  Process.sleep(100)                 # real_actor uses real time
end
```

## Testing

**Test Coverage:**
- 150 tests total, all passing
- 6 new tests for local clock injection
- 3 documentation example tests
- All existing tests unchanged (backwards compatible)

**Test Execution:**
```bash
mix test                    # All tests (150 tests, 0 failures)
mix test --exclude slow     # Fast tests only
mix run examples/clock_modes_demo.exs  # Interactive demo
```

## Files Changed

### Modified Files:
- `lib/virtual_time_gen_server.ex` - Added local injection support
- `test/virtual_time_gen_server_test.exs` - Added comprehensive tests
- `docs/development/README.md` - Added design explanation

### New Files:
- `examples/clock_modes_demo.exs` - Comprehensive demonstration
- `VIRTUAL_CLOCK_DESIGN.md` - Design documentation
- `FEATURE_SUMMARY.md` - This file

## Migration Guide

**No migration needed!** This is a purely additive feature.

If you want to use the new local injection API:

```elixir
# Before: Global clock (still works)
{:ok, clock} = VirtualClock.start_link()
VirtualTimeGenServer.set_virtual_clock(clock)
{:ok, server} = MyActor.start_link()

# After: Local clock (new option)
{:ok, clock} = VirtualClock.start_link()
{:ok, server} = VirtualTimeGenServer.start_link(
  MyActor, :ok, virtual_clock: clock
)
```

## Future Enhancements

Potential future additions (not in scope for this release):
- Named clocks for easier management
- Clock groups for coordinating subsets of actors
- Clock introspection/debugging tools
- Performance optimizations for large-scale simulations

## Questions?

See:
- `VIRTUAL_CLOCK_DESIGN.md` - Design philosophy and rationale
- `docs/development/README.md` - Developer documentation
- `examples/clock_modes_demo.exs` - Working examples
- `test/virtual_time_gen_server_test.exs` - Test examples

