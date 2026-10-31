# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.1] - 2026-10-31

### Fixed

- `mix virtual_time.migrate` no longer renames `:erlang.send_after/3` in place:
  that function takes the delay first where `VirtualTimeGenServer.send_after/3`
  takes it last, so the rewrite compiled and then failed at runtime with "not an
  integer / not a pid". Such a line is now reported with the reordering spelled
  out, like every other call the tool cannot prove

## [1.1.0] - 2026-10-31

### Added

- The six generators are
  `ActorSimulation.Codegen.{CAF,OMNeTPP,Phony,Pony,Ractor,Vlingo}`. The 1.0
  names still work: they forward to the new modules and carry a `@deprecated`
  message, so nothing has to change before 2.0. Doing nothing is a supported
  answer; `mix virtual_time.upgrade` is the convenience that turns the warnings
  into silence
- `mix virtual_time.upgrade` (in `gen_server_virtual_time_migrate`) renames
  those modules in a project: fully qualified references, and an alias together
  with the bare short name it introduced, when the name it becomes is free. An
  alias with `as:`, a taken short name and a bare name with no alias are
  reported instead of guessed
- `mix actor_simulation.upgrade` replaces `mix templates.upgrade`, which still
  forwards with a message
- `examples/ticker_erlang` and `examples/ticker_gleam`: the same one-minute
  ticker in Erlang (a `VirtualTimeGenServer` on a rebar3 project) and in Gleam
  (the clock reached through externals), each asserted without waiting

### Changed

- `docs/generators.md` installs `actor_simulation_codegen` instead of the
  pre-split `gen_server_virtual_time`, so its snippets run as printed

### Fixed

- Six GitHub workflows watched paths that moved into `packages/` at the split,
  so the generator validations and the diagram deployment had not run since
  1.0.0; `test/workflow_paths_test.exs` now fails when a filter names a missing
  file
- The build caches key on `VERSION`, so a release no longer makes CI restore a
  `_build` that still believes the sibling packages are a version behind
- CI now enforces the coverage threshold of `actor_simulation`,
  `actor_simulation_codegen` and the migrator, not just the clock's
- The orphaned `lib/mix/tasks/precommit.ex` is gone; the gate lives in `dev/`

## [1.0.1] - 2026-10-31

### Added

- `gen_server_virtual_time_migrate`, a package with one task:
  `mix virtual_time.migrate` rewrites existing `GenServer` code for the virtual
  clock — `use GenServer` → `use VirtualTimeGenServer` with its options kept,
  `Process.send_after/3`, `Process.sleep/1`, `:erlang.send_after/3` and
  `:timer.sleep/1` inside a converted module, and `GenServer.call/cast/stop/…`
  whose target is a module the project converts. It reports by default,
  `--write` applies, `--check` exits non-zero for CI, and it never touches a
  call it cannot prove safe (a pid, a variable, an unconverted target)
- `VirtualTimeGenServer` keeps the options `use GenServer` was given, so
  `restart:` and friends reach the generated `child_spec`

### Changed

- `GenServerVirtualTime.version/0` reports the version the package was compiled
  at, so it cannot drift from the code that is running

## [1.0.0] - 2026-10-31

The library is published as a family of packages that share this version. A
module keeps its name wherever it lives, so upgrading is a dependency, not a
rewrite — `mix virtual_time.doctor` says which one a project is missing.

### Breaking

- `ActorSimulation`, its statistics, its diagrams and the six code generators
  are no longer part of this package. Add `{:actor_simulation, "~> 1.0.0"}` for
  the DSL and `{:actor_simulation_codegen, "~> 1.0.0"}` for the generators; no
  code changes are needed, and `mix virtual_time.doctor` reports exactly which
  line to add and where it is used
- `VirtualClock`, `VirtualTimeGenServer`, `VirtualTimeGenStateMachine`,
  `TimeBackend` and friends keep their names, callbacks and behaviour. That is
  the point of the split: the clock and the OTP wrappers are unaffected
- `DiningPhilosophers` is a test fixture now rather than part of the published
  library, and the maintainer tasks stay in the repository

### Added

- `actor_simulation` package: the actor-system DSL, statistics, sequence
  diagrams and flowchart reports
- `actor_simulation_codegen` package: CAF, Phony, Pony, Ractor, VLINGO XOOM and
  OMNeT++ generators, with their guides
- `mix virtual_time.doctor` reads the project's own module references and says
  which package a missing module lives in, with the `mix.exs` line that fixes
  the build (`--check` exits non-zero, for CI); it also reports calls that were
  removed together with what to write instead
