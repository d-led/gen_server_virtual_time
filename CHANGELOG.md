# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-10-11

### Added
- Initial release of GenServerVirtualTime
- `VirtualClock` module for virtual time management
- `VirtualTimeGenServer` behavior for time-dependent GenServers
- `ActorSimulation` DSL for simulating actor systems
- Actor simulation statistics and tracing
- PlantUML and Mermaid sequence diagram generation
- OMNeT++ C++ code generation from ActorSimulation DSL
- Process-in-the-loop testing support
- Multiple send patterns: periodic, rate-based, and burst
- Pattern matching and function-based message handlers
- Synchronous (call) and asynchronous (cast) message support
- Complete test coverage (70%+)
- Comprehensive documentation with examples
- Demo scripts for basic usage, advanced patterns, and OMNeT++ generation

### Features
- **Virtual Time Testing**: Test time-dependent behavior without waiting
- **Deterministic Execution**: Reproducible test results
- **Fast Simulation**: 10-100x faster than real-time
- **Actor System DSL**: Define complex distributed systems
- **Statistics Collection**: Automatic message counting and timing
- **Visualization**: Generate sequence diagrams from traces
- **OMNeT++ Integration**: Export to production-grade C++ simulations

[Unreleased]: https://github.com/dmitryledentsov/gen_server_virtual_time/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/dmitryledentsov/gen_server_virtual_time/releases/tag/v0.1.0

