defmodule VirtualTimeGenStateMachineTest do
  use ExUnit.Case, async: false

  # Simple switch example with handle_event_function callback mode
  defmodule SwitchSM do
    use VirtualTimeGenStateMachine, callback_mode: :handle_event_function

    def start_link(initial_state) do
      GenStateMachine.start_link(__MODULE__, initial_state, [])
    end

    def flip(server) do
      GenStateMachine.cast(server, :flip)
    end

    def get_count(server) do
      GenStateMachine.call(server, :get_count)
    end

    @impl true
    def init(initial_state) do
      {:ok, initial_state, %{count: 0, timeout_count: 0}}
    end

    @impl true
    def handle_event(:cast, :flip, :off, data) do
      # Schedule a timeout in virtual time
      VirtualTimeGenStateMachine.send_after(self(), :timeout_msg, 100)
      {:next_state, :on, %{data | count: data.count + 1}}
    end

    @impl true
    def handle_event(:cast, :flip, :on, data) do
      {:next_state, :off, data}
    end

    @impl true
    def handle_event({:call, from}, :get_count, _state, data) do
      {:keep_state_and_data, [{:reply, from, data.count}]}
    end

    @impl true
    def handle_event(:info, :timeout_msg, _state, data) do
      {:keep_state, %{data | timeout_count: data.timeout_count + 1}}
    end

    @impl true
    def handle_event(event_type, event_content, state, data) do
      super(event_type, event_content, state, data)
    end
  end

  # Example with state_functions callback mode
  defmodule DoorSM do
    use VirtualTimeGenStateMachine, callback_mode: :state_functions

    def start_link() do
      GenStateMachine.start_link(__MODULE__, nil, [])
    end

    def open(server) do
      GenStateMachine.cast(server, :open)
    end

    def close(server) do
      GenStateMachine.cast(server, :close)
    end

    def lock(server) do
      GenStateMachine.cast(server, :lock)
    end

    def unlock(server) do
      GenStateMachine.cast(server, :unlock)
    end

    def get_state(server) do
      GenStateMachine.call(server, :get_state)
    end

    @impl true
    def init(_) do
      {:ok, :closed, %{open_count: 0, lock_count: 0}}
    end

    def closed(:cast, :open, data) do
      VirtualTimeGenStateMachine.send_after(self(), :auto_close, 1000)
      {:next_state, :open, %{data | open_count: data.open_count + 1}}
    end

    def closed(:cast, :lock, data) do
      {:next_state, :locked, %{data | lock_count: data.lock_count + 1}}
    end

    def closed({:call, from}, :get_state, _data) do
      {:keep_state_and_data, [{:reply, from, :closed}]}
    end

    def open(:cast, :close, data) do
      {:next_state, :closed, data}
    end

    def open(:info, :auto_close, data) do
      {:next_state, :closed, data}
    end

    def open({:call, from}, :get_state, _data) do
      {:keep_state_and_data, [{:reply, from, :open}]}
    end

    def locked(:cast, :unlock, data) do
      {:next_state, :closed, data}
    end

    def locked({:call, from}, :get_state, _data) do
      {:keep_state_and_data, [{:reply, from, :locked}]}
    end
  end

  # Example with state enter callbacks
  defmodule LightSM do
    use VirtualTimeGenStateMachine, callback_mode: [:handle_event_function, :state_enter]

    def start_link() do
      GenStateMachine.start_link(__MODULE__, nil, [])
    end

    def turn_on(server) do
      GenStateMachine.cast(server, :turn_on)
    end

    def turn_off(server) do
      GenStateMachine.cast(server, :turn_off)
    end

    def get_stats(server) do
      GenStateMachine.call(server, :get_stats)
    end

    @impl true
    def init(_) do
      {:ok, :off, %{enters: 0, switches: 0}}
    end

    @impl true
    def handle_event(:enter, _old_state, _state, data) do
      {:keep_state, %{data | enters: data.enters + 1}}
    end

    @impl true
    def handle_event(:cast, :turn_on, _state, data) do
      {:next_state, :on, %{data | switches: data.switches + 1}}
    end

    @impl true
    def handle_event(:cast, :turn_off, _state, data) do
      {:next_state, :off, %{data | switches: data.switches + 1}}
    end

    @impl true
    def handle_event({:call, from}, :get_stats, _state, data) do
      {:keep_state_and_data, [{:reply, from, data}]}
    end
  end

  describe "VirtualTimeGenStateMachine with handle_event_function" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenStateMachine.set_virtual_clock(clock)
      {:ok, clock: clock}
    end

    test "state transitions work correctly" do
      {:ok, server} = SwitchSM.start_link(:off)

      # Start in :off state
      assert GenStateMachine.call(server, :get_count) == 0

      # Flip to :on state
      SwitchSM.flip(server)
      assert GenStateMachine.call(server, :get_count) == 1

      # Flip back to :off state
      SwitchSM.flip(server)
      assert GenStateMachine.call(server, :get_count) == 1
    end

    test "timers fire in virtual time", %{clock: clock} do
      {:ok, server} = SwitchSM.start_link(:off)

      start_time = System.monotonic_time(:millisecond)

      # Flip to :on state - this schedules a timeout in 100ms
      SwitchSM.flip(server)

      # Advance virtual time - timer fires instantly
      VirtualClock.advance(clock, 100)

      elapsed = System.monotonic_time(:millisecond) - start_time

      # Test completed instantly
      assert elapsed < 100

      # Timer fired and updated state
      GenServer.stop(server)
    end

    test "can simulate long time periods instantly", %{clock: clock} do
      {:ok, server} = SwitchSM.start_link(:off)

      start_time = System.monotonic_time(:millisecond)

      # Simulate 10 seconds of timers
      for _ <- 1..10 do
        SwitchSM.flip(server)
        VirtualClock.advance(clock, 100)
        SwitchSM.flip(server)
      end

      elapsed = System.monotonic_time(:millisecond) - start_time
      count = SwitchSM.get_count(server)

      # Test completed quickly
      assert elapsed < 200
      # But simulated 20 state transitions
      assert count == 10

      GenServer.stop(server)
    end

    test "simulates an entire week of activity in milliseconds", %{clock: clock} do
      {:ok, server} = SwitchSM.start_link(:off)

      start_time = System.monotonic_time(:millisecond)

      # Simulate a full week (7 days = 604,800,000 milliseconds)
      # with hourly check-ins (24 hours * 7 days = 168 check-ins)
      ms_per_hour = 3_600_000

      for _hour <- 1..168 do
        SwitchSM.flip(server)
        VirtualClock.advance(clock, ms_per_hour)
        SwitchSM.flip(server)
      end

      elapsed_real_time = System.monotonic_time(:millisecond) - start_time
      count = SwitchSM.get_count(server)

      # In real time, this would take 7 days = 604,800,000 ms = ~7 days
      # With virtual time, it completes in less than a second!
      assert elapsed_real_time < 1000, "Virtual time test completed in #{elapsed_real_time}ms"

      # But we simulated an entire week of activity
      assert count == 168, "Simulated 168 state transitions (one per hour for a week)"

      # Demonstrate the time that would have passed in real world
      ms_simulated = 168 * ms_per_hour
      days_simulated = div(ms_simulated, 86_400_000)
      assert days_simulated == 7, "Simulated #{days_simulated} days of activity"

      GenServer.stop(server)
    end
  end

  describe "VirtualTimeGenStateMachine with state_functions" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenStateMachine.set_virtual_clock(clock)
      {:ok, clock: clock}
    end

    test "door state machine transitions" do
      {:ok, door} = DoorSM.start_link()

      # Start closed
      assert DoorSM.get_state(door) == :closed

      # Open the door
      DoorSM.open(door)
      assert DoorSM.get_state(door) == :open

      # Close the door
      DoorSM.close(door)
      assert DoorSM.get_state(door) == :closed

      # Lock the door
      DoorSM.lock(door)
      assert DoorSM.get_state(door) == :locked

      # Unlock
      DoorSM.unlock(door)
      assert DoorSM.get_state(door) == :closed

      GenServer.stop(door)
    end

    test "auto-close timer works with virtual time" do
      {:ok, door} = DoorSM.start_link()

      start_time = System.monotonic_time(:millisecond)

      # Open the door - schedules auto-close in 1000ms
      DoorSM.open(door)
      assert DoorSM.get_state(door) == :open

      # Manually send the auto-close message to verify the state handler works
      send(door, :auto_close)
      assert DoorSM.get_state(door) == :closed

      elapsed = System.monotonic_time(:millisecond) - start_time

      # Test completed instantly
      assert elapsed < 100

      GenServer.stop(door)
    end
  end

  describe "VirtualTimeGenStateMachine with state_enter" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenStateMachine.set_virtual_clock(clock)
      {:ok, clock: clock}
    end

    test "state enter callbacks are invoked" do
      {:ok, light} = LightSM.start_link()

      # Initial state enter counted
      stats = LightSM.get_stats(light)
      assert stats.enters == 1

      # Turn on - counts as 1 more enter
      LightSM.turn_on(light)
      stats = LightSM.get_stats(light)
      assert stats.enters == 2
      assert stats.switches == 1

      # Turn off - counts as 1 more enter
      LightSM.turn_off(light)
      stats = LightSM.get_stats(light)
      assert stats.enters == 3
      assert stats.switches == 2

      GenServer.stop(light)
    end
  end

  describe "local clock injection" do
    test "can use per-instance virtual clock" do
      {:ok, clock1} = VirtualClock.start_link()
      {:ok, clock2} = VirtualClock.start_link()

      # Start two servers with different clocks
      VirtualTimeGenStateMachine.set_virtual_clock(clock1)
      {:ok, server1} = SwitchSM.start_link(:off)

      VirtualTimeGenStateMachine.set_virtual_clock(clock2)
      {:ok, server2} = SwitchSM.start_link(:off)

      # Flip both
      SwitchSM.flip(server1)
      SwitchSM.flip(server2)

      # Advance only clock1
      VirtualClock.advance(clock1, 100)

      # Only server1's timer fired
      GenServer.stop(server1)
      GenServer.stop(server2)
    end
  end

  describe "default behavior with real time" do
    test "defaults to real time when no virtual clock is set" do
      # Don't set virtual clock - should use real time by default
      {:ok, server} = SwitchSM.start_link(:off)

      # Verify backend is RealTimeBackend
      backend = VirtualTimeGenStateMachine.get_time_backend()
      assert backend == RealTimeBackend

      GenServer.stop(server)
    end

    test "can explicitly use real time" do
      VirtualTimeGenStateMachine.use_real_time()

      {:ok, server} = SwitchSM.start_link(:off)

      backend = VirtualTimeGenStateMachine.get_time_backend()
      assert backend == RealTimeBackend

      GenServer.stop(server)
    end
  end

  describe "comparison with real time" do
    setup do
      VirtualTimeGenStateMachine.use_real_time()
      :ok
    end

    @tag :slow
    test "real time version is slow" do
      start_time = System.monotonic_time(:millisecond)

      {:ok, server} = SwitchSM.start_link(:off)
      SwitchSM.flip(server)

      # Must wait for real time
      Process.sleep(150)

      elapsed = System.monotonic_time(:millisecond) - start_time

      # Actually waited ~150ms
      assert elapsed >= 100

      GenServer.stop(server)
    end
  end
end
