# Documentation Index

Welcome to the `gen_server_virtual_time` documentation!

## 🚀 Getting Started

- **[Main README](../README.md)** - Project overview and installation
- **[Quick Start](generators.md)** - Generate code in 5 minutes with single-file scripts

## 📚 Core Documentation

### Virtual Time System

- **[Virtual Clock Design](virtual_clock_design.md)** - Architecture and design decisions
- **[Local Clock Injection](local_clock_injection_feature.md)** - Isolated time control
- **[Implementation Summary](implementation_summary.md)** - Technical deep dive

### Code Generators

Transform ActorSimulation DSL into production code across five languages:

- **[OMNeT++ Generator](omnetpp_generator.md)** - Network simulations (C++)
- **[CAF Generator](caf_generator.md)** - Production actors with callbacks (C++)
- **[Pony Generator](pony_generator.md)** - Capabilities-secure actors (Pony)
- **[Phony Generator](phony_generator.md)** - Zero-allocation actors (Go)
- **[VLINGO Generator](vlingo_generator.md)** - Type-safe actors (Java)

### Visualization

- **[Flowchart Reports](flowchart_reports.md)** - Interactive Mermaid diagrams

## 💻 Examples

All examples are in the [`examples/`](../examples/) directory.

### Single-File Scripts (No Installation Required!)

Generate complete projects with just `Mix.install`:

```bash
elixir examples/single_file_omnetpp.exs  # OMNeT++ project
elixir examples/single_file_caf.exs      # CAF project
elixir examples/single_file_pony.exs     # Pony project
elixir examples/single_file_phony.exs    # Go project
```

### Pre-Generated Projects

16+ complete, buildable projects ready to explore:
- **4 OMNeT++ projects** - Network simulations (C++)
- **4 CAF projects** - Actor systems with Catch2 tests (C++)
- **4 Pony projects** - Data-race-free actors (Pony)
- **4 Phony projects** - Zero-allocation actors (Go)

See [`examples/`](../examples/) directory for all projects.

## 🛠️ Development

### For Contributors

- **[Contributing Guide](../CONTRIBUTING.md)** - How to contribute
- **[Development Docs](development/README.md)** - Setup and workflows
- **[Versioning Guide](development/VERSIONING.md)** - Release process
- **[Scripts README](../scripts/README.md)** - Automation tools

### Historical Records

- **[Agent Logs](agent/README.md)** - AI-assisted development history

## 🔗 Links

- **[Hex Package](https://hex.pm/packages/gen_server_virtual_time)** - Published package
- **[GitHub](https://github.com/yourusername/gen_server_virtual_time)** - Source code
- **[HexDocs](https://hexdocs.pm/gen_server_virtual_time)** - API documentation
- **[Changelog](../CHANGELOG.md)** - Version history
