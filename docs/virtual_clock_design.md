# Virtual Clock Design: Global vs Local Configuration

## Overview

This document explains the design decision behind the virtual clock
configuration in GenServerVirtualTime and the local injection API added to
support more use cases.

## The Design Question

One might expect to inject configuration values (e.g., `clock_pid`, `module`,
etc.) directly into each actor's implementation:

```elixir
# Hypothetical per-actor injection
defmodule MyActor do
  use VirtualTimeGenServer, clock: some_clock
end
```

Instead, this library uses a **global virtual time** approach by default, with
**local injection** as an option.

## Why Global Virtual Time?

### The Core Principle: Actor Systems Need Coordinated Time

When testing distributed systems or actor-based applications, **all components
must operate in the same timeframe**. This isn't a limitation—it's a requirement
for accurate simulation.

Consider this scenario:

```elixir
# Producer sends a message every 100ms
# Consumer must respond within 50ms
# If they're on different timelines, the timing contract breaks!
```

### How It Works

The global approach uses the Process dictionary
(`Process.put(:virtual_clock, clock)`), which is naturally inherited by child
processes:

```elixir
# Set once in your test
{:ok, clock} = VirtualClock.start_link()
VirtualTimeGenServer.set_virtual_clock(clock)

# All actors automatically share the same timeline
{:ok, actor1} = MyActor.start_link()
{:ok, actor2} = MyActor.start_link()
{:ok, actor3} = MyActor.start_link()

# Advance time once - ALL actors move forward together
VirtualClock.advance(clock, 1000)
```

### Benefits

1. **Timing relationships are preserved** - Request/response patterns work
   correctly
2. **Message ordering matches production** - Race conditions behave
   realistically
3. **Simulations remain deterministic** - Same input = same output
4. **Convenient API** - Set once, applies everywhere
5. **Natural inheritance** - Child processes automatically use parent's clock

## But What About Isolation?

The global approach works perfectly for testing a single actor system. However,
real BEAM applications often have:

- **Multiple independent subsystems** in one node
- **Integration tests** mixing virtual and real time
- **Parallel test scenarios** requiring isolation
- **Microservices** that shouldn't share state

**This is where local clock injection becomes essential.**

## Local Clock Injection API

The library now supports **both** approaches without breaking backwards
compatibility.

### API Design

Local clock injection uses standard Elixir options:

```elixir
# Option 1: Inject a specific virtual clock
{:ok, clock} = VirtualClock.start_link()
{:ok, server} = VirtualTimeGenServer.start_link(
  MyActor,
  :ok,
  virtual_clock: clock
)

# Option 2: Force real time (override global clock)
{:ok, server} = VirtualTimeGenServer.start_link(
  MyActor,
  :ok,
  real_time: true
)
```

### Priority Order

When determining which clock to use:

1. **Local options** (`virtual_clock:` or `real_time:` in `start_link/3`) -
   Highest priority
2. **Global Process dictionary** (`VirtualTimeGenServer.set_virtual_clock/1`)
3. **Real time** (default)

This ensures:

- Local options always win (explicit > implicit)
- Global settings work for the common case
- Backwards compatibility is maintained

## When to Use Which?

### Use Global Clock When:

✅ Testing actor systems where components interact  
✅ Simulating distributed systems with timing dependencies  
✅ You want all actors to advance together (most common case)  
✅ Timing relationships between actors matter

**Examples:**

- Chat systems (message ordering)
- Trading platforms (order matching)
- Game servers (synchronized state)
- Workflow engines (step coordination)

**Code:**

```elixir
{:ok, clock} = VirtualClock.start_link()
VirtualTimeGenServer.set_virtual_clock(clock)

{:ok, producer} = Producer.start_link()
{:ok, consumer1} = Consumer.start_link()
{:ok, consumer2} = Consumer.start_link()

VirtualClock.advance(clock, 1000)  # All advance together
```

### Use Local Clock When:

✅ Running multiple independent simulations in parallel  
✅ Testing components in complete isolation  
✅ Each system needs its own timeline  
✅ Per-test isolation in parallel test suites

