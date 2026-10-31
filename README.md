# gen_server_virtual_time

Test time-based GenServers instantly — no waiting, no flaky timing. This
repository publishes the clock and the code that builds on it as four packages
that share one version, so you add what you use.

| Package                                                                       | What it is for                                                                  | Hex                                                               | Docs                                                          |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------- |
| [`gen_server_virtual_time`](packages/gen_server_virtual_time)                 | virtual clock, `GenServer`/`gen_statem` wrappers, time backends                 | [hex.pm](https://hex.pm/packages/gen_server_virtual_time)         | [hexdocs](https://hexdocs.pm/gen_server_virtual_time)         |
| [`actor_simulation`](packages/actor_simulation)                               | actor-system DSL, statistics, sequence diagrams, flowchart reports              | [hex.pm](https://hex.pm/packages/actor_simulation)                | [hexdocs](https://hexdocs.pm/actor_simulation)                |
| [`actor_simulation_codegen`](packages/actor_simulation_codegen)               | generate runnable C++, Go, Pony, Rust, Java, OMNeT++ projects from a simulation | [hex.pm](https://hex.pm/packages/actor_simulation_codegen)        | [hexdocs](https://hexdocs.pm/actor_simulation_codegen)        |
| [`gen_server_virtual_time_migrate`](packages/gen_server_virtual_time_migrate) | rewrite existing `GenServer` code for the virtual clock, report first           | [hex.pm](https://hex.pm/packages/gen_server_virtual_time_migrate) | [hexdocs](https://hexdocs.pm/gen_server_virtual_time_migrate) |

The idea is the [RxJS TestScheduler](https://rxjs.dev/api/testing/TestScheduler)
applied to the BEAM: the clock is yours to advance, so a test describes the
timeline it wants instead of sleeping through it.

```elixir
{:ok, clock} = VirtualClock.start_link()
{:ok, server} = VirtualTimeGenServer.start_link(MyServer, :ok, virtual_clock: clock)

VirtualClock.advance(clock, 100_000)   # 100 virtual seconds, ~10ms real
```

## Working in this repository

Each package is a Mix project of its own; the root project is only a workspace
that lets the scripts, benchmarks and maintainer tooling run against all four.

```bash
./scripts/test.sh                                  # every package, then the tooling tests
./scripts/test.sh --only slow                      # the same selection everywhere
TEST_PACKAGES=actor_simulation ./scripts/test.sh   # one package

cd packages/actor_simulation && mix test           # work on one package
mix run benchmarks/virtual_time_speedup.exs        # benchmarks run from the root
mix precommit                                      # every CI check; --all adds dialyzer
```

| What               | Where                                                                          |
| ------------------ | ------------------------------------------------------------------------------ |
| Design plan        | [docs/package_split_plan.md](docs/package_split_plan.md)                       |
| Upgrade notes      | `mix virtual_time.doctor` (shipped in `gen_server_virtual_time`)               |
| Rewriting code     | `mix virtual_time.migrate` (shipped in `gen_server_virtual_time_migrate`)      |
| Release process    | `elixir scripts/release.exs bump <kind>`, then tag; the tag publishes all four |
| Generated examples | `examples/` (sources) and `generated/` (checked-in output)                     |

The version lives in [`VERSION`](VERSION); `elixir scripts/release.exs check`
fails when the packages disagree, and `.github/workflows/publish.yml` refuses to
publish a tag whose version they do not share.

## License

MIT License — see [LICENSE](LICENSE).
