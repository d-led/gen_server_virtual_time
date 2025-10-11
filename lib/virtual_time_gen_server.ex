defmodule VirtualTimeGenServer.Wrapper do
  @moduledoc false
  use GenServer

  def init({init_fun, module}) do
    case init_fun.() do
      {:ok, {^module, state}} -> {:ok, {module, state}}
      {:ok, {^module, state}, timeout} -> {:ok, {module, state}, timeout}
      other -> other
    end
  end

  def handle_call(request, from, {module, state}) do
    case module.handle_call(request, from, state) do
      {:reply, reply, new_state} -> {:reply, reply, {module, new_state}}
      {:reply, reply, new_state, timeout} -> {:reply, reply, {module, new_state}, timeout}
      {:noreply, new_state} -> {:noreply, {module, new_state}}
      {:noreply, new_state, timeout} -> {:noreply, {module, new_state}, timeout}
      {:stop, reason, reply, new_state} -> {:stop, reason, reply, {module, new_state}}
      {:stop, reason, new_state} -> {:stop, reason, {module, new_state}}
    end
  end

  def handle_cast(request, {module, state}) do
    case module.handle_cast(request, state) do
      {:noreply, new_state} -> {:noreply, {module, new_state}}
      {:noreply, new_state, timeout} -> {:noreply, {module, new_state}, timeout}
      {:stop, reason, new_state} -> {:stop, reason, {module, new_state}}
    end
  end

  def handle_info(msg, {module, state}) do
    case module.handle_info(msg, state) do
      {:noreply, new_state} -> {:noreply, {module, new_state}}
      {:noreply, new_state, timeout} -> {:noreply, {module, new_state}, timeout}
      {:stop, reason, new_state} -> {:stop, reason, {module, new_state}}
    end
  end

  def terminate(reason, {module, state}) do
    if function_exported?(module, :terminate, 2) do
      module.terminate(reason, state)
    else
      :ok
    end
  end

  def code_change(old_vsn, {module, state}, extra) do
    if function_exported?(module, :code_change, 3) do
      case module.code_change(old_vsn, state, extra) do
        {:ok, new_state} -> {:ok, {module, new_state}}
        other -> other
      end
    else
      {:ok, {module, state}}
    end
  end
end

defmodule VirtualTimeGenServer do
  @moduledoc """
  A behavior module for GenServers with virtual time support.

  This module wraps GenServer and provides a `send_after/3` function that can
  work with either real time (production) or virtual time (testing).

  ## Example

      defmodule MyTimedServer do
        use VirtualTimeGenServer

        def start_link(opts) do
          VirtualTimeGenServer.start_link(__MODULE__, :ok, opts)
        end

        @impl true
        def init(:ok) do
          # Schedule a tick every 1000ms
          schedule_tick()
          {:ok, %{count: 0}}
        end

        @impl true
        def handle_info(:tick, state) do
          new_count = state.count + 1
          schedule_tick()
          {:noreply, %{state | count: new_count}}
        end

        defp schedule_tick do
          VirtualTimeGenServer.send_after(self(), :tick, 1000)
        end
      end

  ## Testing with Virtual Time

      test "server ticks correctly" do
        {:ok, clock} = VirtualClock.start_link()
        VirtualTimeGenServer.set_virtual_clock(clock)

        {:ok, server} = MyTimedServer.start_link([])

        # Advance virtual time by 5 seconds
        VirtualClock.advance(clock, 5000)

        # Server will have ticked 5 times
        assert get_count(server) == 5
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

  defmacro __using__(_opts) do
    quote do
      use GenServer

      @doc """
      Sends a message to this process after a delay.
      Works with both real and virtual time.
      """
      def send_after_self(message, delay) do
        VirtualTimeGenServer.send_after(self(), message, delay)
      end
    end
  end

  # Custom start_link that propagates virtual clock to child process
  def start_link(module, init_arg, opts \\ []) do
    virtual_clock = Process.get(:virtual_clock)
    time_backend = Process.get(:time_backend, RealTimeBackend)

    # Use a wrapper to inject virtual clock into spawned process
    init_fun = fn ->
      if virtual_clock do
        Process.put(:virtual_clock, virtual_clock)
      end
      Process.put(:time_backend, time_backend)

      case module.init(init_arg) do
        {:ok, state} -> {:ok, {module, state}}
        {:ok, state, timeout} -> {:ok, {module, state}, timeout}
        :ignore -> :ignore
        {:stop, reason} -> {:stop, reason}
      end
    end

    # Start with wrapper module
    GenServer.start_link(VirtualTimeGenServer.Wrapper, {init_fun, module}, opts)
  end

  def start(module, init_arg, opts \\ []) do
    virtual_clock = Process.get(:virtual_clock)
    time_backend = Process.get(:time_backend, RealTimeBackend)

    init_fun = fn ->
      if virtual_clock do
        Process.put(:virtual_clock, virtual_clock)
      end
      Process.put(:time_backend, time_backend)

      case module.init(init_arg) do
        {:ok, state} -> {:ok, {module, state}}
        {:ok, state, timeout} -> {:ok, {module, state}, timeout}
        :ignore -> :ignore
        {:stop, reason} -> {:stop, reason}
      end
    end

    GenServer.start(VirtualTimeGenServer.Wrapper, {init_fun, module}, opts)
  end

  defdelegate call(server, request, timeout \\ 5000), to: GenServer
  defdelegate cast(server, request), to: GenServer
  defdelegate stop(server, reason \\ :normal, timeout \\ :infinity), to: GenServer
end
