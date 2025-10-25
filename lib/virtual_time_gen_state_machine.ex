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
  Sends a message after a delay using the configured time backend.
  """
  def send_after(dest, message, delay) do
    backend = get_time_backend()
    backend.send_after(dest, message, delay)
  end

  @doc """
  Cancels a timer created with send_after/3.
  """
  def cancel_timer(ref) do
    backend = get_time_backend()
    backend.cancel_timer(ref)
  end

  @doc """
  Sleeps for the specified duration (in milliseconds).
  """
  def sleep(duration) do
    backend = get_time_backend()
    backend.sleep(duration)
  end

  @doc """
  Starts a GenStateMachine with virtual time support.

  This function injects the virtual clock into the spawned process,
  similar to VirtualTimeGenServer.start_link/3.
  """
  def start_link(module, init_arg, opts \\ []) do
    # Extract time-related options from opts
    {virtual_clock, opts} = Keyword.pop(opts, :virtual_clock)
    {real_time, opts} = Keyword.pop(opts, :real_time, false)

    # Determine which clock and backend to use
    # Priority: local options > global Process dictionary
    {final_clock, final_backend} = determine_time_config(virtual_clock, real_time)

    # Set virtual clock in current process before starting
    if final_clock do
      Process.put(:virtual_clock, final_clock)
    end

    Process.put(:time_backend, final_backend)

    # Start with the original module
    GenStateMachine.start_link(module, init_arg, opts)
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

    # Start with the original module
    GenStateMachine.start(module, init_arg, opts)
  end

  @doc """
  Makes a synchronous call to a state machine.
  """
  def call(server, request, timeout \\ 5000) do
    GenStateMachine.call(server, request, timeout)
  end

  @doc """
  Sends an asynchronous cast to a state machine.
  """
  def cast(server, request) do
    GenStateMachine.cast(server, request)
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
    quote do
      use GenStateMachine, unquote(opts)

      @doc """
      Sends a message to this process after a delay.
      Works with both real and virtual time.
      """
      def send_after_self(message, delay) do
        VirtualTimeGenStateMachine.send_after(self(), message, delay)
      end
    end
  end

  # Note: Users should call set_virtual_clock/1 BEFORE starting the GenStateMachine
  # Child processes will inherit the Process dictionary containing the virtual clock
end