**Examples:**

- Parallel test scenarios
- Multiple independent systems in one node
- Component isolation tests
- Different time scales for different systems

**Code:**

```elixir
{:ok, clock1} = VirtualClock.start_link()
{:ok, clock2} = VirtualClock.start_link()

{:ok, system1} = VirtualTimeGenServer.start_link(
  PaymentProcessor, :ok, virtual_clock: clock1
)
{:ok, system2} = VirtualTimeGenServer.start_link(
  AnalyticsSystem, :ok, virtual_clock: clock2
)

VirtualClock.advance(clock1, 1000)  # Only system1 advances
VirtualClock.advance(clock2, 5000)  # Only system2 advances
```

### Use Real Time When:

✅ Production deployments  
✅ Integration tests with external systems (databases, APIs)  
✅ Performance benchmarking  
✅ You actually want to wait for real time to pass

**Code:**

```elixir
# Production
{:ok, server} = VirtualTimeGenServer.start_link(
  MyActor, :ok, real_time: true
)

# Or use real time everywhere (default)
VirtualTimeGenServer.use_real_time()
```

### Mixed Mode: Virtual + Real

✅ Integration testing with external systems  
✅ Business logic uses virtual time, I/O uses real time  
✅ Testing how virtual systems interact with real-time dependencies

**Code:**

```elixir
{:ok, clock} = VirtualClock.start_link()

# Virtual time for business logic (fast testing)
{:ok, business_logic} = VirtualTimeGenServer.start_link(
  PaymentProcessor, :ok, virtual_clock: clock
)

# Real time for database connection pool
{:ok, db_pool} = VirtualTimeGenServer.start_link(
  DBPool, :ok, real_time: true
)

VirtualClock.advance(clock, 5000)  # Only business logic advances
Process.sleep(100)                 # DB pool operates on real time
```

## Implementation Details

### How Local Injection Works

The implementation extracts time-related options from `start_link/3` and sets up
the process before calling `init/1`:

```elixir
def start_link(module, init_arg, opts \\ []) do
  {virtual_clock, opts} = Keyword.pop(opts, :virtual_clock)
  {real_time, opts} = Keyword.pop(opts, :real_time, false)

  {final_clock, final_backend} = determine_time_config(virtual_clock, real_time)

  init_fun = fn ->
    if final_clock do
      Process.put(:virtual_clock, final_clock)
    end
    Process.put(:time_backend, final_backend)

    module.init(init_arg)
  end

  GenServer.start_link(Wrapper, {init_fun, module}, opts)
end
```

### Backwards Compatibility

The local injection API is **100% backwards compatible**:

- Existing code using global clocks continues to work unchanged
- No breaking API changes
- Local options are additive
- Priority system ensures predictable behavior

## Testing Strategy

The implementation includes comprehensive tests:

1. **Global clock tests** - Ensure coordinated simulation works
2. **Local clock tests** - Verify isolation between systems
3. **Mixed mode tests** - Confirm virtual + real time interaction
4. **Priority tests** - Local options override global settings
5. **Backwards compatibility** - All existing tests pass unchanged

See `test/virtual_time_gen_server_test.exs` for examples.

## Examples

See `examples/clock_modes_demo.exs` for a comprehensive demonstration of:

- Global clock mode (coordinated simulation)
- Local clock mode (isolated simulations)
- Mixed mode (virtual + real time)

Run with:

```bash
mix run examples/clock_modes_demo.exs
```

## Conclusion

The combination of **global virtual time** (default, best for most cases) and
**local clock injection** (for advanced scenarios) provides:

1. ✅ **Simplicity** - Global clock for the common case
2. ✅ **Power** - Local injection for complex scenarios
3. ✅ **Flexibility** - Mix virtual and real time as needed
4. ✅ **Compatibility** - No breaking changes
5. ✅ **Correctness** - Coordinated time for actor systems

This design ensures that actor systems can be tested with proper timing
relationships while still supporting advanced use cases like parallel
simulations and mixed-mode testing.
