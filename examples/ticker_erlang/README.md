# A ticker in Erlang, on virtual time

A `VirtualTimeGenServer` written in Erlang: it ticks once per simulated second,
and the test asserts a whole minute of ticking without waiting for it.

```console
$ rebar3 eunit
Finished in 0.066 seconds
1 tests, 0 failures
```

The whole example is [`src/ticker.erl`](src/ticker.erl) (30 lines) and
[`test/ticker_tests.erl`](test/ticker_tests.erl) (23 lines).

## How it works

`rebar.config` uses the [`rebar_mix`](https://hex.pm/packages/rebar_mix) plugin,
so rebar3 can drive the Elixir dependency:

```erlang
{plugins, [rebar_mix]}.
{deps, [{gen_server_virtual_time, "1.0.1"}]}.
```

The ticker is started on a clock and arms one tick at a time:

```erlang
start_link(Clock, IntervalMs, Ticks) ->
    InitArg = {self(), IntervalMs, Ticks},
    'Elixir.VirtualTimeGenServer':start_link(?MODULE, InitArg, [{virtual_clock, Clock}]).
```

`'Elixir.VirtualTimeGenServer':send_after(self(), tick, IntervalMs)` is what
puts the process on the clock: with virtual time it schedules an event, with
real time it schedules a timer. The callbacks are ordinary `gen_server`
callbacks — Elixir's `GenServer` and OTP's use the same shapes, so no adapter is
needed.

The test is the value:

```erlang
{ok, Clock} = 'Elixir.VirtualClock':start_link(),
{ok, Ticker} = ticker:start_link(Clock, 1000, 60),
'Elixir.VirtualClock':advance(Clock, 60000),
?assertNot(is_process_alive(Ticker)),
?assertEqual(60, count_ticks(0)),
?assertEqual(60000, 'Elixir.VirtualClock':now(Clock)),
```

Sixty ticks that would take a real minute happen in microseconds, and the clock
reports exactly the time the test asked for.

## Run it

```console
rebar3 eunit
```

Requires Erlang/OTP and a rebar3 whose bundled Hex build matches it. If you see
`please re-compile this module with an Erlang/OTP 29 compiler`, your rebar3 is
older than your runtime: `brew install rebar3` (or check its release for your
OTP).

## What to read next

- [`../ticker_gleam`](../ticker_gleam) — the same idea from Gleam
- [the Erlang/Elixir split of the clock](https://hexdocs.pm/gen_server_virtual_time)
