# GenServerVirtualTimeMigrate

Two dev-only rewrite tasks: move existing `GenServer` code onto the virtual
clock, and move a project off the module names that were renamed in 1.1.

Both read your tree, show exactly what they would change, and write only when
you ask.

```console
$ mix virtual_time.migrate
lib/my_app/counter.ex
  line 2: use GenServer

1 file(s) would change. Re-run with --write to apply.
```

[![Hex.pm](https://img.shields.io/hexpm/v/gen_server_virtual_time_migrate.svg)](https://hex.pm/packages/gen_server_virtual_time_migrate)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/gen_server_virtual_time_migrate)

## The family

| Package                                                                   | What it is for                                                | Add it when                                         |
| ------------------------------------------------------------------------- | ------------------------------------------------------------- | --------------------------------------------------- |
| [`gen_server_virtual_time`](https://hexdocs.pm/gen_server_virtual_time)   | virtual clock, `GenServer`/`gen_statem` wrappers              | you test code with timers                           |
| **`gen_server_virtual_time_migrate`** (this one)                          | rewrite code for the virtual clock, rename deprecated modules | you already have servers, or code that predates 1.1 |
| [`actor_simulation`](https://hexdocs.pm/actor_simulation)                 | actor-system DSL, statistics, sequence diagrams               | you model parts of a system talking to each other   |
| [`actor_simulation_codegen`](https://hexdocs.pm/actor_simulation_codegen) | generate runnable projects in six runtimes                    | you want the same model in another language         |

This package is standalone: it only rewrites text, so it needs nothing at
runtime. The rewritten code needs `gen_server_virtual_time`.

## Install

```elixir
def deps do
  [
    {:gen_server_virtual_time, "~> 1.1.0"},
    {:gen_server_virtual_time_migrate, "~> 1.0.0", only: :dev}
  ]
end
```

## Use

```console
mix virtual_time.migrate                                  # report only
mix virtual_time.migrate --write                          # apply
mix virtual_time.migrate --check                          # exit 1 if anything would change
mix virtual_time.migrate --paths lib --paths test         # defaults to lib and test
```

A rewrite that would not parse aborts the run before anything is written, so a
`--write` either produces a compiling tree or leaves it alone.

## What it rewrites

| Before                                   | After                                                 |
| ---------------------------------------- | ----------------------------------------------------- |
| `use GenServer`                          | `use VirtualTimeGenServer`                            |
| `use GenStateMachine`                    | `use VirtualTimeGenStateMachine`                      |
| `Process.send_after(pid, :tick, 1_000)`  | `VirtualTimeGenServer.send_after(pid, :tick, 1_000)`  |
| `Process.sleep(10)`                      | `VirtualTimeGenServer.sleep(10)`                      |
| `:timer.sleep(10)`                       | `VirtualTimeGenServer.sleep(10)`                      |
| `GenServer.call(MyApp.Counter, :get)`    | `VirtualTimeGenServer.call(MyApp.Counter, :get)`      |

The time calls are only rewritten inside a module that is itself converted —
that is what puts the module on the virtual clock.

## What it leaves for you

The tool never guesses, and it says what it skipped:

- `GenServer.call/2` on a pid, a variable, or a module that stays a plain
  `GenServer` — the call may still be right, the tool just cannot prove it;
- `:erlang.send_after/3`, whose delay is its _first_ argument while
  `VirtualTimeGenServer.send_after/3` wants it last — swapping arguments is not
  a token replacement, so the line is reported with the fix spelled out;
- anything outside a converted module;
- `:gen_statem` timeouts, which the virtual-time state machine handles through
  its own options — see `VirtualTimeGenStateMachine`.

Comments, strings and formatting elsewhere in the file are untouched: the
rewrite is a token replacement, so `git diff` shows only the lines that changed.

## The other task: deprecated generator names

`ActorSimulation.CAFGenerator` and its five siblings became
`ActorSimulation.Codegen.*` in 1.1. The old names still work — they forward, and
warn — so this is optional: it is the difference between a build with
deprecation warnings and one without.

```console
mix virtual_time.upgrade                # report only
mix virtual_time.upgrade --write        # apply
mix virtual_time.upgrade --check        # exit 1 if anything would change
```

| Before                                           | After                                       |
| ------------------------------------------------ | ------------------------------------------- |
| `ActorSimulation.CAFGenerator.generate(sim)`     | `ActorSimulation.Codegen.CAF.generate(sim)` |
| `alias ActorSimulation.PonyGenerator`            | `alias ActorSimulation.Codegen.Pony`        |
| `PonyGenerator.generate(sim)` (under that alias) | `Pony.generate(sim)`                        |

It reports instead of guessing when an alias uses `as:`, when the name it would
introduce is already in use in that file, and when a bare short name has no
alias it can point at.

## Compatibility

Input is parsed with the standard library (`Code.string_to_quoted/2`), so the
migrator needs the same Elixir as the project it runs in. The virtual-time
packages themselves keep working on Elixir 1.19 and OTP 28 as well.
