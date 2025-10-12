# Development Documentation

Documentation for developers working on the GenServerVirtualTime library.

## Versioning & Publishing

- **[VERSIONING.md](VERSIONING.md)** - Complete guide to version management,
  release workflow, and publishing
- **[PUBLISHING.md](PUBLISHING.md)** - Additional publishing instructions

## Virtual Clock Configuration: Global vs Local

### Design Philosophy

One might expect to inject configuration values (e.g., clock pid, module, etc.)
directly into each actor's implementation. However, this library uses a **global
virtual time** approach by default. Here's why:

### Why Global Virtual Time?

**Actor systems require coordinated time.** When testing distributed systems or
actor-based applications, all components must operate in the same timeframe.
Consider:

```elixir
# Producer sends message every 100ms
# Consumer processes within 50ms
# If they're on different timelines, timing relationships break!
```

The global approach (via `Process.put(:virtual_clock, clock)` inherited by
children) ensures:

- All actors share the same timeline
- Timing relationships are preserved (e.g., request/response patterns)
- Message ordering matches production behavior
- Simulations remain deterministic

### But What About Isolation?

The global approach works perfectly when testing a single actor system. However,
you might have:

- Multiple independent systems in one BEAM instance
- Integration tests mixing virtual and real time
- Parallel test scenarios requiring isolation

**This is where local clock injection becomes essential.**

### Local Clock Injection API

The library now supports **both** approaches without breaking backwards
compatibility:

```elixir
# GLOBAL: All actors share one timeline (default, best for most cases)
{:ok, clock} = VirtualClock.start_link()
VirtualTimeGenServer.set_virtual_clock(clock)
{:ok, actor1} = MyActor.start_link()
{:ok, actor2} = MyActor.start_link()
VirtualClock.advance(clock, 1000)  # Both actors advance together

# LOCAL: Each actor/system can have its own timeline
{:ok, clock1} = VirtualClock.start_link()
{:ok, clock2} = VirtualClock.start_link()
{:ok, actor1} = VirtualTimeGenServer.start_link(MyActor, :ok, virtual_clock: clock1)
{:ok, actor2} = VirtualTimeGenServer.start_link(MyActor, :ok, virtual_clock: clock2)
VirtualClock.advance(clock1, 1000)  # Only actor1 advances
VirtualClock.advance(clock2, 500)   # Only actor2 advances

# MIXED: Some actors use virtual time, others use real time
{:ok, clock} = VirtualClock.start_link()
{:ok, virtual_actor} = VirtualTimeGenServer.start_link(MyActor, :ok, virtual_clock: clock)
{:ok, real_actor} = VirtualTimeGenServer.start_link(MyActor, :ok, real_time: true)
```

### Priority Order

When determining which clock to use, the system follows this priority:

1. **Local options** (`virtual_clock:` or `real_time:` in `start_link/3`) -
   Highest priority
2. **Global Process dictionary** (`VirtualTimeGenServer.set_virtual_clock/1`)
3. **Real time** (default)

### When to Use Which?

**Use Global Clock:**

- Testing actor systems where components interact
- Simulating distributed systems with timing dependencies
- When all actors should advance together (most common case)
- Examples: chat systems, trading platforms, game servers

**Use Local Clock:**

- Running multiple independent simulations in parallel
- Testing components in complete isolation
- Mixing virtual and real time in integration tests
- Per-test isolation in parallel test suites
- Examples: separate payment processing and analytics systems

**Use Real Time:**

- Production deployments
- Integration tests with external systems (databases, APIs)
- Performance benchmarking
- When you actually want to wait for real time to pass

### Implementation Details

The local injection works by:

1. Extracting `virtual_clock` or `real_time` options from `start_link/3`
2. Overriding the global Process dictionary values for that specific process
3. Setting up the process with the correct time backend before calling `init/1`
4. Allowing child processes to inherit the local clock naturally

This maintains backwards compatibility—existing code using the global approach
continues to work exactly as before.

## Project Structure

```
lib/
├── gen_server_virtual_time.ex    # Main entry point
├── virtual_clock.ex               # Virtual time scheduler
├── virtual_time_gen_server.ex     # GenServer wrapper
├── time_backend.ex                # Backend behavior
└── actor_simulation/              # Actor DSL & code generation
    ├── actor_simulation.ex        # Main DSL
    ├── definition.ex              # Actor definitions
    ├── actor.ex                   # Actor implementation
    ├── stats.ex                   # Statistics collection
    ├── omnetpp_generator.ex       # OMNeT++ code gen
    └── caf_generator.ex           # CAF code gen
```

## Running Tests

```bash
# All tests
mix test

# Specific test file
mix test test/virtual_clock_test.exs

# With coverage
mix coveralls

# Generate HTML coverage report
mix coveralls.html
```

## Code Quality

```bash
# Run all quality checks
mix precommit

# Individual checks
mix format --check-formatted
mix credo --strict
mix dialyzer
```

## Documentation

```bash
# Generate documentation
mix docs

# View locally
open doc/index.html
```

## Examples

```bash
# Run demo scripts
mix run examples/demo.exs
mix run examples/omnetpp_demo.exs
mix run examples/caf_demo.exs
```

## Code Generation Validation

```bash
# Validate OMNeT++ output
mix run scripts/validate_omnetpp_output.exs

# Validate CAF output
mix run scripts/validate_caf_output.exs

# Generate fresh examples
mix run scripts/generate_omnetpp_examples.exs
mix run scripts/generate_caf_examples.exs
```

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) in the root directory.

## Release Process

Use the `bump_version.sh` script to manage versions:

```bash
# Bump version (patch, minor, major, rc, or release)
./scripts/bump_version.sh patch

# Run quality checks
mix precommit

# Commit, tag, and push
git add -A
git commit -m "Release v0.x.x"
git tag v0.x.x
git push && git push --tags
```

The GitHub Actions workflow will automatically publish to Hex.pm when you push a
tag.

See [VERSIONING.md](VERSIONING.md) for complete details.
