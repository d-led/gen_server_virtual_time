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

  @doc """
  Sets the virtual clock for the current process.
  All child processes will inherit this setting.
  """
  def set_virtual_clock(clock) do
    Process.put(:virtual_clock, clock)
    Process.put(:time_backend, VirtualTimeBackend)
  end

  @doc """
  Uses real time (default behavior).
  """
  def use_real_time do
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
  Sends a message to a process after a delay (in milliseconds).
  Uses the appropriate backend based on the current process configuration.
  """
  def send_after(dest, message, delay) do
    backend = get_time_backend()
    backend.send_after(dest, message, delay)
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
  Sleeps for the specified duration (in milliseconds).
  Uses the appropriate backend based on the current process configuration.
  """
  def sleep(duration) do
    backend = get_time_backend()
    backend.sleep(duration)
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
      case module.init(init_arg) do
        {:ok, state, data} -> {:ok, state, data}
        {:ok, state, data, timeout} -> {:ok, state, data, timeout}
        {:ok, state, data, {:continue, arg}} -> {:ok, state, data, {:continue, arg}}
        other -> other
      end
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

      unless Module.get_attribute(__MODULE__, :doc) do
        @doc """
        Returns a specification to start this module under a supervisor.
        """
        def child_spec(init_arg) do
          %{
            id: __MODULE__,
            start: {__MODULE__, :start_link, [init_arg]},
            type: :worker,
            restart: :permanent,
            shutdown: 5000,
            modules: [__MODULE__]
          }
        end
      end

      @doc """
      Sends a message to this process after a delay.
      Uses the appropriate backend based on the current process configuration.
      """
      def send_after_self(message, delay) do
        VirtualTimeGenStateMachine.send_after(self(), message, delay)
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
    case init_fun.() do
      {:ok, state, data} -> {:ok, state, data}
      {:ok, state, data, timeout} -> {:ok, state, data, timeout}
      {:ok, state, data, {:continue, arg}} -> {:ok, state, data, {:continue, arg}}
      other -> other
    end
  end

  def handle_event(event_type, event_content, state, data) do
    # Get the original module
    module = Process.get(:__vtgsm_module__)

    if module do
      # Delegate to the original module's handle_event
      module.handle_event(event_type, event_content, state, data)
    else
      {:keep_state_and_data, []}
    end
  end

  # Dynamic dispatch for state functions
  def closed(event_type, event_content, data) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :closed, 3) do
      module.closed(event_type, event_content, data)
    else
      {:keep_state_and_data, []}
    end
  end

  def open(event_type, event_content, data) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :open, 3) do
      module.open(event_type, event_content, data)
    else
      {:keep_state_and_data, []}
    end
  end

  def locked(event_type, event_content, data) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :locked, 3) do
      module.locked(event_type, event_content, data)
    else
      {:keep_state_and_data, []}
    end
  end

  def waiting(event_type, event_content, data) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :waiting, 3) do
      module.waiting(event_type, event_content, data)
    else
      {:keep_state_and_data, []}
    end
  end

  def working(event_type, event_content, data) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :working, 3) do
      module.working(event_type, event_content, data)
    else
      {:keep_state_and_data, []}
    end
  end

  def aborting(event_type, event_content, data) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :aborting, 3) do
      module.aborting(event_type, event_content, data)
    else
      {:keep_state_and_data, []}
    end
  end

  def idle(event_type, event_content, data) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :idle, 3) do
      module.idle(event_type, event_content, data)
    else
      {:keep_state_and_data, []}
    end
  end

  def active(event_type, event_content, data) do
    module = Process.get(:__vtgsm_module__)

    if module && function_exported?(module, :active, 3) do
      module.active(event_type, event_content, data)
    else
      {:keep_state_and_data, []}
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
end
