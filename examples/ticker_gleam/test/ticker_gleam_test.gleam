import gleam/erlang/process
import gleeunit
import gleeunit/should
import ticker_gleam

pub fn main() {
  gleeunit.main()
}

/// The whole point: a minute of ticks, asserted in no real time.
pub fn a_virtual_minute_of_ticks_takes_no_real_time_test() {
  let assert Ok(clock) = ticker_gleam.start_clock()

  ticker_gleam.arm_ticks(clock, 60, 1000)
  ticker_gleam.advance(clock, 60_000)

  count_ticks(process.new_selector() |> process.select_other(fn(_) { Nil }), 0)
  |> should.equal(60)

  ticker_gleam.now(clock)
  |> should.equal(60_000)
}

/// Every tick was delivered before `advance` returned, so counting with a zero
/// timeout cannot miss one.
fn count_ticks(selector: process.Selector(Nil), seen: Int) -> Int {
  case process.selector_receive(selector, 0) {
    Ok(_) -> count_ticks(selector, seen + 1)
    Error(_) -> seen
  }
}
