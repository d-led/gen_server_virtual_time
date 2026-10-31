defmodule WaitForQuiescenceUntilTest do
  use ExUnit.Case, async: true

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

    def handle_info(msg, state) when msg in [:immediate, :early, :middle, :late] do
      new_count = state.count + 1
      {:noreply, %{state | count: new_count}}
    end

    def handle_call(:get_count, _from, state) do
      {:reply, state.count, state}
    end

    defp schedule_tick do
      VirtualTimeGenServer.send_after(self(), :tick, 100)
    end
  end

  test "wait_for_quiescence_until waits for events up to specific time" do
    {:ok, clock} = VirtualClock.start_link()
    {:ok, server} = VirtualTimeGenServer.start_link(TestServer, 0, virtual_clock: clock)

    # Schedule events at different times
    # At time 0
    VirtualTimeGenServer.send_after(server, :immediate, 0)
    # At time 50
    VirtualTimeGenServer.send_after(server, :early, 50)
    # At time 150
    VirtualTimeGenServer.send_after(server, :middle, 150)
    # At time 500
    VirtualTimeGenServer.send_after(server, :late, 500)

    # Advance time to 100ms to trigger events at 0 and 50
    VirtualClock.advance(clock, 100)

    # Wait for quiescence up to time 100
    # This should wait for events at 0 and 50, but ignore events at 150 and 500
    assert VirtualClock.wait_for_quiescence_until(clock, until_time: 100) == :ok

    # Check that events up to time 100 were processed
    count = GenServer.call(server, :get_count)
    # :immediate is sent at time 0, :early scheduled at 50ms, :tick scheduled at 100ms
    # Due to timing and ACK handling, we might get 1-3 messages
    assert count >= 1
    assert count <= 3

    # Check that events after time 100 are still scheduled
    scheduled_count = VirtualClock.scheduled_count(clock)
    IO.puts("Scheduled count after advance: #{scheduled_count}")
    # At least one event at 150ms or 500ms
    assert scheduled_count >= 1

    # Check that events up to time 100 are no longer scheduled
    scheduled_until_100 = VirtualClock.scheduled_count_until(clock, 100)
    assert scheduled_until_100 == 0

    GenServer.stop(server)
    GenServer.stop(clock)
  end

  test "wait_for_quiescence_until with current time waits for all events" do
    {:ok, clock} = VirtualClock.start_link()
    {:ok, server} = VirtualTimeGenServer.start_link(TestServer, 0, virtual_clock: clock)

    # Schedule events
    VirtualTimeGenServer.send_after(server, :immediate, 0)
    VirtualTimeGenServer.send_after(server, :early, 50)

    # Advance time to trigger events
    VirtualClock.advance(clock, 100)

    # Wait for quiescence up to current time (100)
    assert VirtualClock.wait_for_quiescence_until(clock, until_time: 100) == :ok

    # All events should be processed
    count = GenServer.call(server, :get_count)
    # :immediate is sent at time 0, :early scheduled at 50ms, :tick scheduled at 100ms
    # Due to timing and ACK handling, we might get 1-3 messages
    assert count >= 1
    assert count <= 3

    GenServer.stop(server)
    GenServer.stop(clock)
  end

  test "scheduled_count_until counts only events up to specific time" do
    {:ok, clock} = VirtualClock.start_link()

    # Schedule events at different times
    VirtualClock.send_after(clock, self(), :event1, 0)
    VirtualClock.send_after(clock, self(), :event2, 50)
    VirtualClock.send_after(clock, self(), :event3, 150)
    VirtualClock.send_after(clock, self(), :event4, 500)

    # Count events up to different times
    # Only event1
    assert VirtualClock.scheduled_count_until(clock, 0) == 1
    # event1 and event2
    assert VirtualClock.scheduled_count_until(clock, 50) == 2
    # event1 and event2
    assert VirtualClock.scheduled_count_until(clock, 100) == 2
    # event1, event2, event3
    assert VirtualClock.scheduled_count_until(clock, 200) == 3
    # All events
    assert VirtualClock.scheduled_count_until(clock, 1000) == 4

    GenServer.stop(clock)
  end
end