- `VirtualTimeGenServer.Instrumentation`: a port for observing what an
  instrumented process does (`on_receive/2`, `on_send/2`, `snapshot/1`),
  installed per process with the `:instrumentation` start option or with
  `VirtualTimeGenServer.instrument/1`, and read back with
  `VirtualTimeGenServer.snapshot/1`

### Changed

- measuring a system is no longer the clock's job: the wrappers and
  `call/3`/`cast/2` report events to an observer instead of counting into the
  process dictionary, so the library knows nothing about statistics or traces.
  `ActorSimulation.Observer` is what counts a real server in the loop; the
  numbers a simulation reports are unchanged
- the library's own query (`VirtualTimeGenServer.snapshot/1`) is never reported
  to the observer, so reading a server's statistics cannot change them
- the version table the generators read moved with them; one `VERSION` file and
  `elixir scripts/release.exs check` keep every package at the same version

### Removed

- `VirtualTimeGenServer.enable_stats_tracking/0,2`, `get_process_stats/0`,
  `generate_incoming_trace_event/2`, `set_global_trace_collector/1,3` and
  `get_global_trace_collector/0`, together with the `:stats_enabled` start
  option and the `:__vtgs_*` process-dictionary keys they used. Use the
  instrumentation port instead

### Fixed

- the README as published on hex.pm and hexdocs had a link to the century demo
  that pointed at a page that does not exist there, and in-page anchors no
  renderer produces; the demo links to the repository, and linked headings no
  longer start with an emoji, so GitHub and hexdocs agree on the anchor

## [0.7.0] - 2026-10-31

### Added

- `mix virtual_time.doctor` reads the project's own module references and says
  which package of the family a missing module lives in, with the `mix.exs` line
  that fixes the build (`--check` exits non-zero, for CI); it also reports calls
  that were removed together with what to write instead
- `VirtualTimeGenServer.Instrumentation`: a port for observing what an
  instrumented process does (`on_receive/2`, `on_send/2`, `snapshot/1`),
  installed per process with the `:instrumentation` start option or with
  `VirtualTimeGenServer.instrument/1`, and read back with
  `VirtualTimeGenServer.snapshot/1`

### Changed

- measuring a system is no longer the clock's job: the wrappers and
  `call/3`/`cast/2` report events to an observer instead of counting into the
  process dictionary, so the library knows nothing about statistics or traces.
  `ActorSimulation` now ships `ActorSimulation.Observer`, which is what counts
  for a real server in the loop; the numbers a simulation reports are unchanged
- the library's own query (`VirtualTimeGenServer.snapshot/1`) is never reported
  to the observer, so reading a server's statistics cannot change them

### Removed

- `VirtualTimeGenServer.enable_stats_tracking/0,2`, `get_process_stats/0`,
  `generate_incoming_trace_event/2`, `set_global_trace_collector/1,3` and
  `get_global_trace_collector/0`, together with the `:stats_enabled` start
  option and the `:__vtgs_*` process-dictionary keys they used. Use the
  instrumentation port instead

### Fixed

- the wrapper now supports `{:reply, reply, state, {:continue, arg}}` and passes
  any third element of `{:noreply, state, action}` through untouched
- the VLINGO XOOM generator's actors take their `Scheduler` as a constructor
  argument, so a test hands them a clock it owns: the generated tests advance a
  `ManualScheduler` and assert what the actor did, instead of sleeping 100ms and
  asserting `true`, and now hold their actor to a count: three intervals give
  three sends, a one-shot gives exactly one. Production passes no scheduler and
  gets the stage's, so the same actor waits on the wall clock unchanged
- the Go examples' tests assert the count their pattern makes (the burst the DSL
  asked for, one message for a one-shot, the range three intervals can produce
  for a repeating actor) instead of sleeping 10ms and checking that a struct is
  not nil; the generated READMEs show what the programs print, not assertions
- the generated `Main` runs the actors for a moment and stops, and the generated
  project runs it with `mvn compile exec:exec` (a forked JVM, because VLINGO
  compiles an actor's proxy at runtime, which the in-process `exec:java` cannot
  do); the generated README is a short page instead of boilerplate

### Fixed

- the generated CI ran a container action on macOS and Windows, and without
  `checks: write` on Linux, so every job failed at the test-report step; the
  action now runs on Linux only, with the permissions it needs
- `process()` of an actor without messages never called its callbacks, so
  nothing outside it could observe it; found by the generated test, which now
  asserts on what the actor did

## [0.6.1] - 2026-10-15

### Added

- `mix templates.upgrade`, a maintainer task that asks each upstream for its
  latest release and reports or rewrites the versions the code generators pin.
  `--check` fails when a pin is behind, `--examples` regenerates the checked-in
  example projects afterwards, `--offline` skips the network
