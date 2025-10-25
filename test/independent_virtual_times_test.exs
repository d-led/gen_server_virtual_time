defmodule IndependentVirtualTimesTest do
  use ExUnit.Case, async: true

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

  describe "Independent virtual times don't interfere" do
    test "two instances of same module with different virtual clocks run independently" do
      # Create two independent virtual clocks
      {:ok, clock1} = VirtualClock.start_link()
      {:ok, clock2} = VirtualClock.start_link()

      # Start two instances of the same module with different virtual clocks
      {:ok, server1} =
        VirtualTimeGenServer.start_link(
          TickerServer,
          100,
          virtual_clock: clock1
        )

      {:ok, server2} =
        VirtualTimeGenServer.start_link(
          TickerServer,
          100,
          virtual_clock: clock2
        )

      # Initially both servers should have 0 ticks
      assert TickerServer.get_count(server1) == 0
      assert TickerServer.get_count(server2) == 0

      # Advance clock1 by 200ms (should trigger 2 callbacks)
      VirtualClock.advance(clock1, 200)
      # Allow messages to be processed
      Process.sleep(10)

      # Server1 should have ticked 2 times (200ms / 100ms interval)
      # Server2 should still be at 0 (its clock wasn't advanced)
      assert TickerServer.get_count(server1) == 2
      assert TickerServer.get_count(server2) == 0

      # Advance clock2 by 200ms (should trigger 2 callbacks)
      VirtualClock.advance(clock2, 200)
      # Allow messages to be processed
      Process.sleep(10)

      # Server1 should still be at 2 (its clock wasn't advanced)
      # Server2 should now have ticked 2 times (200ms / 100ms interval)
      assert TickerServer.get_count(server1) == 2
      assert TickerServer.get_count(server2) == 2

      # Advance clock1 by another 200ms (should trigger 2 more callbacks)
      VirtualClock.advance(clock1, 200)
      # Allow messages to be processed
      Process.sleep(10)

      # Server1 should now have 4 ticks total (400ms / 100ms interval)
      # Server2 should still be at 2 (its clock wasn't advanced)
      assert TickerServer.get_count(server1) == 4
      assert TickerServer.get_count(server2) == 2

      # Clean up
      GenServer.stop(server1)
      GenServer.stop(server2)
    end

    test "demonstrates complete isolation between virtual time instances" do
      # Create two independent virtual clocks
      {:ok, clock_a} = VirtualClock.start_link()
      {:ok, clock_b} = VirtualClock.start_link()

      # Start two identical servers with different virtual clocks
      {:ok, server_a} =
        VirtualTimeGenServer.start_link(
          TickerServer,
          50,
          virtual_clock: clock_a
        )

      {:ok, server_b} =
        VirtualTimeGenServer.start_link(
          TickerServer,
          50,
          virtual_clock: clock_b
        )

      # Both start at 0
      assert TickerServer.get_count(server_a) == 0
      assert TickerServer.get_count(server_b) == 0

      # Advance clock_a by 150ms (3 ticks)
      VirtualClock.advance(clock_a, 150)
      Process.sleep(10)

      # Only server_a should have ticked
      assert TickerServer.get_count(server_a) == 3
      assert TickerServer.get_count(server_b) == 0

      # Advance clock_b by 250ms (5 ticks)
      VirtualClock.advance(clock_b, 250)
      Process.sleep(10)

      # Server_a unchanged, server_b should have ticked
      assert TickerServer.get_count(server_a) == 3
      assert TickerServer.get_count(server_b) >= 1

      # Advance clock_a by 100ms (2 more ticks)
      VirtualClock.advance(clock_a, 100)
      Process.sleep(10)

      # Server_a should now have 5 ticks, server_b unchanged
      assert TickerServer.get_count(server_a) == 5
      assert TickerServer.get_count(server_b) == 5

      # Clean up
      GenServer.stop(server_a)
      GenServer.stop(server_b)
    end
  end
end
