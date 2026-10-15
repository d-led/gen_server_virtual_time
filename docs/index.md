# Documentation Index

New here? The
[main README](https://github.com/d-led/gen_server_virtual_time#readme) has install
plus a runnable example.

## 🚀 Start here

1. Want a working generated project in ~5 minutes? Run a
   [single-file script](#-examples) — no install needed.
2. Want to understand the timing model? Read the
   [virtual clock design](virtual_clock_design.md).
3. Want to contribute? Read the
   [contributing guide](https://github.com/d-led/gen_server_virtual_time/blob/main/CONTRIBUTING.md).

## 🧭 Find the page you need

| Topic                   | Read                                                         |
| ----------------------- | ------------------------------------------------------------ |
| Virtual clock internals | [Virtual clock design](virtual_clock_design.md)               |
| Isolated test clocks    | [Local clock injection](local_clock_injection_feature.md)     |
| Diagrams and reports    | [Flowchart reports](flowchart_reports.md)                     |
| The version table       | [TemplateVersions](ActorSimulation.TemplateVersions.html)     |

## 🚀 Code generators

Turn the ActorSimulation DSL into a runnable project. Start with the
[generators overview](generators.md):

| Generator                        | Language | Produces                                   |
| -------------------------------- | -------- | ------------------------------------------ |
| [OMNeT++](omnetpp_generator.md)  | C++      | Discrete-event network simulation          |
| [CAF](caf_generator.md)          | C++      | Actors with callback interfaces            |
| [Pony](pony_generator.md)        | Pony     | Capabilities-secure actors                 |
| [Phony](phony_generator.md)      | Go       | Zero-allocation actors                     |
| [Ractor](ractor_generator.md)    | Rust     | gen_server-inspired actors                 |
| [VLINGO XOOM](vlingo_generator.md) | Java   | Type-safe actors                           |

## 💻 Examples

Single-file scripts generate a complete project with `Mix.install` — no setup:

```bash
elixir examples/single_file_omnetpp.exs   # C++ / OMNeT++
elixir examples/single_file_caf.exs       # C++ / CAF
elixir examples/single_file_pony.exs      # Pony
elixir examples/single_file_phony.exs     # Go / Phony
elixir examples/single_file_ractor.exs    # Rust / Ractor
elixir examples/single_file_vlingo.exs    # Java / VLINGO XOOM
```

Pre-generated, buildable projects live in
[`examples/`](https://github.com/d-led/gen_server_virtual_time/tree/main/examples) — five for
OMNeT++ and four each for CAF, Pony, Phony and Ractor. VLINGO XOOM and OMNeT++
samples also live in
[`generated/`](https://github.com/d-led/gen_server_virtual_time/tree/main/generated).

## 🛠️ Working on the project

These live in the repository, not in the published docs:

- [Contributing guide](https://github.com/d-led/gen_server_virtual_time/blob/main/CONTRIBUTING.md)
- [Development docs](https://github.com/d-led/gen_server_virtual_time/blob/main/docs/development/README.md)
- [Versioning and release](https://github.com/d-led/gen_server_virtual_time/blob/main/docs/development/VERSIONING.md)
- [Publishing](https://github.com/d-led/gen_server_virtual_time/blob/main/docs/development/PUBLISHING.md)
- [Automation scripts](https://github.com/d-led/gen_server_virtual_time/blob/main/scripts/README.md)
- [Benchmarks](https://github.com/d-led/gen_server_virtual_time/blob/main/benchmarks/README.md)

Maintainer tooling lives in [`dev/`](https://github.com/d-led/gen_server_virtual_time/tree/main/dev)
and is not part of the published package: it includes `mix templates.upgrade`,
which keeps the versions the code generators pin up to date.

Historical records live in
[`docs/agent/`](https://github.com/d-led/gen_server_virtual_time/tree/main/docs/agent).

## 🔗 Links

- [Hex package](https://hex.pm/packages/gen_server_virtual_time)
- [Source on GitHub](https://github.com/d-led/gen_server_virtual_time)
- [API reference](https://hexdocs.pm/gen_server_virtual_time)
- [Changelog](CHANGELOG.html)
