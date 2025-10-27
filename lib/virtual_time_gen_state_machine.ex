defmodule VirtualTimeGenStateMachine do
  @moduledoc """
  A behavior module for GenStateMachine with virtual time support.

  This module wraps GenStateMachine and provides a `send_after/3` function that can
  work with either real time (production) or virtual time (testing).

  ## Example

      defmodule MyStateMachine do
        use VirtualTimeGenStateMachine, callback_mode: :handle_event_function

        def start_link(opts) do
          GenStateMachine.start_link(__MODULE__, :off, opts)
        end

        @impl true
        def init(_) do
          {:ok, :off, %{count: 0}}
        end

        @impl true
        def handle_event(:cast, :flip, :off, data) do
          schedule_timer(100)
          {:next_state, :on, %{data | count: data.count + 1}}
        end

        @impl true
        def handle_event(:cast, :flip, :on, data) do
          {:next_state, :off, data}
        end

        @impl true
        def handle_event(:info, :timeout, _state, data) do
          {:keep_state, %{data | timeout_fired: true}}
        end

        defp schedule_timer(delay) do
          VirtualTimeGenStateMachine.send_after(self(), :timeout, delay)
        end
      end

  ## Testing with Virtual Time

      test "state machine with timers" do
        {:ok, clock} = VirtualClock.start_link()
        VirtualTimeGenStateMachine.set_virtual_clock(clock)

        {:ok, server} = MyStateMachine.start_link([])

        # Trigger state transition
        GenStateMachine.cast(server, :flip)

        # Advance virtual time - timer fires instantly
        VirtualClock.advance(clock, 100)

        # Check that timeout fired
        assert get_timeout_fired(server) == true
      end
  """

  @behaviour :gen_statem

  # Required callbacks for :gen_statem behavior
  @doc false
  def callback_mode, do: :handle_event_function

  @doc false
  def init(_arg), do: {:ok, :undefined, :undefined}

  @doc false
  def handle_event(_event_type, _event_content, _state, _data) do
    {:keep_state_and_data, []}
  end

  @doc false
  def terminate(_reason, _state, _data), do: :ok

  @doc false
  def code_change(_old_vsn, state, data, _extra), do: {:ok, state, data}

  # Helper function to get caller information from stacktrace
  defp get_caller_info do
    case Process.info(self(), :current_stacktrace) do
      {:current_stacktrace, stacktrace} ->
        # Find the first external caller (not from this module)
        case find_external_caller(stacktrace) do
          {_module, _function, _arity, location} ->
            file = Keyword.get(location, :file, "unknown")
            line = Keyword.get(location, :line, 0)
            [file: to_string(file), line: line]

          nil ->
            []
        end

      _ ->
        []
    end
  end

  defp find_external_caller(stacktrace) do
    Enum.find_value(stacktrace, fn
      {module, function, arity, location} when module != __MODULE__ ->
        {module, function, arity, location}

      _ ->
        nil
    end)
  end

  @doc """
  Sets the virtual clock for the current process.
  All child processes will inherit this setting.
  """
  def set_virtual_clock(clock) do
    # Get caller information from stacktrace
    caller_info = get_caller_info()

    # Emit a compilation warning to alert users about potential race conditions
    IO.warn(
      """
      ⚠️  GLOBAL VIRTUAL CLOCK INJECTION DETECTED ⚠️

      VirtualTimeGenStateMachine.set_virtual_clock/1 sets a GLOBAL virtual clock that affects
      ALL child processes. This can cause race conditions in tests and production!

      Consider using test-local virtual clocks instead:

      # ❌ Global (can cause race conditions)
      VirtualTimeGenStateMachine.set_virtual_clock(clock)
      {:ok, server} = MyStateMachine.start_link([])

      # ✅ Test-local (isolated, safe)
      {:ok, server} = MyStateMachine.start_link([], virtual_clock: clock)

      For coordinated simulations, use global clocks intentionally.
      For isolated testing, use test-local clocks.
      """,
      caller_info
    )

    Process.put(:virtual_clock, clock)
    Process.put(:time_backend, VirtualTimeBackend)
  end

  @doc """
  Sets the virtual clock for the current process without emitting warnings.

  Use this when you intentionally want global virtual clock behavior and understand
  the implications. The explanation message should describe why global clock is needed.

  ## Example

      iex> {:ok, clock} = VirtualClock.start_link()
      iex> VirtualTimeGenStateMachine.set_virtual_clock(clock, :i_know_what_i_am_doing, "coordinated simulation")
      VirtualTimeBackend

  """
  def set_virtual_clock(clock, :i_know_what_i_am_doing, explanation)
      when is_binary(explanation) do
    Process.put(:virtual_clock, clock)
    Process.put(:time_backend, VirtualTimeBackend)
  end

  @doc """
  Uses real time (default behavior).
  """
  def use_real_time do
    # Get caller information from stacktrace
    caller_info = get_caller_info()

    # Emit a compilation warning to alert users about global time backend changes
    IO.warn(
      """
      ⚠️  GLOBAL TIME BACKEND CHANGE DETECTED ⚠️

      VirtualTimeGenStateMachine.use_real_time/0 changes the GLOBAL time backend for
      ALL child processes. This can cause race conditions in tests and production!

      Consider using test-local time backend instead:

      # ❌ Global (can cause race conditions)
      VirtualTimeGenStateMachine.use_real_time()
      {:ok, server} = MyStateMachine.start_link([])

      # ✅ Test-local (isolated, safe)
      {:ok, server} = MyStateMachine.start_link([], real_time: true)

      For production, the default is already real time.
      For testing, use test-local virtual clocks.
      """,
      caller_info
    )

    Process.delete(:virtual_clock)
    Process.put(:time_backend, RealTimeBackend)
  end

  @doc """
  Uses real time without emitting warnings.

  Use this when you intentionally want global real time behavior and understand
  the implications. The explanation message should describe why global real time is needed.

  ## Example

      iex> VirtualTimeGenStateMachine.use_real_time(:i_know_what_i_am_doing, "production mode")
      RealTimeBackend

  """
  def use_real_time(:i_know_what_i_am_doing, explanation) when is_binary(explanation) do
    Process.delete(:virtual_clock)
    Process.put(:time_backend, RealTimeBackend)
  end

  @doc """
  Gets the current time backend.
  """
  def get_time_backend do
    Process.get(:time_backend, RealTimeBackend)
  end

  @doc """
  Sends a message to a process after a delay in milliseconds.
  Uses the appropriate backend based on the current process configuration.
  """
  def send_after(dest, message, delay_ms) do
    backend = get_time_backend()
    backend.send_after(dest, message, delay_ms)
  end

  @doc """
  Sends a message immediately in virtual time.

  With virtual time, this schedules the message for the current virtual time,
  ensuring it gets processed in the next event cycle.
  With real time, this sends the message immediately.

  This is useful for triggering immediate responses or state changes
  within the virtual time simulation.

  ## Examples

      # Send immediate message to self
      VirtualTimeGenStateMachine.send_immediately(self(), :process_now)

      # Send immediate message to another process
      VirtualTimeGenStateMachine.send_immediately(other_pid, {:urgent, data})
  """
  def send_immediately(dest, message) do
    backend = get_time_backend()
    backend.send_immediately(dest, message)
  end

  @doc """
  Cancels a timer created with send_after/3.
  Uses the appropriate backend based on the current process configuration.
  """
  def cancel_timer(ref) do
    backend = get_time_backend()
    backend.cancel_timer(ref)
  end

  @doc """
  Sleeps for the specified duration in milliseconds.
  Uses the appropriate backend based on the current process configuration.
  """
  def sleep(duration_ms) do
    backend = get_time_backend()
    backend.sleep(duration_ms)
  end

  @doc """
  Starts a GenStateMachine with virtual time support.

  Returns {:ok, pid, backend} where backend is the time backend to use.
  Store the backend in your process state for optimal performance.
  """
  def start_link(module, init_arg, opts \\ []) do
    # Extract time-related options from opts
    {virtual_clock, opts} = Keyword.pop(opts, :virtual_clock)
    {real_time, opts} = Keyword.pop(opts, :real_time, false)

    # Determine which clock and backend to use
    # Priority: local options > global Process dictionary
    {final_clock, final_backend} = determine_time_config(virtual_clock, real_time)

    # Use a wrapper to inject virtual clock into spawned process
    init_fun = fn ->
      if final_clock do
        Process.put(:virtual_clock, final_clock)
      end

      Process.put(:time_backend, final_backend)

      # Call the module's init function
      module.init(init_arg)
    end

    # Start with a wrapper that injects the virtual clock
    case :gen_statem.start_link(VirtualTimeGenStateMachine.Wrapper, {init_fun, module}, opts) do
      {:ok, pid} -> {:ok, pid}
      error -> error
    end
  end

  @doc """
  Starts a GenStateMachine without linking.
  """
  def start(module, init_arg, opts \\ []) do
    # Extract time-related options from opts
    {virtual_clock, opts} = Keyword.pop(opts, :virtual_clock)
    {real_time, opts} = Keyword.pop(opts, :real_time, false)

    # Determine which clock and backend to use
    {final_clock, final_backend} = determine_time_config(virtual_clock, real_time)

    # Set virtual clock in current process before starting
    if final_clock do
      Process.put(:virtual_clock, final_clock)
    end

    Process.put(:time_backend, final_backend)

    # Start with the original module using native gen_statem
    :gen_statem.start(module, init_arg, opts)
  end

  @doc """
  Makes a synchronous call to a state machine.
  """
  def call(server, request, timeout \\ 5000) do
    :gen_statem.call(server, request, timeout)
  end

  @doc """
  Sends an asynchronous cast to a state machine.
  """
  def cast(server, request) do
    :gen_statem.cast(server, request)
  end

  @doc """
  Stops a state machine.
  """
  def stop(server, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(server, reason, timeout)
  end

  # Private helper to determine time configuration
  # Priority: explicit local options > global Process dictionary
  defp determine_time_config(nil, false) do
    # No local options - use global settings
    global_clock = Process.get(:virtual_clock)
    global_backend = Process.get(:time_backend, RealTimeBackend)
    {global_clock, global_backend}
  end

  defp determine_time_config(nil, true) do
    # Explicit real_time: true - ignore global settings
    {nil, RealTimeBackend}
  end

  defp determine_time_config(local_clock, _) when is_pid(local_clock) do
    # Explicit local clock provided - use it regardless of global settings
    {local_clock, VirtualTimeBackend}
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour :gen_statem

      {callback_mode, _opts} = Keyword.pop(opts, :callback_mode, :handle_event_function)

      @impl true
      @doc false
      def callback_mode do
        unquote(Macro.escape(callback_mode))
      end

      @impl true
      @doc false
      def init({state, data}) do
        {:ok, state, data}
      end

      @impl true
      @doc false
      def terminate(_reason, _state, _data) do
        :ok
      end

      @impl true
      @doc false
      def code_change(_old_vsn, _state, _data, _extra) do
        :undefined
      end

      # Note: child_spec should be defined by the using module if needed

      @doc """
      Sends a message to this process after a delay in milliseconds.
      Uses the appropriate backend based on the current process configuration.
      """
      def send_after_self(message, delay_ms) do
        VirtualTimeGenStateMachine.send_after(self(), message, delay_ms)
      end
    end
  end

  # Note: Users should call set_virtual_clock/1 BEFORE starting the GenStateMachine
  # Child processes will inherit the Process dictionary containing the virtual clock
end

defmodule VirtualTimeGenStateMachine.Wrapper do
  @moduledoc false
  @behaviour :gen_statem

  def callback_mode do
    # Get the original module's callback mode
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :callback_mode, 0) do
      module.callback_mode()
    else
      :handle_event_function
    end
  end

  def init({init_fun, module}) do
    # Store the module reference
    Process.put(:__vtgsm_module__, module)

    # Call the init function which injects the virtual clock
    init_fun.()
  end

  def handle_event(event_type, event_content, state, data) do
    # Handle delayed ack messages first
    case {event_type, event_content} do
      {:info, {:send_ack_to_clock, clock_pid}} ->
        # Now send the actual ack - any send_after calls have been processed
        send(clock_pid, {:actor_processed, self()})
        {:keep_state_and_data, []}

      _ ->
        # Get the original module
        module = Process.get(:__vtgsm_module__)

        result =
          if module do
            # Delegate to the original module's handle_event
            module.handle_event(event_type, event_content, state, data)
          else
            {:keep_state_and_data, []}
          end

        # Auto-send ack to VirtualClock AFTER processing event
        send_ack_to_virtual_clock()

        result
    end
  end

  # Dynamic dispatch for state functions
  def closed(event_type, event_content, data) do
    # Handle delayed ack messages first
    case {event_type, event_content} do
      {:info, {:send_ack_to_clock, clock_pid}} ->
        # Now send the actual ack - any send_after calls have been processed
        send(clock_pid, {:actor_processed, self()})
        {:keep_state_and_data, []}

      _ ->
        module = Process.get(:__vtgsm_module__)

        result =
          if module && function_exported?(module, :closed, 3) do
            module.closed(event_type, event_content, data)
          else
            {:keep_state_and_data, []}
          end

        # Auto-send ack to VirtualClock AFTER processing event
        send_ack_to_virtual_clock()

        result
    end
  end

  def open(event_type, event_content, data) do
    # Handle delayed ack messages first
    case {event_type, event_content} do
      {:info, {:send_ack_to_clock, clock_pid}} ->
        # Now send the actual ack - any send_after calls have been processed
        send(clock_pid, {:actor_processed, self()})
        {:keep_state_and_data, []}

      _ ->
        module = Process.get(:__vtgsm_module__)

        result =
          if module && function_exported?(module, :open, 3) do
            module.open(event_type, event_content, data)
          else
            {:keep_state_and_data, []}
          end

        # Auto-send ack to VirtualClock AFTER processing event
        send_ack_to_virtual_clock()

        result
    end
  end

  def locked(event_type, event_content, data) do
    # Handle delayed ack messages first
    case {event_type, event_content} do
      {:info, {:send_ack_to_clock, clock_pid}} ->
        # Now send the actual ack - any send_after calls have been processed
        send(clock_pid, {:actor_processed, self()})
        {:keep_state_and_data, []}

      _ ->
        module = Process.get(:__vtgsm_module__)

        result =
          if module && function_exported?(module, :locked, 3) do
            module.locked(event_type, event_content, data)
          else
            {:keep_state_and_data, []}
          end

        # Auto-send ack to VirtualClock AFTER processing event
        send_ack_to_virtual_clock()

        result
    end
  end

  def waiting(event_type, event_content, data) do
    # Handle delayed ack messages first
    case {event_type, event_content} do
      {:info, {:send_ack_to_clock, clock_pid}} ->
        # Now send the actual ack - any send_after calls have been processed
        send(clock_pid, {:actor_processed, self()})
        {:keep_state_and_data, []}

      _ ->
        module = Process.get(:__vtgsm_module__)

        result =
          if module && function_exported?(module, :waiting, 3) do
            module.waiting(event_type, event_content, data)
          else
            {:keep_state_and_data, []}
          end

        # Auto-send ack to VirtualClock AFTER processing event
        send_ack_to_virtual_clock()

        result
    end
  end

  def working(event_type, event_content, data) do
    # Handle delayed ack messages first
    case {event_type, event_content} do
      {:info, {:send_ack_to_clock, clock_pid}} ->
        # Now send the actual ack - any send_after calls have been processed
        send(clock_pid, {:actor_processed, self()})
        {:keep_state_and_data, []}

      _ ->
        module = Process.get(:__vtgsm_module__)

        result =
          if module && function_exported?(module, :working, 3) do
            module.working(event_type, event_content, data)
          else
            {:keep_state_and_data, []}
          end

        # Auto-send ack to VirtualClock AFTER processing event
        send_ack_to_virtual_clock()

        result
    end
  end

  def aborting(event_type, event_content, data) do
    # Handle delayed ack messages first
    case {event_type, event_content} do
      {:info, {:send_ack_to_clock, clock_pid}} ->
        # Now send the actual ack - any send_after calls have been processed
        send(clock_pid, {:actor_processed, self()})
        {:keep_state_and_data, []}

      _ ->
        module = Process.get(:__vtgsm_module__)

        result =
          if module && function_exported?(module, :aborting, 3) do
            module.aborting(event_type, event_content, data)
          else
            {:keep_state_and_data, []}
          end

        # Auto-send ack to VirtualClock AFTER processing event
        send_ack_to_virtual_clock()

        result
    end
  end

  def idle(event_type, event_content, data) do
    # Handle delayed ack messages first
    case {event_type, event_content} do
      {:info, {:send_ack_to_clock, clock_pid}} ->
        # Now send the actual ack - any send_after calls have been processed
        send(clock_pid, {:actor_processed, self()})
        {:keep_state_and_data, []}

      _ ->
        module = Process.get(:__vtgsm_module__)

        result =
          if module && function_exported?(module, :idle, 3) do
            module.idle(event_type, event_content, data)
          else
            {:keep_state_and_data, []}
          end

        # Auto-send ack to VirtualClock AFTER processing event
        send_ack_to_virtual_clock()

        result
    end
  end

  def active(event_type, event_content, data) do
    # Handle delayed ack messages first
    case {event_type, event_content} do
      {:info, {:send_ack_to_clock, clock_pid}} ->
        # Now send the actual ack - any send_after calls have been processed
        send(clock_pid, {:actor_processed, self()})
        {:keep_state_and_data, []}

      _ ->
        module = Process.get(:__vtgsm_module__)

        result =
          if module && function_exported?(module, :active, 3) do
            module.active(event_type, event_content, data)
          else
            {:keep_state_and_data, []}
          end

        # Auto-send ack to VirtualClock AFTER processing event
        send_ack_to_virtual_clock()

        result
    end
  end

  def terminate(reason, state, data) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :terminate, 3) do
      module.terminate(reason, state, data)
    else
      :ok
    end
  end

  def code_change(old_vsn, state, data, extra) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :code_change, 4) do
      module.code_change(old_vsn, state, data, extra)
    else
      {:ok, state, data}
    end
  end

  # Send acknowledgment to VirtualClock that this actor finished processing
  defp send_ack_to_virtual_clock do
    # Only send ack if we're using virtual time (not real time)
    case Process.get(:virtual_clock) do
      # Real time mode - no ack needed
      nil ->
        :ok

      clock_pid when is_pid(clock_pid) ->
        # Send ack asynchronously AFTER any send_after calls in event handler
        # This ensures the actor has completed all scheduling before we ack
        send(self(), {:send_ack_to_clock, clock_pid})
        :ok
    end
  end
end
