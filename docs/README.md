# Documentation Index

Welcome to the `gen_server_virtual_time` documentation!

## Core Concepts

- [Main README](../README.md) - Project overview and quick start
- [CHANGELOG](../CHANGELOG.md) - Version history and changes

## Code Generators

Transform ActorSimulation DSL into production C++ code:

- **[Generators Overview](generators.md)** - Quick start with single-file scripts
- **[OMNeT++ Generator](omnetpp_generator.md)** - Network simulations
- **[CAF Generator](caf_generator.md)** - Production actor systems with callbacks
- **[Pony Generator](pony_generator.md)** - Capabilities-secure actors

## Examples

All examples are in the [`examples/`](../examples/) directory:

### Single-File Scripts

Use these with `Mix.install` - no setup required!

- [`single_file_omnetpp.exs`](../examples/single_file_omnetpp.exs)
- [`single_file_caf.exs`](../examples/single_file_caf.exs)
- [`single_file_pony.exs`](../examples/single_file_pony.exs)

### Generated Projects

Complete, buildable C++ projects:

**OMNeT++:**
- [`omnetpp_pubsub/`](../examples/omnetpp_pubsub/)
- [`omnetpp_pipeline/`](../examples/omnetpp_pipeline/)
- [`omnetpp_burst/`](../examples/omnetpp_burst/)
- [`omnetpp_loadbalanced/`](../examples/omnetpp_loadbalanced/)

**CAF:**
- [`caf_pubsub/`](../examples/caf_pubsub/)
- [`caf_pipeline/`](../examples/caf_pipeline/)
- [`caf_burst/`](../examples/caf_burst/)
- [`caf_loadbalanced/`](../examples/caf_loadbalanced/)

**Pony:**
- [`pony_pubsub/`](../examples/pony_pubsub/)
- [`pony_pipeline/`](../examples/pony_pipeline/)
- [`pony_burst/`](../examples/pony_burst/)
- [`pony_loadbalanced/`](../examples/pony_loadbalanced/)

## Development

- [Contributing](../CONTRIBUTING.md) - How to contribute
- [Scripts](../scripts/README.md) - Automation scripts

## Quick Links

- [Hex Package](https://hex.pm/packages/gen_server_virtual_time)
- [GitHub Repository](https://github.com/yourusername/gen_server_virtual_time)
- [Online Documentation](https://hexdocs.pm/gen_server_virtual_time)
