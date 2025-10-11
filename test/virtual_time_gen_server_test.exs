defmodule VirtualTimeGenServerTest do
  use ExUnit.Case, async: false

  # A simple ticker GenServer for testing
  defmodule TickerServer do
    use VirtualTimeGenServer

    def start_link(interval) do
      VirtualTimeGenServer.start_link(__MODULE__, interval, [])
    end

    def get_count(server) do
      VirtualTimeGenServer.call(server, :get_count)
    end

    @impl true
    def init(interval) do
      schedule_tick(interval)
      {:ok, %{interval: interval, count: 0}}
    end

    @impl true
    def handle_info(:tick, state) do
      new_count = state.count + 1
      schedule_tick(state.interval)
      {:noreply, %{state | count: new_count}}
    end

    @impl true
    def handle_call(:get_count, _from, state) do
      {:reply, state.count, state}
    end

    defp schedule_tick(interval) do
      VirtualTimeGenServer.send_after(self(), :tick, interval)
    end
  end

  describe "VirtualTimeGenServer with real time (slow tests)" do
    setup do
      VirtualTimeGenServer.use_real_time()
      :ok
    end

    @tag :slow
    test "waiting for real time is slow and wastes time" do
      start_time = System.monotonic_time(:millisecond)

      {:ok, server} = TickerServer.start_link(100)

      # We have to actually wait for real time to pass
      Process.sleep(600)

      count = TickerServer.get_count(server)
      elapsed = System.monotonic_time(:millisecond) - start_time

      # We actually waited ~600ms
      assert elapsed >= 500
      assert count >= 5

      GenServer.stop(server)
    end
  end

  describe "VirtualTimeGenServer with virtual time (instant tests)" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)
      {:ok, clock: clock}
    end

    test "advancing virtual time is instant and precise", %{clock: clock} do
      start_time = System.monotonic_time(:millisecond)

      {:ok, server} = TickerServer.start_link(100)

      # Advance virtual time by 500ms - happens instantly!
      VirtualClock.advance(clock, 500)

      count = TickerServer.get_count(server)
      elapsed = System.monotonic_time(:millisecond) - start_time

      # Test completed in milliseconds, not seconds
      assert elapsed < 100
      # But we simulated 500ms of time
      assert count == 5

      GenServer.stop(server)
    end

    test "can simulate hours of time instantly", %{clock: clock} do
      {:ok, server} = TickerServer.start_link(1000)

      start_time = System.monotonic_time(:millisecond)

      # Simulate 1 hour (3,600,000 ms)
      VirtualClock.advance(clock, 3_600_000)

      elapsed = System.monotonic_time(:millisecond) - start_time
      count = TickerServer.get_count(server)

      # Completed in seconds, not hours
      # (With virtual time, 1 hour simulation takes ~4 seconds vs 3600 seconds real time)
      assert elapsed < 10_000, "Should complete in under 10 seconds"
      # But simulated 1 hour of ticks
      assert count == 3600

      GenServer.stop(server)
    end

    test "advance_to_next allows precise control", %{clock: clock} do
      {:ok, server} = TickerServer.start_link(100)

      # Advance to first tick
      VirtualClock.advance_to_next(clock)
      assert TickerServer.get_count(server) == 1

      # Advance to second tick
      VirtualClock.advance_to_next(clock)
      assert TickerServer.get_count(server) == 2

      # Advance to third tick
      VirtualClock.advance_to_next(clock)
      assert TickerServer.get_count(server) == 3

      GenServer.stop(server)
    end

    test "multiple servers can be tested simultaneously", %{clock: clock} do
      {:ok, fast_server} = TickerServer.start_link(10)
      {:ok, slow_server} = TickerServer.start_link(100)

      # Advance 1 second of virtual time
      VirtualClock.advance(clock, 1000)

      # Fast server ticked 100 times
      assert TickerServer.get_count(fast_server) == 100
      # Slow server ticked 10 times
      assert TickerServer.get_count(slow_server) == 10

      GenServer.stop(fast_server)
      GenServer.stop(slow_server)
    end
  end

  describe "demonstrates the futility of waiting (like RxJava tests)" do
    test "DON'T WAIT FOREVER - real time test would take too long" do
      # This test demonstrates that with real time, we'd need to wait
      # Let's say we want to test a server that ticks every 10 seconds
      # and we want to verify 100 ticks - that's 1000 seconds or ~16 minutes!
      #
      # With virtual time, this is fast:

      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      # 10 second interval
      {:ok, server} = TickerServer.start_link(10_000)

      start_time = System.monotonic_time(:millisecond)

      # Simulate 1000 seconds (100 ticks)
      VirtualClock.advance(clock, 1_000_000)

      elapsed = System.monotonic_time(:millisecond) - start_time
      count = TickerServer.get_count(server)

      # Completed in well under a second (vs 1000 seconds real time!)
      assert elapsed < 2_000, "Should complete in under 2 seconds vs 1000 seconds real time"
      # But simulated 16+ minutes
      assert count == 100

      GenServer.stop(server)
    end

    test "testing complex timing scenarios becomes trivial" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      # Start three servers with different intervals
      # Every 100ms
      {:ok, server1} = TickerServer.start_link(100)
      # Every 300ms
      {:ok, server2} = TickerServer.start_link(300)
      # Every 1000ms
      {:ok, server3} = TickerServer.start_link(1000)

      # Advance to a specific point in time
      VirtualClock.advance(clock, 3000)

      # Verify precise tick counts
      assert TickerServer.get_count(server1) == 30
      assert TickerServer.get_count(server2) == 10
      assert TickerServer.get_count(server3) == 3

      # Continue simulation
      VirtualClock.advance(clock, 2000)

      assert TickerServer.get_count(server1) == 50
      # 5000 / 300 = 16.67 -> 16
      assert TickerServer.get_count(server2) == 16
      assert TickerServer.get_count(server3) == 5

      GenServer.stop(server1)
      GenServer.stop(server2)
      GenServer.stop(server3)
    end
  end
end
