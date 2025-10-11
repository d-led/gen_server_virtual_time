# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Termination Conditions** - Simulations can now terminate based on actor state rather than fixed time
  - New `terminate_when` option for `ActorSimulation.run/2`
  - New `collect_current_stats/1` function for checking state during simulation
  - `actual_duration` field tracks how long simulation actually ran
  - Fully backward compatible - existing code works unchanged

- **Enhanced Mermaid Diagrams** - Using advanced [Mermaid sequence diagram features](https://docs.mermaidchart.com/mermaid-oss/syntax/sequenceDiagram.html)
  - Solid arrows (`->>`) for synchronous calls
  - Dotted arrows (`-->>`) for asynchronous casts
  - Activation boxes showing when actors process messages
  - Timestamp annotations with `Note over`
  - Options: `enhanced: true/false`, `timestamps: true/false`

- **Dining Philosophers Example** - Classic concurrency problem solved
  - Deadlock-free solution with asymmetric fork acquisition
  - Configurable number of philosophers (2, 3, 5, etc.)
  - Full trace visualization with sequence diagrams
  - Demonstration of condition-based termination

- **Diagram Generation in Tests** - Auto-generate viewable HTML files
  - Self-contained HTML with CDN-based Mermaid.js
  - PlantUML diagrams via PlantUML server
  - Index page to browse all diagrams
  - Stored in `test/output/` for visual progress tracking

### Changed
- **Documentation** - Reorganized to lead with "Show Me The Code"
  - Quick start examples come first
  - API reference moved after practical examples
  - All examples tested in `test/documentation_test.exs`

## [0.1.0] - 2025-10-11

### Added
- Initial release
- **VirtualTimeGenServer** - Drop-in GenServer replacement with virtual time
- **VirtualClock** - Virtual time management and event scheduling
- **Time Backend System** - Switchable real/virtual time backends
- **Actor Simulation DSL** - Define and simulate complex actor systems
- **Send Patterns** - Periodic, rate-based, and burst message patterns
- **Process-in-the-Loop** - Mix real GenServers with simulated actors
- **Pattern Matching Responses** - Declarative message handling with `on_match`
- **Sync/Async Communication** - Support for call, cast, and send
- **Message Tracing** - Capture all inter-actor communication
- **PlantUML Generation** - Generate PlantUML sequence diagrams
- **Mermaid Generation** - Generate Mermaid sequence diagrams
- **Statistics Collection** - Track message counts and rates
- Comprehensive test suite (70+ tests)
- Examples and demos
- Complete documentation

### Performance
- 100x+ speedup for time-dependent tests
- ~6,000 virtual events processed per real second
- Deterministic, reproducible test results

[Unreleased]: https://github.com/dmitryledentsov/gen_server_virtual_time/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/dmitryledentsov/gen_server_virtual_time/releases/tag/v0.1.0
