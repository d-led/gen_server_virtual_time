# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Property-based test suites (`test/virtual_clock_property_test.exs`,
  `test/actor_simulation_property_test.exs`) covering time additivity, event
  ordering, cancellation and simulation message counts
- Mutation testing with [muex](https://hex.pm/packages/muex) in place of the
  broken `muzak`/`exavier` dependencies, which fail on current Elixir
- `doctest VirtualClock` so the moduledoc and `cancel_timer/2` examples are
  executed by the test suite

### Changed

- Minimum Elixir version is now 1.19, and minimum OTP 28, matching the
  versions CI verifies. (1.15 was the previous floor, needed by `ex_doc ~>
  0.40`.)
- CI matrix reduced to Elixir 1.19/1.20 with OTP 28/29, and the other five
  workflows aligned, which still pinned Elixir 1.15/1.18 and OTP 25/27
- GitHub Actions updated to their current majors (`checkout` v7, `cache` v6,
  `upload-artifact` v7, `download-artifact` v8, `setup-java` v6, `setup-go` v7,
  the Pages actions, `action-junit-report` v6, `action-gh-release` v3 and
  `setup-rust-toolchain` v2), which also clears the Node 20 deprecation notices
- Updated all dependencies, including `ex_doc` 0.38 → 0.40, `credo` 1.7.13 →
  1.7.19, `dialyxir` 1.4.6 → 1.4.8, `castore` 1.0.15 → 1.0.21
- Consolidated four duplicated message-dispatch blocks in `ActorSimulation.Actor`
  into shared helpers, and nine duplicated acknowledgement clauses in
  `VirtualTimeGenStateMachine.Wrapper` into shared delivery handling
- FOSSA no longer scans `generated/` or `examples/`: they are build output whose
  transitive dependencies (for example `io.vlingo.xoom:xoom-actors`, MPL-2.0)
  are not part of what is published
- README and documentation index restructured to lead with install and runnable
  examples

### Fixed

- Clock deliveries to `VirtualTimeGenServer` actors now carry a token and are
  acknowledged by that token alone. Actors previously acknowledged *every*
  message they handled, so an unrelated message could satisfy the wait for a
  delivered event and let the clock advance while the event was still queued -
  which made simulations intermittently under-count their messages
- `VirtualTimeGenStateMachine` actors use the same token protocol, so a
  `:gen_statem` actor can no longer be advanced past an event it has not
  processed
- `ActorSimulation.run/2` now reads actor statistics until they settle. A single
  pass could sample a downstream actor before an upstream one had forwarded to
  it, so a finished simulation could report zero messages for the last actor in
  a chain
- Events due at the same virtual instant now fire in scheduling order, matching
  real timers (previously reverse order)
- `VirtualClock.scheduled_count/1` now counts every scheduled event; it
  previously reported one per due time, undercounting events that shared a
  timestamp
- `VirtualClock.cancel_timer/2` now returns the remaining virtual milliseconds
  (or `false`), matching the `TimeBackend` behaviour and `Process.cancel_timer/1`
- The acknowledgement watchdog is now tracked in the clock state, so a stale
  timeout can no longer fire against a later wait
- Removed dead code: redundant `Enum.each` clauses in `ActorSimulation.Actor`,
  an unreachable `pattern_to_interval/2` clause in the OMNeT++ generator, and
  unused `VirtualScheduler` accessors that had no server-side handlers

### Test Reliability

- Removed all `Process.sleep/1`-based synchronisation from the test suite: tests
  now wait on the observable effect (`WaitUntil.wait_until/2`) before advancing
  the clock, instead of guessing how long another process needs. The four
  remaining sleeps are deliberate and documented: two gen_server timeouts, which
  cannot be polled because any message resets them, and two `:slow` tests that
  exist to show real time *is* slow
- Replaced real-time deadline assertions with load-tolerant bounds, so a busy
  machine slows the tests down rather than failing them
- Fixed tests that claimed to use virtual time but did not: they scheduled
  timers from the test process, which uses that process's backend - real time by
  default - so the clock advance did nothing and the assertions were vacuous.
  They now schedule from inside the server, which is the documented pattern, and
  assert the resulting state
- Gave assertions to tests that had none (they slept and then stopped the
  server): cancellation, per-instance clocks, `send_after_self/2` and the
  "virtual time is faster than real time" claim now check what they claim
- The dining philosophers diagram test no longer asserts that every philosopher
  eats: concurrent actors have no deterministic ordering, so that outcome is a
  race. It asserts the behaviour the scenario guarantees instead

## [0.5.0] - 2025-10-27

### Added

- VirtualTimeGenStateMachine with full `:gen_statem` support
- `start_link/3`, `start/3`, `call/3`, `cast/2`, `stop/3` functions for
  VirtualTimeGenStateMachine
- Compilation warnings for global virtual clock operations to prevent race
  conditions

### Changed

- Optimized VirtualClock event scheduling by using asynchronous operations
- Time backend is now internal and transparent to client code
- VirtualTimeGenServer and VirtualTimeGenStateMachine functions now emit
  warnings when using global clock injection
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
