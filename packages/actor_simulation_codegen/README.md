# ActorSimulationCodegen

Turn an `actor_simulation` model into a runnable project in another language:
C++ (CAF or OMNeT++), Go (Phony), Pony, Rust (Ractor) or Java (VLINGO XOOM).
Each generated project comes with build files, a CI workflow, a test suite and,
for every target but OMNeT++, callback interfaces, so behaviour can be
customised without editing generated code.

Prototype in Elixir where a simulated hour takes a millisecond, then take the
same model to production.

[![Hex.pm](https://img.shields.io/hexpm/v/actor_simulation_codegen.svg)](https://hex.pm/packages/actor_simulation_codegen)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/actor_simulation_codegen)

## The family

| Package                                                                                 | What it is for                                       | Add it when                                       |
| --------------------------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------- |
| [`gen_server_virtual_time`](https://hexdocs.pm/gen_server_virtual_time)                 | virtual clock, `GenServer`/`gen_statem` wrappers     | you test code with timers                         |
| [`gen_server_virtual_time_migrate`](https://hexdocs.pm/gen_server_virtual_time_migrate) | `mix virtual_time.migrate` rewrites `GenServer` code | you already have servers and want to keep them    |
| [`actor_simulation`](https://hexdocs.pm/actor_simulation)                               | actor-system DSL, statistics, sequence diagrams      | you model parts of a system talking to each other |
| **`actor_simulation_codegen`** (this one)                                               | generate runnable projects in six runtimes           | you want the same model in another language       |

This package depends on `actor_simulation`, which brings
`gen_server_virtual_time` with it.

## Install

```elixir
def deps do
  [{:actor_simulation_codegen, "~> 1.0.1"}]
end
```

## Targets

| Generator   | Language | Framework                                               | Output                                       |
| ----------- | -------- | ------------------------------------------------------- | -------------------------------------------- |
| **CAF**     | C++      | [C++ Actor Framework](https://www.actor-framework.org/) | Typed actors, CMake build, Conan deps, tests |
| **Phony**   | Go       | [Phony](https://github.com/Arceliar/phony)              | Zero-alloc actors, Go modules, tests         |
| **Pony**    | Pony     | [Pony Language](https://www.ponylang.io/)               | Type-safe actors, Corral deps, PonyTest      |
| **Ractor**  | Rust     | [Ractor](https://github.com/slawlor/ractor)             | Gen_server-inspired, Cargo, async/await      |
| **VLINGO**  | Java     | [VLINGO XOOM](https://docs.vlingo.io/)                  | Protocol actors, Maven, JUnit 5              |
| **OMNeT++** | C++      | [OMNeT++](https://omnetpp.org/)                         | Discrete-event simulation, NED files, CMake  |

Each is generated from the same simulation:

```elixir
simulation = ActorSimulation.new()
|> ActorSimulation.add_actor(:publisher,
    send_pattern: {:periodic, 100, :event},
    targets: [:sub1, :sub2, :sub3])
|> ActorSimulation.add_actor(:sub1)
|> ActorSimulation.add_actor(:sub2)
|> ActorSimulation.add_actor(:sub3)

# C++ with the C++ Actor Framework
{:ok, files} = ActorSimulation.CAFGenerator.generate(simulation,
  project_name: "PubSubActors",
  enable_callbacks: true)
ActorSimulation.CAFGenerator.write_to_directory(files, "caf_output/")

# Go with Phony
{:ok, files} = ActorSimulation.PhonyGenerator.generate(simulation,
  project_name: "pubsub",
  enable_callbacks: true)
ActorSimulation.PhonyGenerator.write_to_directory(files, "phony_output/")

# Rust with Ractor
{:ok, files} = ActorSimulation.RactorGenerator.generate(simulation,
  project_name: "pubsub",
  enable_callbacks: true)
ActorSimulation.RactorGenerator.write_to_directory(files, "ractor_output/")
```

Then build the output with its own toolchain — each generated project ships a
`README.md` with the exact commands:

| Target  | Build                                     |
| ------- | ----------------------------------------- |
| CAF     | `cmake` + `conan`                         |
| OMNeT++ | `cmake` (NED files and a runnable config) |
| Pony    | `make` (Corral for dependencies)          |
| Phony   | `go test ./...`                           |
| Ractor  | `cargo test`                              |
| VLINGO  | `mvn compile exec:exec` (forked JVM)      |

Callback interfaces let you change behaviour without touching generated files:

```cpp
// CAF: publisher_callbacks_impl.cpp
void publisher_callbacks::on_event() {
  log_to_database();
  send_metrics();
}
```

```rust
// Ractor: publisher.rs
impl PublisherCallbacks for MyPublisherCallbacks {
    fn on_event(&self) {
        println!("Publishing event with custom handler");
    }
}
```

## Guides

- [Code generators overview](docs/generators.md) — what every target emits and
  how the shared pieces fit
- [OMNeT++](docs/omnetpp_generator.md) · [CAF](docs/caf_generator.md) ·
  [Pony](docs/pony_generator.md) · [Phony](docs/phony_generator.md) ·
  [Ractor](docs/ractor_generator.md) · [VLINGO XOOM](docs/vlingo_generator.md)
- [API reference](https://hexdocs.pm/actor_simulation_codegen)
- [Changelog](https://github.com/d-led/gen_server_virtual_time/blob/main/CHANGELOG.md)

## License

MIT License - See the [LICENSE](LICENSE) file for details.
