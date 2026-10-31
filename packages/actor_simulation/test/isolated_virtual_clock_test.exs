defmodule IsolatedVirtualClockTest do
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

    def handle_call(:get_count, _from, state) do
      {:reply, state.count, state}
    end

    defp schedule_tick do
      VirtualTimeGenServer.send_after(self(), :tick, 100)
    end
  end

  test "isolated virtual clock test - no global state pollution" do
    # Each test gets its own virtual clock - no global state!
    {:ok, clock} = VirtualClock.start_link()

    # Start server with local virtual clock
    {:ok, server} = VirtualTimeGenServer.start_link(TestServer, 0, virtual_clock: clock)

    # Advance virtual time
    VirtualClock.advance(clock, 500)

    # Should have ticked 5 times (500ms / 100ms = 5)
    count = GenServer.call(server, :get_count)
    assert count == 5

    GenServer.stop(server)
    GenServer.stop(clock)
  end

  test "multiple isolated tests can run in parallel" do
    # This test should not interfere with other tests
    {:ok, clock} = VirtualClock.start_link()

    {:ok, server} = VirtualTimeGenServer.start_link(TestServer, 10, virtual_clock: clock)

    VirtualClock.advance(clock, 300)

    count = GenServer.call(server, :get_count)
    # 10 + 3 ticks
    assert count == 13

    GenServer.stop(server)
    GenServer.stop(clock)
  end

  test "ActorSimulation with isolated virtual clock" do
    # ActorSimulation should also use isolated clocks
    simulation =
      ActorSimulation.new(trace: true)
      |> ActorSimulation.add_actor(:sender,
        send_pattern: {:periodic, 100, :msg},
        targets: [:receiver]
      )
      |> ActorSimulation.add_actor(:receiver)
      |> ActorSimulation.run(duration: 200)

    trace = ActorSimulation.get_trace(simulation)

    # Debug: Print trace details
    IO.puts("Trace length: #{length(trace)}")

    Enum.with_index(trace)
    |> Enum.each(fn {event, idx} ->
      IO.puts(
        "Event #{idx}: timestamp=#{event.timestamp}, from=#{event.from}, to=#{event.to}, message=#{inspect(event.message)}, type=#{event.type}"
      )
    end)

    # Should have trace events for periodic sends
    assert length(trace) >= 2

    # Verify trace structure
    event = hd(trace)
    assert Map.has_key?(event, :timestamp)
    assert Map.has_key?(event, :from)
    assert Map.has_key?(event, :to)
    assert Map.has_key?(event, :message)
    assert Map.has_key?(event, :type)
  end
end
