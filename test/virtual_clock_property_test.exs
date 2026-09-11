defmodule VirtualClockPropertyTest do
  @moduledoc """
  Property-based specification of `VirtualClock`.

  Virtual time is only useful if it behaves like wall-clock time, just faster.
  These properties pin the invariants that make that true:

    * advancing is additive - splitting one advance into several parts lands on
      the same virtual time and delivers the same messages
    * a scheduled event fires exactly once, and only once virtual time reaches
      its due time
    * events are delivered in due-time order, and events due at the same instant
      are delivered in the order they were scheduled (like real timers)
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  defp start_clock do
    {:ok, clock} = VirtualClock.start_link()
    clock
  end

  # Schedules `{:event, index, delay}` at `delays[index]`, so a delivered message
  # identifies both its scheduling position and its due time.
  defp schedule_all(clock, delays) do
    delays
    |> Enum.with_index()
    |> Enum.each(fn {delay, index} ->
      VirtualClock.send_after(clock, self(), {:event, index, delay}, delay)
    end)
  end

  defp expected_events(delays) do
    delays
    |> Enum.with_index()
    |> Enum.map(fn {delay, index} -> {:event, index, delay} end)
  end

  defp due_time({:event, _index, delay}), do: delay

  # Collects everything that has been delivered, in delivery order.
  defp delivered_so_far(acc \\ []) do
    receive do
      message -> delivered_so_far([message | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp advance_in_chunks(_clock, remaining, _chunk) when remaining <= 0, do: :ok

  defp advance_in_chunks(clock, remaining, chunk) do
    step = min(chunk, remaining)
    VirtualClock.advance(clock, step)
    advance_in_chunks(clock, remaining - step, chunk)
  end

  defp non_decreasing?([]), do: true
  defp non_decreasing?([_single]), do: true

  defp non_decreasing?([first, second | rest]),
    do: first <= second and non_decreasing?([second | rest])

  test "an idle clock reports no progress" do
    clock = start_clock()

    assert VirtualClock.advance_to_next(clock) == 0
    assert VirtualClock.now(clock) == 0
    assert delivered_so_far() == []
  end

  property "advancing is additive: the parts sum to the whole" do
    check all(deltas <- list_of(integer(1..500), min_length: 1, max_length: 15)) do
      total = Enum.sum(deltas)

      one_shot = start_clock()
      assert {:ok, ^total} = VirtualClock.advance(one_shot, total)

      in_chunks = start_clock()
      Enum.each(deltas, fn delta -> VirtualClock.advance(in_chunks, delta) end)

      assert VirtualClock.now(in_chunks) == VirtualClock.now(one_shot)
    end
  end

  property "an event fires once and only once time reaches its due time" do
    check all(delay <- integer(1..1_000), horizon <- integer(0..1_000)) do
      clock = start_clock()
      VirtualClock.send_after(clock, self(), :due, delay)

      VirtualClock.advance(clock, horizon)

      assert VirtualClock.now(clock) == horizon

      expected = if horizon >= delay, do: [:due], else: []
      assert delivered_so_far() == expected
    end
  end

  property "every scheduled event is delivered exactly once" do
    check all(delays <- list_of(integer(1..200), min_length: 1, max_length: 20)) do
      clock = start_clock()
      schedule_all(clock, delays)

      VirtualClock.advance(clock, 500)

      assert Enum.sort(delivered_so_far()) == Enum.sort(expected_events(delays))
    end
  end

  property "events are delivered in due-time order" do
    check all(
            delays <- list_of(integer(0..500), min_length: 1, max_length: 25),
            horizon <- integer(0..500)
          ) do
      clock = start_clock()
      schedule_all(clock, delays)

      VirtualClock.advance(clock, horizon)

      due_times = delivered_so_far() |> Enum.map(&due_time/1)

      assert non_decreasing?(due_times)
      assert length(due_times) == Enum.count(delays, &(&1 <= horizon))
    end
  end

  property "events due at the same instant are delivered in scheduling order" do
    check all(count <- integer(2..20), instant <- integer(1..500)) do
      clock = start_clock()
      for index <- 1..count, do: VirtualClock.send_after(clock, self(), index, instant)

      VirtualClock.advance(clock, instant)

      assert delivered_so_far() == Enum.to_list(1..count)
    end
  end

  property "splitting an advance delivers the same messages as one big advance" do
    check all(
            delays <- list_of(integer(1..300), min_length: 1, max_length: 15),
            chunk <- integer(1..50)
          ) do
      horizon = Enum.max(delays)

      one_shot = start_clock()
      schedule_all(one_shot, delays)
      VirtualClock.advance(one_shot, horizon)
      one_shot_delivery = delivered_so_far()

      in_chunks = start_clock()
      schedule_all(in_chunks, delays)
      advance_in_chunks(in_chunks, horizon, chunk)
      chunked_delivery = delivered_so_far()

      assert VirtualClock.now(in_chunks) == VirtualClock.now(one_shot)
      assert chunked_delivery == one_shot_delivery
    end
  end

  property "a cancelled timer reports its remaining time and never fires" do
    check all(
            delay <- integer(1..1_000),
            elapsed <- integer(0..(delay - 1))
          ) do
      clock = start_clock()
      ref = VirtualClock.send_after(clock, self(), :cancelled, delay)

      VirtualClock.advance(clock, elapsed)

      assert VirtualClock.cancel_timer(clock, ref) == delay - elapsed
      assert VirtualClock.cancel_timer(clock, ref) == false

      VirtualClock.advance(clock, delay)
      assert delivered_so_far() == []
    end
  end

  property "advance_to_next stops exactly at the earliest pending event" do
    check all(delays <- list_of(integer(1..500), min_length: 1, max_length: 15)) do
      clock = start_clock()
      schedule_all(clock, delays)

      earliest = Enum.min(delays)

      assert VirtualClock.advance_to_next(clock) == earliest
      assert VirtualClock.now(clock) == earliest
    end
  end

  property "the scheduled counts agree with what advancing actually delivers" do
    check all(
            delays <- list_of(integer(1..500), min_length: 1, max_length: 15),
            horizon <- integer(0..500)
          ) do
      clock = start_clock()
      Enum.each(delays, fn delay -> VirtualClock.send_after(clock, self(), :ping, delay) end)

      due_within_horizon = VirtualClock.scheduled_count_until(clock, horizon)

      VirtualClock.advance(clock, horizon)

      assert length(delivered_so_far()) == due_within_horizon
      assert VirtualClock.scheduled_count(clock) == length(delays) - due_within_horizon
    end
  end
end
