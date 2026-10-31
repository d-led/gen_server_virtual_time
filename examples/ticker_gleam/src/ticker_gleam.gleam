//// Drive the virtual clock from Gleam.
////
//// Gleam has no atom literals and no `use GenServer`, so the Elixir clock is
//// reached through externals — but what it gives you is the same as in Elixir:
//// a minute of ticking that costs no real time.

import gleam/erlang/process
import gleam/int

pub type Clock =
  process.Pid

@external(erlang, "Elixir.VirtualClock", "start_link")
pub fn start_clock() -> Result(Clock, Nil)

/// Arms `count` ticks on the clock, one per `interval_ms` of virtual time, each
/// delivered as its own number to the calling process.
pub fn arm_ticks(clock: Clock, count: Int, interval_ms: Int) -> Nil {
  int.range(from: 1, to: count + 1, with: Nil, run: fn(_, n) {
    send_after(clock, process.self(), n, n * interval_ms)
  })
}

@external(erlang, "Elixir.VirtualClock", "send_after")
fn send_after(clock: Clock, destination: process.Pid, message: Int, delay_ms: Int) -> Nil

/// Moves the clock forward, delivering everything due on the way.
@external(erlang, "Elixir.VirtualClock", "advance")
pub fn advance(clock: Clock, amount_ms: Int) -> Nil

/// The clock's current virtual time, in milliseconds.
@external(erlang, "Elixir.VirtualClock", "now")
pub fn now(clock: Clock) -> Int
