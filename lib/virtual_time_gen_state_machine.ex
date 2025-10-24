defmodule VirtualTimeGenStateMachine do
  @moduledoc """
  A behavior module for GenStateMachine with virtual time support.

  This module wraps GenStateMachine and provides a `send_after/3` function that can
  work with either real time (production) or virtual time (testing).

  ## Example

      defmodule MyStateMachine do
        use VirtualTimeGenStateMachine, callback_mode: :handle_event_function

        def start_link(opts) do
          VirtualTimeGenStateMachine.start_link(__MODULE__, :off, opts)
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