- `ActorSimulation.TemplateVersions`, the single table of third-party versions a
  generated project pins, together with `sources/0`, which records where each
  version comes from and how much of it we take (`:latest_within_major` never
  moves a generated project across a breaking major on its own)
- `scripts/generate_ractor_examples.exs`, so all six generators have a
  regeneration script
- `benchmarks/virtual_time_speedup.exs`, which measures the real speed-up the
  README quotes, so the performance table is reproducible rather than inherited
- Tests for the clock lifecycle: a stopped or killed clock must not leave its
  scheduler process behind

### Changed

- Code generators no longer hardcode dependency versions in their templates.
  They read `ActorSimulation.TemplateVersions`, which is why the generated
  projects' pins are now reviewed in one place
- Generator dependency pins brought up to date: CAF 1.0.2 → 1.1.0, Catch2 3.7.1
  → 3.16.0, OMNeT++ 6.2.0 → 6.4.0, Ractor 0.15 → 0.16.5, tokio-test 0.4 → 0.4.6,
  JUnit 5.10.0 → 5.14.4, Maven plugins, Prism 1.29.0 → 1.30.0, and the GitHub
  Actions the generated CI workflows pin (`checkout` v3 → v7, `cache` v3 → v6,
  `setup-go` v4 → v7, `setup-java` v3 → v6, `setup-python` v4 → v7,
  `setup-rust-toolchain` v1 → v2). Generated CAF projects install Conan with
  `conan-io/setup-conan` instead of an unpinned `pip install conan`
- Generated projects now refer to this repository instead of a `yourusername`
  placeholder, and their README prerequisites follow the version table
- All dependencies and their requirement floors are current; the library itself
  still depends on nothing but `:logger` — the upgrade tooling lives in `dev/`
  and is not packaged
- Documentation corrected against the code: the README's speed-up table is now
  measured, `wrap_mermaid_html/1` (which never existed) is replaced with the
  real report API, the state machine documentation names
  `VirtualTimeGenStateMachine` rather than a dependency the library does not
  use, and the flowchart shape and colour tables match what the report generator
  emits. The README also says what is deterministic about a run: the clock, not
  the order in which tracing records messages that share one virtual instant
- `docs/index.md` is now published on HexDocs, and its links resolve there

### Fixed

- A `VirtualClock` leaked its scheduler process: the two were linked, and a
  process that is not trapping exits ignores an exit signal whose reason is
  `:normal`, so every stopped clock left a process behind. The scheduler now
  watches its clock. This made long benchmark runs fail with "Too many
  processes"
- The generated CAF main did not initialise the atom type ID block it declares
  (`CAF_MAIN(caf::id_block::ActorSimulation)`), which is undefined behaviour:
  the generated demo crashed with SIGSEGV as soon as it sent a message
- Generated CAF actors without a send pattern now handle the message atom their
  upstream actually sends, and call their declared `on_message` callback, so a
  generated pub/sub project delivers messages instead of dropping them
- Examples and templates regenerated from the upgraded generators;
  `test/output/` (stale generated reports that no test wrote) removed
- `GeneratorUtils.to_pascal_case/1` mangled an identifier that was already
  PascalCase (`"MyActor"` → `"Myactor"`), so a generated project could not be
  regenerated from its own output. It now uppercases the first character of each
  word and leaves the rest alone
- `GeneratorUtils.pattern_interval/1` raised on
  `{:self_message, delay, message}`, a pattern the DSL otherwise accepts, so a
  generator could not read the interval of a self-messaging actor
- `ActorSimulation.TemplateVersions.major/1` answered with the first
  dot-separated field of whatever the pin happened to be, so a release channel
  or a Go pseudo-version produced a nonsense major for the templates that
  interpolate it. A pin that is not a version now reports no major
- Tests that asserted nothing, asserted their own fixtures, compared a list
  against `[]`, or claimed virtual-time behaviour without attaching a clock now
  assert the behaviour their names describe
- The pure parts of the library — actor definitions, the statistics aggregation,
  the identifier conversions and the version table — are now specified by
  property tests, and `mix templates.upgrade` takes its fetcher, its table path
  and its script runner as arguments, so its report, its `--check` and its
  example regeneration are exercised without the network, without touching the
  real table and without rebuilding the checked-in projects
- CI: the sequence-diagram job ran `mix test` in the documentation workflow's
  `dev` environment, where the test-only dependencies are not loaded, so
  compiling the test files failed there; it now runs in the test environment, as
  the other test steps already did. One property test filtered a generator down
  to the handful of pins that are versions, which StreamData refuses on Elixir
  1.19; it now enumerates that subset and asserts it is not empty

## [0.6.0] - 2026-09-13

