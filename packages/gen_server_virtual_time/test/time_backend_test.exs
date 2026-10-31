defmodule TimeBackendTest do
  use ExUnit.Case, async: true

  import WaitUntil

  describe "RealTimeBackend" do
    test "sends messages after specified delay" do
      ref = RealTimeBackend.send_after(self(), :hello, 50)
      assert is_reference(ref)

      # Generous bound: the behaviour under test is that the message arrives,
      # not that a loaded machine delivers it within 100ms.
      assert_receive :hello, 1_000
    end

    test "cancels timers before they fire" do
      ref = RealTimeBackend.send_after(self(), :cancelled, 100)
      result = RealTimeBackend.cancel_timer(ref)

      assert is_integer(result) or result == false
      refute_receive :cancelled, 150
    end

    test "returns false when canceling already-fired timer" do
      ref = RealTimeBackend.send_after(self(), :fired, 10)
      assert_receive :fired, 1_000

      result = RealTimeBackend.cancel_timer(ref)
      assert result == false
    end

    test "sleeps block execution for specified duration" do
      start = System.monotonic_time(:millisecond)
      RealTimeBackend.sleep(50)
      elapsed = System.monotonic_time(:millisecond) - start

      assert elapsed >= 45
    end
  end

  describe "VirtualTimeBackend" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      Process.put(:virtual_clock, clock)
      {:ok, clock: clock}
    end

    test "sends messages via virtual clock", %{clock: clock} do
      ref = VirtualTimeBackend.send_after(self(), :virtual_msg, 100)
      assert is_reference(ref)

      refute_receive :virtual_msg, 10

      VirtualClock.advance(clock, 100)
      assert_receive :virtual_msg, 10
    end

    test "cancels virtual timers", %{clock: clock} do
      ref = VirtualTimeBackend.send_after(self(), :wont_arrive, 100)

      assert VirtualTimeBackend.cancel_timer(ref) == 100

      VirtualClock.advance(clock, 100)
      refute_receive :wont_arrive, 10
    end

    test "cancelling an unknown timer reports false", %{clock: _clock} do
      ref = VirtualTimeBackend.send_after(self(), :wont_arrive, 100)

      VirtualTimeBackend.cancel_timer(ref)

      assert VirtualTimeBackend.cancel_timer(ref) == false
    end

    test "sleeps in virtual time without blocking real execution", %{clock: clock} do
      # Start a process that will sleep in virtual time
      parent = self()

      _sleeper =
        spawn(fn ->
          Process.put(:virtual_clock, clock)
          VirtualTimeBackend.sleep(1000)
          send(parent, :after_sleep)
        end)

      # Wait until the sleep has actually registered its wake-up: advancing the
      # clock before that would leave the sleeper waiting forever.
      wait_until(fn -> VirtualClock.scheduled_count(clock) == 1 end)

      # Sleep is waiting, not completed yet
      refute_receive :after_sleep, 50

      # Advance virtual time
      VirtualClock.advance(clock, 1000)

      # Now sleep completes
      assert_receive :after_sleep, 100
    end

    test "raises when virtual clock not set" do
      Process.delete(:virtual_clock)

      assert_raise RuntimeError, ~r/Virtual clock not set/, fn ->
        VirtualTimeBackend.send_after(self(), :msg, 100)
      end
    end

    test "sleep raises when virtual clock not set" do
      Process.delete(:virtual_clock)

      assert_raise RuntimeError, ~r/Virtual clock not set/, fn ->
        VirtualTimeBackend.sleep(100)
      end
    end
  end

  describe "TimeBackend behaviour contract" do
    test "both backends implement required callbacks" do
      behaviours_real =
        RealTimeBackend.module_info(:attributes)
        |> Keyword.get(:behaviour, [])

      behaviours_virtual =
        VirtualTimeBackend.module_info(:attributes)
        |> Keyword.get(:behaviour, [])

      assert TimeBackend in behaviours_real
      assert TimeBackend in behaviours_virtual
    end

    test "send_after returns reference in both backends" do
      # Real backend
      ref_real = RealTimeBackend.send_after(self(), :test1, 10)
      assert is_reference(ref_real)

      # Virtual backend
      {:ok, clock} = VirtualClock.start_link()
      Process.put(:virtual_clock, clock)
      ref_virtual = VirtualTimeBackend.send_after(self(), :test2, 10)
      assert is_reference(ref_virtual)

      # Cleanup
      assert_receive :test1, 1_000
      VirtualClock.advance(clock, 10)
      assert_receive :test2, 10
    end
  end
end
