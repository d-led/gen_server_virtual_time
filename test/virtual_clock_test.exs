defmodule VirtualClockTest do
  use ExUnit.Case, async: true

  describe "VirtualClock" do
    test "starts with time at 0" do
      {:ok, clock} = VirtualClock.start_link()
      assert VirtualClock.now(clock) == 0
    end

    test "advances time" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualClock.advance(clock, 1000)
      assert VirtualClock.now(clock) == 1000

      VirtualClock.advance(clock, 500)
      assert VirtualClock.now(clock) == 1500
    end

    test "schedules and triggers events" do
      {:ok, clock} = VirtualClock.start_link()

      VirtualClock.send_after(clock, self(), :hello, 1000)

      # Message not received yet
      refute_receive :hello, 10

      # Advance time and message is received
      VirtualClock.advance(clock, 1000)
      assert_receive :hello, 10
    end

    test "triggers multiple events in order" do
      {:ok, clock} = VirtualClock.start_link()

      VirtualClock.send_after(clock, self(), :first, 100)
      VirtualClock.send_after(clock, self(), :second, 200)
      VirtualClock.send_after(clock, self(), :third, 300)

      VirtualClock.advance(clock, 250)

      assert_receive :first
      assert_receive :second
      refute_receive :third, 10

      VirtualClock.advance(clock, 100)
      assert_receive :third
    end

    test "cancels scheduled events" do
      {:ok, clock} = VirtualClock.start_link()

      ref = VirtualClock.send_after(clock, self(), :cancelled, 1000)
      assert VirtualClock.cancel_timer(clock, ref) == :ok

      VirtualClock.advance(clock, 1000)
      refute_receive :cancelled, 10
    end

    test "advance_to_next jumps to next event" do
      {:ok, clock} = VirtualClock.start_link()

      VirtualClock.send_after(clock, self(), :msg1, 500)
      VirtualClock.send_after(clock, self(), :msg2, 1000)

      amount = VirtualClock.advance_to_next(clock)
      assert amount == 500
      assert VirtualClock.now(clock) == 500
      assert_receive :msg1

      amount = VirtualClock.advance_to_next(clock)
      assert amount == 500
      assert VirtualClock.now(clock) == 1000
      assert_receive :msg2
    end

    test "scheduled_count tracks pending events" do
      {:ok, clock} = VirtualClock.start_link()

      assert VirtualClock.scheduled_count(clock) == 0

      VirtualClock.send_after(clock, self(), :msg1, 100)
      VirtualClock.send_after(clock, self(), :msg2, 200)
      assert VirtualClock.scheduled_count(clock) == 2

      VirtualClock.advance(clock, 150)
      assert VirtualClock.scheduled_count(clock) == 1

      VirtualClock.advance(clock, 100)
      assert VirtualClock.scheduled_count(clock) == 0
    end
  end
end