**Breaking changes:** the minimum Elixir is now 1.19 with OTP 28, and
`VirtualClock.cancel_timer/2` returns the remaining virtual time, or `false`,
where it previously returned `:ok`. Events scheduled for the same instant now
fire in the order they were scheduled rather than the reverse. A virtual time
that used to be silently truncated at the end of a long advance is no longer
truncated, so a simulation can now report more messages than before.

### Added

- Property-based test suites (`test/virtual_clock_property_test.exs`,
  `test/actor_simulation_property_test.exs`) covering time additivity, event
  ordering, cancellation and simulation message counts
- Mutation testing with [muex](https://hex.pm/packages/muex) in place of the
  broken `muzak`/`exavier` dependencies, which fail on current Elixir
- `doctest VirtualClock` so the moduledoc and `cancel_timer/2` examples are
  executed by the test suite

### Changed

- Minimum Elixir version is now 1.19, and minimum OTP 28, matching the versions
  CI verifies. (1.15 was the previous floor, needed by `ex_doc ~> 0.40`.)
- CI matrix reduced to Elixir 1.19/1.20 with OTP 28/29, and the other five
  workflows aligned, which still pinned Elixir 1.15/1.18 and OTP 25/27
- GitHub Actions updated to their current majors (`checkout` v7, `cache` v6,
  `upload-artifact` v7, `download-artifact` v8, `setup-java` v6, `setup-go` v7,
  the Pages actions, `action-junit-report` v6, `action-gh-release` v3 and
  `setup-rust-toolchain` v2), which also clears the Node 20 deprecation notices
- Updated all dependencies, including `ex_doc` 0.38 → 0.40, `credo` 1.7.13 →
  1.7.19, `dialyxir` 1.4.6 → 1.4.8, `castore` 1.0.15 → 1.0.21
- Consolidated four duplicated message-dispatch blocks in
  `ActorSimulation.Actor` into shared helpers, and nine duplicated
  acknowledgement clauses in the `VirtualTimeGenStateMachine` wrapper into
  shared delivery handling
- FOSSA no longer scans `generated/` or `examples/`: they are build output whose
  transitive dependencies (for example `io.vlingo.xoom:xoom-actors`, MPL-2.0)
  are not part of what is published
- README and documentation index restructured to lead with install and runnable
  examples
- Replaced `length(x) > 0` with `x != []` throughout, which is what Credo's
  expensive-empty-enum check asks for. Every expression was verified to hold a
  list, and the two where it may be `nil` use `not in [nil, []]` to keep the
  original short-circuit behaviour. Credo now reports no issues, down from 42

### Fixed

- Clock deliveries to `VirtualTimeGenServer` actors now carry a token and are
  acknowledged by that token alone. Actors previously acknowledged _every_
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
  (or `false`), matching the `TimeBackend` behaviour and
  `Process.cancel_timer/1`
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
  exist to show real time _is_ slow
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

### Demos and Documentation

- The century demo runs this repository's code instead of the published Hex
  package (`Mix.install` used to fetch `~> 0.5.0`), so a fix made here can show
  up in it, and its workflow can catch a regression here. Its header no longer
  claims "milliseconds" where runs measure seconds
- The century demo reports its goal honestly: it states how many of the 36,525
  midnights triggered a backup and how many were skipped because the previous
  backup was still running, and checks that the two add up - which they do. The
  earlier `(expected: 36525)` line implied the simulation was losing work; the
  gap was the demo's own "ignore a trigger while already backing up" rule
- README states the primary goal up front - the RxJS TestScheduler idea applied
  to the BEAM - alongside the simulation DSL and the generators, rather than
  leaving it at the bottom under "Inspiration"

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
  https://github.com/d-led/gen_server_virtual_time/compare/v1.1.1...HEAD
[1.1.1]:
  https://github.com/d-led/gen_server_virtual_time/compare/v1.1.0...v1.1.1
[1.1.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v1.0.1...v1.1.0
[1.0.1]:
  https://github.com/d-led/gen_server_virtual_time/compare/v1.0.0...v1.0.1
[1.0.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.7.1...v1.0.0
[0.7.1]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.7.0...v0.7.1
[0.7.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.6.1...v0.7.0
[0.6.1]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.6.0...v0.6.1
[0.6.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.5.0...v0.6.0
[0.5.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.4.0...v0.5.0
[0.4.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.2.4...v0.4.0
[0.3.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.2.3...v0.3.0
[0.2.4]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.2.3...v0.2.4
[0.2.3]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.2.2...v0.2.3
[0.2.0]:
  https://github.com/d-led/gen_server_virtual_time/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/d-led/gen_server_virtual_time/releases/tag/v0.1.0
