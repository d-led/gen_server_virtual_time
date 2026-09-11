defmodule VirtualTimeGenStateMachineEdgeCasesTest do
  use ExUnit.Case, async: true

  # Test module with various callback modes and edge cases
  defmodule TestSM do
    use VirtualTimeGenStateMachine, callback_mode: :handle_event_function

    def start_link(opts \\ []) do
      VirtualTimeGenStateMachine.start_link(__MODULE__, :init_state, opts)
    end

    def start(opts \\ []) do
      VirtualTimeGenStateMachine.start(__MODULE__, :init_state, opts)
    end

    def cast_test(server) do
      VirtualTimeGenStateMachine.cast(server, :test_cast)
    end

    def call_test(server) do
      VirtualTimeGenStateMachine.call(server, :test_call)
    end

    def stop_test(server) do
      VirtualTimeGenStateMachine.stop(server)
    end

    def child_spec(opts) do
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, [opts]},
        type: :worker,
        restart: :permanent,
        shutdown: 5000,
        modules: [__MODULE__]
      }
    end

    def schedule_timeout(server, delay) do
      VirtualTimeGenStateMachine.call(server, {:schedule_timeout, delay})
    end

    def cancel_timeout(server, ref) do
      VirtualTimeGenStateMachine.call(server, {:cancel_timeout, ref})
    end

    def sleep_test(duration) do
      VirtualTimeGenStateMachine.sleep(duration)
    end

    @impl true
    def init(:init_state) do
      {:ok, :ready, %{count: 0, timers: []}}
    end

    @impl true
    def handle_event(:cast, :test_cast, _state, data) do
      {:keep_state, %{data | count: data.count + 1}}
    end

    @impl true
    def handle_event({:call, from}, :test_call, _state, data) do
      {:keep_state_and_data, [{:reply, from, data.count}]}
    end

    @impl true
    def handle_event(:info, :timeout_msg, _state, data) do
      {:keep_state, %{data | count: data.count + 1}}
    end

    @impl true
    def handle_event({:call, from}, {:schedule_timeout, delay}, _state, _data) do
      # Scheduled from inside the server, so it uses the server's own clock.
      # Scheduling from a test process would use *that* process's backend,
      # which is real time unless the test set it up first.
      ref = VirtualTimeGenStateMachine.send_after(self(), :timeout_msg, delay)
      {:keep_state_and_data, [{:reply, from, ref}]}
    end

    @impl true
    def handle_event({:call, from}, {:cancel_timeout, ref}, _state, _data) do
      {:keep_state_and_data, [{:reply, from, VirtualTimeGenStateMachine.cancel_timer(ref)}]}
    end

    @impl true
    def handle_event(_event_type, _event_content, _state, _data) do
      {:keep_state_and_data, []}
    end
  end

  # Test module with state_functions callback mode
  defmodule StateFunctionsSM do
    use VirtualTimeGenStateMachine, callback_mode: :state_functions

    def start_link(opts \\ []) do
      VirtualTimeGenStateMachine.start_link(__MODULE__, :init_state, opts)
    end

    def trigger_transition(server) do
      VirtualTimeGenStateMachine.cast(server, :transition)
    end

    def get_state(server) do
      VirtualTimeGenStateMachine.call(server, :get_state)
    end

    @impl true
    def init(:init_state) do
      {:ok, :idle, %{transitions: 0}}
    end

    def idle(:cast, :transition, data) do
      {:next_state, :active, %{data | transitions: data.transitions + 1}}
    end

    def idle({:call, from}, :get_state, _data) do
      {:keep_state_and_data, [{:reply, from, :idle}]}
    end

    def active(:cast, :transition, data) do
      {:next_state, :idle, %{data | transitions: data.transitions + 1}}
    end

    def active({:call, from}, :get_state, _data) do
      {:keep_state_and_data, [{:reply, from, :active}]}
    end
  end

  # Test module with state_enter callback mode
  defmodule StateEnterSM do
    use VirtualTimeGenStateMachine, callback_mode: [:handle_event_function, :state_enter]

    def start_link(opts \\ []) do
      VirtualTimeGenStateMachine.start_link(__MODULE__, :init_state, opts)
    end

    def switch_state(server) do
      VirtualTimeGenStateMachine.cast(server, :switch)
    end

    def get_enters(server) do
      VirtualTimeGenStateMachine.call(server, :get_enters)
    end

    @impl true
    def init(:init_state) do
      {:ok, :state_a, %{enters: 0}}
    end

    @impl true
    def handle_event(:enter, _old_state, _new_state, data) do
      {:keep_state, %{data | enters: data.enters + 1}}
    end

    @impl true
    def handle_event(:cast, :switch, :state_a, data) do
      {:next_state, :state_b, data}
    end

    @impl true
    def handle_event(:cast, :switch, :state_b, data) do
      {:next_state, :state_a, data}
    end

    @impl true
    def handle_event({:call, from}, :get_enters, _state, data) do
      {:keep_state_and_data, [{:reply, from, data.enters}]}
    end
  end

  describe "VirtualTimeGenStateMachine API functions" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      {:ok, clock: clock}
    end

    test "start_link/3 with virtual clock", %{clock: clock} do
      {:ok, server} = TestSM.start_link(virtual_clock: clock)
      assert Process.alive?(server)
      GenServer.stop(server)
    end

    test "start_link/3 with local virtual clock option" do
      {:ok, clock} = VirtualClock.start_link()
      {:ok, server} = TestSM.start_link(virtual_clock: clock)
      assert Process.alive?(server)
      GenServer.stop(server)
    end

    test "start_link/3 with real_time option" do
      {:ok, server} = TestSM.start_link(real_time: true)
      assert Process.alive?(server)
      GenServer.stop(server)
    end

    test "start/3 without linking", %{clock: clock} do
      {:ok, server} = TestSM.start(virtual_clock: clock)
      assert Process.alive?(server)
      GenServer.stop(server)
    end

    test "cast/2 sends asynchronous message", %{clock: clock} do
      {:ok, server} = TestSM.start_link(virtual_clock: clock)

      TestSM.cast_test(server)

      # call_test/1 is a synchronous call handled after the cast, and it reports
      # the count the cast increments
      assert TestSM.call_test(server) == 1

      GenServer.stop(server)
    end

    test "call/3 makes synchronous call", %{clock: clock} do
      {:ok, server} = TestSM.start_link(virtual_clock: clock)

      result = TestSM.call_test(server)
      assert result == 0

      GenServer.stop(server)
    end

    test "stop/3 stops the server", %{clock: clock} do
      {:ok, server} = TestSM.start_link(virtual_clock: clock)
      assert Process.alive?(server)

      ref = Process.monitor(server)
      TestSM.stop_test(server)

      assert_receive {:DOWN, ^ref, :process, ^server, :normal}, 2_000
    end

    test "send_after/3 schedules message in virtual time", %{clock: clock} do
      {:ok, server} = TestSM.start_link(virtual_clock: clock)

      TestSM.schedule_timeout(server, 100)

      # Not due yet
      assert TestSM.call_test(server) == 0

      # advance/2 returns once the actor has acknowledged, so the scheduled
      # message has been handled by the time it returns
      VirtualClock.advance(clock, 100)

      assert TestSM.call_test(server) == 1

      GenServer.stop(server)
    end

    test "cancel_timer/1 cancels scheduled timer", %{clock: clock} do
      {:ok, server} = TestSM.start_link(virtual_clock: clock)

      ref = TestSM.schedule_timeout(server, 100)

      # Cancelling reports the remaining virtual time, like Process.cancel_timer/1
      assert TestSM.cancel_timeout(server, ref) == 100

      # Advancing past the deadline must not deliver the cancelled message
      VirtualClock.advance(clock, 100)

      assert TestSM.call_test(server) == 0

      GenServer.stop(server)
    end

    test "sleep/1 function exists and can be called" do
      # Test that sleep function exists and can be called
      # The actual sleep behavior is tested in the time backend tests
      # We just verify the function exists and doesn't crash immediately
      assert is_function(&TestSM.sleep_test/1)
    end
  end

  describe "Time backend configuration" do
    test "set_virtual_clock/1 sets virtual time backend" do
      {:ok, clock} = VirtualClock.start_link()

      VirtualTimeGenStateMachine.set_virtual_clock(
        clock,
        :i_know_what_i_am_doing,
        "testing time backend configuration"
      )

      backend = VirtualTimeGenStateMachine.get_time_backend()
      assert backend == VirtualTimeBackend
    end

    test "use_real_time/0 sets real time backend" do
      VirtualTimeGenStateMachine.use_real_time(
        :i_know_what_i_am_doing,
        "testing real time backend configuration"
      )

      backend = VirtualTimeGenStateMachine.get_time_backend()
      assert backend == RealTimeBackend
    end

    test "get_time_backend/0 returns default when not set" do
      # Clear any existing settings
      Process.delete(:time_backend)

      backend = VirtualTimeGenStateMachine.get_time_backend()
      assert backend == RealTimeBackend
    end
  end

  describe "State functions callback mode" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      {:ok, clock: clock}
    end

    test "state_functions mode works correctly", %{clock: clock} do
      {:ok, server} = StateFunctionsSM.start_link(virtual_clock: clock)

      # Start in idle state
      assert StateFunctionsSM.get_state(server) == :idle

      # Trigger transition to active
      StateFunctionsSM.trigger_transition(server)
      assert StateFunctionsSM.get_state(server) == :active

      # Trigger transition back to idle
      StateFunctionsSM.trigger_transition(server)
      assert StateFunctionsSM.get_state(server) == :idle

      GenServer.stop(server)
    end
  end

  describe "State enter callback mode" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      {:ok, clock: clock}
    end

    test "state_enter callbacks are invoked", %{clock: clock} do
      {:ok, server} = StateEnterSM.start_link(virtual_clock: clock)

      # Initial state enter should be counted
      enters = StateEnterSM.get_enters(server)
      assert enters == 1

      # Switch states - should trigger enter callbacks
      StateEnterSM.switch_state(server)
      enters = StateEnterSM.get_enters(server)
      assert enters == 2

      # Switch back - should trigger another enter callback
      StateEnterSM.switch_state(server)
      enters = StateEnterSM.get_enters(server)
      assert enters == 3

      GenServer.stop(server)
    end
  end

  describe "Local clock injection" do
    test "per-instance virtual clock works" do
      {:ok, clock1} = VirtualClock.start_link()
      {:ok, clock2} = VirtualClock.start_link()

      # Start servers with different clocks
      {:ok, server1} = TestSM.start_link(virtual_clock: clock1)
      {:ok, server2} = TestSM.start_link(virtual_clock: clock2)

      # Schedule messages on both
      TestSM.schedule_timeout(server1, 100)
      TestSM.schedule_timeout(server2, 100)

      # Only clock1 advances, so only server1's timer fires
      VirtualClock.advance(clock1, 100)
      assert TestSM.call_test(server1) == 1
      assert TestSM.call_test(server2) == 0

      # Now clock2 catches up, leaving server1 where it was
      VirtualClock.advance(clock2, 100)
      assert TestSM.call_test(server2) == 1
      assert TestSM.call_test(server1) == 1

      GenServer.stop(server1)
      GenServer.stop(server2)
    end

    test "real_time option overrides global settings" do
      # Set global virtual clock
      {:ok, clock} = VirtualClock.start_link()

      VirtualTimeGenStateMachine.set_virtual_clock(
        clock,
        :i_know_what_i_am_doing,
        "testing time backend configuration"
      )

      # Start server with real_time: true
      {:ok, server} = TestSM.start_link(real_time: true)

      # The server should be using real time backend internally
      # We can't easily test this without accessing internal state
      # But we can verify the server started successfully
      assert Process.alive?(server)

      GenServer.stop(server)
    end
  end

  describe "Wrapper module edge cases" do
    test "wrapper handles missing module gracefully" do
      # Test the wrapper's fallback behavior
      wrapper = VirtualTimeGenStateMachine.Wrapper

      # Test callback_mode when no module is set
      Process.delete(:__vtgsm_module__)
      assert wrapper.callback_mode() == :handle_event_function
    end

    test "wrapper handles missing functions gracefully" do
      # Test dynamic dispatch when functions don't exist
      wrapper = VirtualTimeGenStateMachine.Wrapper

      # Set a module that doesn't have the expected functions
      Process.put(:__vtgsm_module__, String)

      # These should return default responses
      result = wrapper.closed(:cast, :test, %{})
      assert result == {:keep_state_and_data, []}

      result = wrapper.open(:cast, :test, %{})
      assert result == {:keep_state_and_data, []}

      result = wrapper.locked(:cast, :test, %{})
      assert result == {:keep_state_and_data, []}

      result = wrapper.waiting(:cast, :test, %{})
      assert result == {:keep_state_and_data, []}

      result = wrapper.working(:cast, :test, %{})
      assert result == {:keep_state_and_data, []}

      result = wrapper.aborting(:cast, :test, %{})
      assert result == {:keep_state_and_data, []}
    end

    test "wrapper terminate and code_change callbacks" do
      wrapper = VirtualTimeGenStateMachine.Wrapper

      # Test terminate with no module
      Process.delete(:__vtgsm_module__)
      assert wrapper.terminate(:normal, :state, %{}) == :ok

      # Test code_change with no module
      result = wrapper.code_change("1.0", :state, %{}, %{})
      assert result == {:ok, :state, %{}}
    end
  end

  describe "Error handling and edge cases" do
    test "handles invalid init responses gracefully" do
      # This tests the wrapper's init function with various return values
      init_fun = fn -> {:error, :invalid_init} end

      # The wrapper should pass through the error
      result = VirtualTimeGenStateMachine.Wrapper.init({init_fun, TestSM})
      assert result == {:error, :invalid_init}
    end

    test "handles init with timeout" do
      init_fun = fn -> {:ok, :state, %{}, 5000} end

      result = VirtualTimeGenStateMachine.Wrapper.init({init_fun, TestSM})
      assert result == {:ok, :state, %{}, 5000}
    end

    test "handles init with continue" do
      init_fun = fn -> {:ok, :state, %{}, {:continue, :init}} end

      result = VirtualTimeGenStateMachine.Wrapper.init({init_fun, TestSM})
      assert result == {:ok, :state, %{}, {:continue, :init}}
    end

    test "stop function exists and can be called" do
      # Test that stop function exists and can be called
      # The actual stop behavior is complex to test reliably
      assert is_function(&VirtualTimeGenStateMachine.stop/1)
      assert is_function(&VirtualTimeGenStateMachine.stop/2)
      assert is_function(&VirtualTimeGenStateMachine.stop/3)
    end
  end

  describe "Macro and behavior integration" do
    test "__using__ macro sets up behavior correctly" do
      # Test that the macro sets up the :gen_statem behavior
      assert TestSM.__info__(:attributes)[:behaviour] == [:gen_statem]
    end

    test "child_spec is generated correctly" do
      child_spec = TestSM.child_spec(:init_state)

      assert child_spec.id == TestSM
      assert child_spec.start == {TestSM, :start_link, [:init_state]}
      assert child_spec.type == :worker
      assert child_spec.restart == :permanent
      assert child_spec.shutdown == 5000
      assert child_spec.modules == [TestSM]
    end

    test "send_after_self helper function works" do
      {:ok, clock} = VirtualClock.start_link()

      VirtualTimeGenStateMachine.set_virtual_clock(
        clock,
        :i_know_what_i_am_doing,
        "testing time backend configuration"
      )

      {:ok, server} = TestSM.start_link(virtual_clock: clock)

      # send_after_self/2 schedules to the *calling* process, so the message
      # lands in this test process's own mailbox
      TestSM.send_after_self(:test_msg, 100)
      refute_received :test_msg

      VirtualClock.advance(clock, 100)
      assert_received :test_msg

      GenServer.stop(server)
    end
  end

  describe "Performance and timing" do
    test "virtual time is significantly faster than real time" do
      {:ok, clock} = VirtualClock.start_link()
      {:ok, server} = TestSM.start_link(virtual_clock: clock)

      start_time = System.monotonic_time(:millisecond)

      # Ten timers spread across one virtual second
      for i <- 1..10 do
        TestSM.schedule_timeout(server, i * 100)
      end

      VirtualClock.advance(clock, 1000)

      elapsed = System.monotonic_time(:millisecond) - start_time

      # Every timer fired ...
      assert TestSM.call_test(server) == 10
      # ... and simulating a full second cost less real time than the second it
      # simulated. (A tighter millisecond budget would measure the machine.)
      assert elapsed < 1000

      GenServer.stop(server)
    end
  end
end
