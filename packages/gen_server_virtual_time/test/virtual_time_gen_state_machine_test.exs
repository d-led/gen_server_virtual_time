defmodule VirtualTimeGenStateMachineTest do
  use ExUnit.Case, async: true

  # Simple switch example with handle_event_function callback mode
  defmodule SwitchSM do
    use VirtualTimeGenStateMachine, callback_mode: :handle_event_function

    def start_link(initial_state, opts \\ []) do
      VirtualTimeGenStateMachine.start_link(__MODULE__, initial_state, opts)
    end

    def flip(server) do
      VirtualTimeGenStateMachine.cast(server, :flip)
      # A cast is asynchronous, and flipping schedules a timer relative to the
      # clock, so wait until it has been handled before time is allowed to move.
      VirtualTimeGenStateMachine.call(server, :get_count)
      :ok
    end

    def get_count(server) do
      VirtualTimeGenStateMachine.call(server, :get_count)
    end

    def get_timeout_count(server) do
      VirtualTimeGenStateMachine.call(server, :get_timeout_count)
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
    def handle_event({:call, from}, :get_timeout_count, _state, data) do
      {:keep_state_and_data, [{:reply, from, data.timeout_count}]}
    end

    @impl true
    def handle_event(:info, :timeout_msg, _state, data) do
      {:keep_state, %{data | timeout_count: data.timeout_count + 1}}
    end

    @impl true
    def handle_event(_event_type, _event_content, _state, _data) do
      {:keep_state_and_data, []}
    end
  end

  # Example with state_functions callback mode
  defmodule DoorSM do
    use VirtualTimeGenStateMachine, callback_mode: :state_functions

    def start_link(opts \\ []) do
      VirtualTimeGenStateMachine.start_link(__MODULE__, nil, opts)
    end

    def open(server) do
      VirtualTimeGenStateMachine.cast(server, :open)
    end

    def close(server) do
      VirtualTimeGenStateMachine.cast(server, :close)
    end

    def lock(server) do
      VirtualTimeGenStateMachine.cast(server, :lock)
    end

    def unlock(server) do
      VirtualTimeGenStateMachine.cast(server, :unlock)
    end

    def get_state(server) do
      VirtualTimeGenStateMachine.call(server, :get_state)
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

    def start_link(opts \\ []) do
      VirtualTimeGenStateMachine.start_link(__MODULE__, nil, opts)
    end

    def turn_on(server) do
      VirtualTimeGenStateMachine.cast(server, :turn_on)
    end

    def turn_off(server) do
      VirtualTimeGenStateMachine.cast(server, :turn_off)
    end

    def get_stats(server) do
      VirtualTimeGenStateMachine.call(server, :get_stats)
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
      {:ok, clock: clock}
    end

    test "state transitions work correctly", %{clock: clock} do
      {:ok, server} = SwitchSM.start_link(:off, virtual_clock: clock)

      # Start in :off state
      assert VirtualTimeGenStateMachine.call(server, :get_count) == 0

      # Flip to :on state
      SwitchSM.flip(server)
      assert VirtualTimeGenStateMachine.call(server, :get_count) == 1

      # Flip back to :off state
      SwitchSM.flip(server)
      assert VirtualTimeGenStateMachine.call(server, :get_count) == 1
    end

    test "a timer fires when virtual time reaches it, and not before", %{clock: clock} do
      {:ok, server} = SwitchSM.start_link(:off, virtual_clock: clock)

      # Flipping to :on schedules a timeout 100ms ahead
      SwitchSM.flip(server)
      assert SwitchSM.get_timeout_count(server) == 0

      VirtualClock.advance(clock, 99)
      assert SwitchSM.get_timeout_count(server) == 0

      VirtualClock.advance(clock, 1)
      assert SwitchSM.get_timeout_count(server) == 1

      GenServer.stop(server)
    end

    test "a long timeline is replayed without waiting for it", %{clock: clock} do
      {:ok, server} = SwitchSM.start_link(:off, virtual_clock: clock)

      for _ <- 1..10 do
        SwitchSM.flip(server)
        VirtualClock.advance(clock, 100)
        SwitchSM.flip(server)
      end

      assert SwitchSM.get_count(server) == 10
      assert SwitchSM.get_timeout_count(server) == 10
      assert VirtualClock.now(clock) == 1000

      GenServer.stop(server)
    end

    test "a week of hourly activity is replayed in one virtual hour at a time", %{clock: clock} do
      {:ok, server} = SwitchSM.start_link(:off, virtual_clock: clock)
      ms_per_hour = 3_600_000

      for _hour <- 1..168 do
        SwitchSM.flip(server)
        VirtualClock.advance(clock, ms_per_hour)
        SwitchSM.flip(server)
      end

      assert SwitchSM.get_count(server) == 168
      assert SwitchSM.get_timeout_count(server) == 168
      assert div(VirtualClock.now(clock), 86_400_000) == 7

      GenServer.stop(server)
    end
  end

  describe "VirtualTimeGenStateMachine with state_functions" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      {:ok, clock: clock}
    end

    test "door state machine transitions", %{clock: clock} do
      {:ok, door} = DoorSM.start_link(virtual_clock: clock)

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

    test "the auto-close timer closes the door when its time comes", %{clock: clock} do
      {:ok, door} = DoorSM.start_link(virtual_clock: clock)

      # Opening the door schedules an auto-close 1000ms ahead
      DoorSM.open(door)
      assert DoorSM.get_state(door) == :open

      VirtualClock.advance(clock, 999)
      assert DoorSM.get_state(door) == :open

      VirtualClock.advance(clock, 1)
      assert DoorSM.get_state(door) == :closed

      GenServer.stop(door)
    end
  end

  describe "VirtualTimeGenStateMachine with state_enter" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      {:ok, clock: clock}
    end

    test "state enter callbacks are invoked", %{clock: clock} do
      {:ok, light} = LightSM.start_link(virtual_clock: clock)

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
      {:ok, server1} = SwitchSM.start_link(:off, virtual_clock: clock1)
      {:ok, server2} = SwitchSM.start_link(:off, virtual_clock: clock2)

      # Flip both
      SwitchSM.flip(server1)
      SwitchSM.flip(server2)

      # Advance only clock1
      VirtualClock.advance(clock1, 100)

      assert SwitchSM.get_timeout_count(server1) == 1
      assert SwitchSM.get_timeout_count(server2) == 0

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
      VirtualTimeGenStateMachine.use_real_time(
        :i_know_what_i_am_doing,
        "testing real time functionality"
      )

      {:ok, server} = SwitchSM.start_link(:off)

      backend = VirtualTimeGenStateMachine.get_time_backend()
      assert backend == RealTimeBackend

      GenServer.stop(server)
    end
  end

  describe "comparison with real time" do
    setup do
      VirtualTimeGenStateMachine.use_real_time(
        :i_know_what_i_am_doing,
        "testing real time functionality"
      )

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
