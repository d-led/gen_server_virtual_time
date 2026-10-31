# A ticker in Gleam, on virtual time

Sixty ticks, one per simulated second, asserted without waiting a minute.

```console
$ ./run.sh
1 passed, no failures
```

The whole example is [`src/ticker_gleam.gleam`](src/ticker_gleam.gleam) (31
lines) and [`test/ticker_gleam_test.gleam`](test/ticker_gleam_test.gleam) (30
lines).

## How it works

Gleam has no atom literals and no `use GenServer`, so the Elixir clock is
reached through externals:

```gleam
@external(erlang, "Elixir.VirtualClock", "start_link")
pub fn start_clock() -> Result(Clock, Nil)

@external(erlang, "Elixir.VirtualClock", "advance")
pub fn advance(clock: Clock, amount_ms: Int) -> Nil
```

`arm_ticks` schedules one tick per virtual second, and `advance` moves a whole
minute in one call:

```gleam
let assert Ok(clock) = ticker_gleam.start_clock()
ticker_gleam.arm_ticks(clock, 60, 1000)
ticker_gleam.advance(clock, 60_000)
```

Each tick arrives as a plain message, so counting them needs
`process.select_other` — the catch-all selector meant for messages from other
BEAM languages.

## Why the ticks are armed up front

In Elixir or Erlang the ticker re-arms from `handle_info`, and the clock waits
for the process to finish before moving on. That wait is what makes the ordering
deterministic, and it is acknowledged by the `VirtualTimeGenServer` wrapper — a
callback contract Gleam cannot express without atom literals. So this example
schedules its minute in one pass, which needs no acknowledgement and is equally
exact: everything due up to the target time is delivered before `advance/2`
returns.

For a self-rescheduling ticker in Erlang, see
[`../ticker_erlang`](../ticker_erlang).

## Run it

```console
./run.sh
```

Gleam can only depend on Gleam packages, so the script has the rebar3 example
next door fetch and compile `gen_server_virtual_time`, then puts it (and
Elixir's own applications) on this project's Erlang code path with `ERL_LIBS`.
Running `gleam test` directly works too, as long as `ERL_LIBS` points at those
two directories.
