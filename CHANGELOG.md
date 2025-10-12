# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1-rc.0] - 2025-10-12

### Added

- **Generator Documentation in README** - Added prominent table listing all 5
  code generators (CAF, Phony, Pony, VLINGO, OMNeT++) with links and feature
  descriptions at the top of README

### Changed

- **Enhanced Console Output in All Generators** - All generated code now
  produces visible output during execution for better demos and debugging:
  - **CAF**: Added `std::cout` logging in callback implementations
  - **Phony**: Added `fmt.Printf` logging in callback implementations
  - **Pony**: Replaced unsafe `@printf` with thread-safe `ConsoleLogger` actor
    following [best practices](https://github.com/d-led/DDDwithActorsPony)
  - **VLINGO**: Added `System.out.println` logging in callback implementations
  - **OMNeT++**: Enhanced `EV` logging with actor names and message details
- **Pony Generator Thread Safety** - Implemented dedicated `ConsoleLogger` actor
  for thread-safe console output
  - Eliminates race conditions from `@printf` FFI calls
  - Uses `env.out` through actor message passing
  - All Pony actors now accept and use `ConsoleLogger` parameter
  - Updated tests to use `ConsoleLogger`
- **Regenerated All Examples** - Updated all example projects in `examples/` and
  `generated/` directories to reflect generator improvements:
  - CAF examples (pubsub, pipeline, burst, loadbalanced)
  - Phony examples (pubsub, pipeline, burst, loadbalanced)
  - Pony examples (pubsub, pipeline, burst, loadbalanced)
  - OMNeT++ examples (pubsub, pipeline, burst, loadbalanced)
  - VLINGO example (loadbalanced)

## [0.2.0] - 2025-10-12

### Added

#### Code Generators

- **CAF (C++ Actor Framework) Generator** - Generate production-ready C++ actor
  code
  - Full actor implementation with message passing
  - CMake build system with Conan dependency management
  - GitHub Actions CI/CD pipeline included
  - Callback-based architecture for custom behavior
  - Comprehensive test generation
  - Examples: pipeline, pubsub, burst, loadbalanced

- **Pony Generator** - Generate code for the Pony actor language
  - Type-safe actor implementations with capabilities
  - Corral package management integration
  - GitHub Actions CI/CD pipeline
  - Callback trait system for extensibility
  - Unit test generation
  - Examples: pipeline, pubsub, burst, loadbalanced

- **Phony (Go) Generator** - Generate Go actor code using the Phony library
  - Lightweight actor implementation
  - Go modules and dependency management
  - GitHub Actions CI/CD pipeline
  - Interface-based callback system
  - Test generation with actor validation
  - Examples: pipeline, pubsub, burst, loadbalanced

- **Vlingo Generator** - Generate Java actor code using Vlingo/Platform
  - Protocol-based actor interfaces
  - Maven build system (pom.xml)
  - Callback-based extensibility
  - JUnit test generation
  - GitHub Actions CI/CD pipeline
  - Example: loadbalanced system

- **Generator Utilities Module** - Common utilities for all code generators
  - File writing with directory creation
  - Indentation helpers
  - Callback template generation
  - Shared code generation patterns

- **Mermaid Report Generator** - Dedicated module for Mermaid diagram generation
  - Flowchart-style actor interaction reports
  - Message flow visualization
  - Statistics integration
  - HTML export with embedded diagrams

#### Enhanced GenServer Support

- **`handle_continue/2` Support** - Full support for GenServer continuation
  callbacks
  - Virtual time-aware continue handling
  - Proper sequencing with other callbacks
  - Test coverage for continue patterns

- **Call Timeout Support** - Proper handling of GenServer call timeouts
  - Virtual time-based timeout simulation
  - Timeout error propagation
  - Test coverage for timeout scenarios

- **Complete GenServer Callbacks** - All standard GenServer callbacks now
  supported
  - `init/1`, `handle_call/3`, `handle_cast/2`, `handle_info/2`
  - `handle_continue/2`, `terminate/2`, `code_change/3`
  - `format_status/1` and `format_status/2`
  - Full compatibility with standard GenServer behavior

#### Testing & Quality

- **Extensive Generator Tests** - Comprehensive test suites for all generators
  - Output validation for each generator
  - Deterministic generation tests
  - Build system verification
  - Example generation scripts

- **GenServer Feature Tests** - New test files for GenServer capabilities
  - `genserver_callbacks_test.exs` - All callback types
  - `genserver_call_timeout_test.exs` - Timeout handling
  - `handle_continue_test.exs` - Continue callback patterns
  - `ridiculous_time_test.exs` - Extreme time scale testing

- **Simulation Testing** - Enhanced simulation test coverage
  - `simulation_timing_test.exs` - Timing accuracy verification
  - `termination_indicator_test.exs` - Termination condition testing
  - `show_me_code_examples_test.exs` - Documentation example validation

#### Examples & Documentation

- **Single-File Generator Examples** - Quick-start examples for each generator
  - `single_file_caf.exs` - CAF generation demo
  - `single_file_pony.exs` - Pony generation demo
  - `single_file_phony.exs` - Phony generation demo
  - `single_file_omnetpp.exs` - OMNeT++ generation demo

- **Multiple Example Projects** - 16 complete example projects generated
  - 4 CAF examples (pipeline, pubsub, burst, loadbalanced)
  - 4 Pony examples (pipeline, pubsub, burst, loadbalanced)
  - 4 Phony examples (pipeline, pubsub, burst, loadbalanced)
  - 4 OMNeT++ examples (pipeline, pubsub, burst, loadbalanced)

- **Generator Documentation** - Comprehensive documentation for all generators
  - `docs/caf_generator.md` - CAF generator guide
  - `docs/pony_generator.md` - Pony generator guide
  - `docs/phony_generator.md` - Phony generator guide
  - `docs/vlingo_generator.md` - Vlingo generator guide
  - `docs/generators.md` - Overview of all generators

- **Mix Task for Pre-commit** - `mix precommit` task for code quality checks
  - Format, compile, test, dialyzer, credo
  - Automated quality gate for development

#### Features from Previous Unreleased

- **Termination Conditions** - Simulations can now terminate based on actor
  state rather than fixed time
  - New `terminate_when` option for `ActorSimulation.run/2`
  - New `collect_current_stats/1` function for checking state during simulation
  - `actual_duration` field tracks how long simulation actually ran
  - Fully backward compatible - existing code works unchanged

- **Enhanced Mermaid Diagrams** - Using advanced
  [Mermaid sequence diagram features](https://docs.mermaidchart.com/mermaid-oss/syntax/sequenceDiagram.html)
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
  - Stored in `test/output/` for visual progress tracking

### Changed

- **Documentation** - Reorganized to lead with "Show Me The Code"
  - Quick start examples come first
  - API reference moved after practical examples
  - All examples tested in `test/documentation_test.exs`
  - Added comprehensive generator documentation

- **README** - Significantly restructured and expanded
  - Better organization of features
  - Code generator section added
  - More practical examples upfront
  - Clearer getting started guide

- **CI/CD Pipeline** - Enhanced GitHub Actions workflows
  - Added Pony validation workflow
  - Added Phony validation workflow
  - Optimized Dialyzer caching
  - Better error handling and retries

- **License** - Updated to include full MIT license text

### Fixed

- **Dialyzer Warnings** - Resolved type specification issues
- **Flaky Tests** - Fixed non-deterministic test failures
- **Generator Output** - Cleaned up trailing whitespace in generated code
- **Pony CI** - Improved PATH handling and added retries for reliability
- **Phony Generator** - Updated to latest version and optimized imports
- **Vlingo Generator** - Fixed various generation issues

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

[Unreleased]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.2.0...HEAD
[0.2.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/d-led/gen_server_virtual_time/releases/tag/v0.1.0
