# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2025-10-27

### Added

- VirtualTimeGenStateMachine with full `:gen_statem` support
- `start_link/3`, `start/3`, `call/3`, `cast/2`, `stop/3` functions for VirtualTimeGenStateMachine
- Compilation warnings for global virtual clock operations to prevent race conditions

### Changed

- Optimized VirtualClock event scheduling by using asynchronous operations
- Time backend is now internal and transparent to client code
- VirtualTimeGenServer and VirtualTimeGenStateMachine functions now emit warnings when using global clock injection
- Removed complex wrapper module causing callback conflicts
- Now uses native Erlang `:gen_statem` directly

### Fixed

- State enter callbacks now work correctly in VirtualTimeGenStateMachine
- Long-running simulations timeout issues resolved
- Both `:handle_event_function` and `:state_functions` callback modes supported

## [0.4.0] - 2025-10-15

### Added

- Ractor (Rust) code generator with [Ractor](https://github.com/slawlor/ractor)
  framework
- Single-file generator examples for Ractor and VLINGO
- Documentation for Ractor generator

### Fixed

- Separated generated interface code from customizable implementation code
  across all generators
- Fixed Mermaid flowchart reports missing edges for dynamic sends

## [0.3.0] - 2025-10-14

### Added

- Virtual delays feature for actors
- Quiescence termination mode
- Enhanced diagram generation with trace-based approach
- Dining philosophers example

### Changed

- Refactored sleep handling into `TimeBackend` behaviour
- Enhanced diagram generation

### Fixed

- Corrected termination labels in reports
- Fixed diagram accuracy issues

## [0.2.3] - 2025-10-14

### Added

- Generator documentation in README

### Changed

- Added console output in all generated code
- Implemented thread-safe ConsoleLogger for Pony generator
- Updated all example projects

## [0.2.0] - 2025-10-12

### Added

- Code generators for CAF (C++), Pony, Phony (Go), and VLINGO (Java)
- Mermaid report generator module
- Full GenServer callback support including `handle_continue/2` and call timeout
  handling
- Termination conditions for simulations based on actor state
- Enhanced Mermaid diagrams with sequence diagram features
- Dining philosophers example
- Single-file generator examples
- Generator documentation

### Changed

- Reorganized documentation with quick start examples first
- Enhanced GitHub Actions workflows
- Updated license to include full MIT license text

### Fixed

- Dialyzer warnings
- Flaky tests
- Generator output issues

## [0.1.0] - 2025-10-11

### Added

- Initial release
- VirtualTimeGenServer with virtual time support
- VirtualClock for event scheduling
- Switchable real/virtual time backends
- Actor Simulation DSL
- Message patterns (periodic, rate-based, burst)
- Process-in-the-Loop support
- Pattern matching responses with `on_match`
- Message tracing and Mermaid diagram generation

[Unreleased]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.2.0...HEAD
[0.2.4]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.2.3...v0.2.4
[0.2.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/d-led/gen_server_virtual_time/releases/tag/v0.1.0
