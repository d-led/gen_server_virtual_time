# Development Documentation

Documentation for developers working on the GenServerVirtualTime library.

## Publishing

See [PUBLISHING.md](PUBLISHING.md) for instructions on releasing new versions to Hex.pm.

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

1. Update version in `mix.exs`
2. Update `CHANGELOG.md`
3. Run tests: `mix test`
4. Run quality checks: `mix precommit`
5. Generate docs: `mix docs`
6. Commit changes
7. Create git tag: `git tag v0.x.x`
8. Push tag: `git push origin v0.x.x`
9. Publish to Hex: `mix hex.publish`
10. Publish docs: `mix hex.publish docs`

See [PUBLISHING.md](PUBLISHING.md) for detailed instructions.

