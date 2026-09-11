# Documentation Index

New here? Read the [main README](../README.md) first — it has install plus a
runnable example.

## 🚀 Start here

1. Want a working generated project in ~5 minutes? Run a
   [single-file script](#-examples) — no install needed.
2. Want to understand the timing model? Read the
   [virtual clock design](virtual_clock_design.md).
3. Want to contribute? Read the [development docs](development/README.md).

## 🧭 Find the page you need

| Topic                    | Read                                                       |
| ------------------------ | ---------------------------------------------------------- |
| Virtual clock internals  | [Virtual clock design](virtual_clock_design.md)             |
| Isolated test clocks     | [Local clock injection](local_clock_injection_feature.md)   |
| Implementation deep dive | [Implementation summary](implementation_summary.md)         |
| Diagrams and reports     | [Flowchart reports](flowchart_reports.md)                   |
| Development setup        | [Development docs](development/README.md)                   |

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

Pre-generated, buildable projects live in [`examples/`](../examples/) — four
each for OMNeT++, CAF, Pony and Phony, plus Ractor and VLINGO XOOM.

## 🛠️ Working on the project

- [Contributing guide](../CONTRIBUTING.md)
- [Development docs](development/README.md)
- [Versioning and release](development/VERSIONING.md)
- [Publishing](development/PUBLISHING.md)
- [Automation scripts](../scripts/README.md)

Historical records live in [`docs/agent/`](agent/README.md).

## 🔗 Links

- [Hex package](https://hex.pm/packages/gen_server_virtual_time)
- [Source on GitHub](https://github.com/d-led/gen_server_virtual_time)
- [API reference](https://hexdocs.pm/gen_server_virtual_time)
- [Changelog](../CHANGELOG.md)
