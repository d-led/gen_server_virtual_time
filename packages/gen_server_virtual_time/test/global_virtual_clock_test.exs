defmodule GlobalVirtualClockTest do
  # This test must run sequentially to avoid interference
  use ExUnit.Case, async: false

  defmodule TestServer do
    use VirtualTimeGenServer

    def init(initial_count) do
      schedule_tick()
      {:ok, %{count: initial_count}}
    end

    def handle_info(:tick, state) do
      new_count = state.count + 1
      schedule_tick()
      {:noreply, %{state | count: new_count}}
    end

    def handle_call(:get_count, _from, state) do
      {:reply, state.count, state}
    end

    defp schedule_tick do
      VirtualTimeGenServer.send_after(self(), :tick, 100)
    end
  end

  test "GLOBAL CLOCK: Coordinated simulation with multiple servers" do
    # This is the ONLY test that should use the global virtual clock
    # It tests coordinated simulation where multiple servers share the same timeline

    {:ok, clock} = VirtualClock.start_link()

    # Set global virtual clock for coordinated simulation
    VirtualTimeGenServer.set_virtual_clock(
      clock,
      :i_know_what_i_am_doing,
      "Testing coordinated simulation with multiple servers sharing the same virtual timeline"
    )

    # Start multiple servers that will share the same virtual time
    {:ok, server1} = VirtualTimeGenServer.start_link(TestServer, 0)
    {:ok, server2} = VirtualTimeGenServer.start_link(TestServer, 10)
    {:ok, server3} = VirtualTimeGenServer.start_link(TestServer, 20)

    # Advance virtual time - all servers should tick together
    VirtualClock.advance(clock, 500)

    # All servers should have the same number of ticks (5)
    count1 = GenServer.call(server1, :get_count)
    count2 = GenServer.call(server2, :get_count)
    count3 = GenServer.call(server3, :get_count)

    # 0 + 5 ticks
    assert count1 == 5
    # 10 + 5 ticks
    assert count2 == 15
    # 20 + 5 ticks
    assert count3 == 25

    # Clean up
    GenServer.stop(server1)
    GenServer.stop(server2)
    GenServer.stop(server3)
    GenServer.stop(clock)
  end

  test "GLOBAL CLOCK: Child processes inherit global clock" do
    # Test that child processes automatically inherit the global virtual clock

    {:ok, clock} = VirtualClock.start_link()

    VirtualTimeGenServer.set_virtual_clock(
      clock,
      :i_know_what_i_am_doing,
      "Testing that child processes inherit global virtual clock"
    )

    # Start server without explicit virtual_clock - should inherit global
    {:ok, server} = VirtualTimeGenServer.start_link(TestServer, 0)

    VirtualClock.advance(clock, 300)

    count = GenServer.call(server, :get_count)
    # 0 + 3 ticks
    assert count == 3

    GenServer.stop(server)
    GenServer.stop(clock)
  end
end
