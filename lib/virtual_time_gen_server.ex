defmodule VirtualTimeGenServer.Wrapper do
  @moduledoc false
  use GenServer

  def init({init_fun, module}) do
    case init_fun.() do
      {:ok, {^module, state}} -> {:ok, {module, state}}
      {:ok, {^module, state}, timeout} -> {:ok, {module, state}, timeout}
      {:ok, {^module, state}, {:continue, arg}} -> {:ok, {module, state}, {:continue, arg}}
      other -> other
    end
  end

  def handle_call(request, from, {module, state}) do
    # Handle internal requests
    case request do
      :__vtgs_get_stats__ ->
        stats = VirtualTimeGenServer.get_process_stats()
        {:reply, stats, {module, state}}

      _ ->
        # Track incoming call only if stats tracking is enabled (in simulations)
        if Process.get(:__vtgs_stats_enabled__) do
          track_received_message(request, :call)
          # Generate trace event for incoming message
          VirtualTimeGenServer.generate_incoming_trace_event(request, :call)
        end

        case module.handle_call(request, from, state) do
          {:reply, reply, new_state} -> {:reply, reply, {module, new_state}}
          {:reply, reply, new_state, timeout} -> {:reply, reply, {module, new_state}, timeout}
          {:noreply, new_state} -> {:noreply, {module, new_state}}
          {:noreply, new_state, timeout} -> {:noreply, {module, new_state}, timeout}
          {:stop, reason, reply, new_state} -> {:stop, reason, reply, {module, new_state}}
          {:stop, reason, new_state} -> {:stop, reason, {module, new_state}}
        end
    end
  end

  def handle_cast(request, {module, state}) do
    # Track incoming cast only if stats tracking is enabled (in simulations)
    if Process.get(:__vtgs_stats_enabled__) do
      track_received_message(request, :cast)
      # Generate trace event for incoming message
      VirtualTimeGenServer.generate_incoming_trace_event(request, :cast)
    end

    case module.handle_cast(request, state) do
      {:noreply, new_state} -> {:noreply, {module, new_state}}
      {:noreply, new_state, timeout} -> {:noreply, {module, new_state}, timeout}
      {:stop, reason, new_state} -> {:stop, reason, {module, new_state}}
    end
  end

  def handle_info(msg, {module, state}) do
    case module.handle_info(msg, state) do
      {:noreply, new_state} -> {:noreply, {module, new_state}}
      {:noreply, new_state, {:continue, arg}} -> {:noreply, {module, new_state}, {:continue, arg}}
      {:noreply, new_state, timeout} -> {:noreply, {module, new_state}, timeout}
      {:stop, reason, new_state} -> {:stop, reason, {module, new_state}}
    end
  end

  def handle_continue(arg, {module, state}) do
    if function_exported?(module, :handle_continue, 2) do
      case module.handle_continue(arg, state) do
        {:noreply, new_state} ->
          {:noreply, {module, new_state}}

        {:noreply, new_state, {:continue, next_arg}} ->
          {:noreply, {module, new_state}, {:continue, next_arg}}

        {:noreply, new_state, timeout} ->
          {:noreply, {module, new_state}, timeout}

        {:stop, reason, new_state} ->
          {:stop, reason, {module, new_state}}
      end
    else
      # Module doesn't implement handle_continue, just continue with no-op
      {:noreply, {module, state}}
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

  # Message tracking helpers (only used in simulations)
  defp track_received_message(message, _type) do
    # Skip internal messages
    case message do
      :get_stats ->
        :ok

      :__vtgs_get_stats__ ->
        :ok

      {:start_sending, _, _} ->
        :ok

      # Skip internal scheduled messages
      :send_random_message ->
        :ok

      _ ->
        # Only track if stats are enabled (in simulations)
        if Process.get(:__vtgs_stats_enabled__) do
          stats = Process.get(:__vtgs_stats__, %{sent_count: 0, received_count: 0})
          new_stats = %{stats | received_count: stats.received_count + 1}
          Process.put(:__vtgs_stats__, new_stats)
        end
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

  ## Testing with Virtual Time - Global Clock (Coordinated Simulation)

      test "server ticks correctly" do
        {:ok, clock} = VirtualClock.start_link()
        VirtualTimeGenServer.set_virtual_clock(clock)

        {:ok, server} = MyTimedServer.start_link([])

        # Advance virtual time by 5 seconds
        VirtualClock.advance(clock, 5000)

        # Server will have ticked 5 times
        assert get_count(server) == 5
      end

  ## Testing with Virtual Time - Local Clock (Isolated Simulation)

      test "isolated simulation with local clock" do
        {:ok, clock} = VirtualClock.start_link()

        # Pass clock directly to this specific server
        {:ok, server} = VirtualTimeGenServer.start_link(MyTimedServer, :ok, virtual_clock: clock)

        # Advance only this server's timeline
        VirtualClock.advance(clock, 5000)

        assert get_count(server) == 5
      end

  ## Clock Configuration Options

  The virtual clock can be configured in three ways (in priority order):

  1. **Local Clock Injection** - Pass `virtual_clock: clock_pid` to `start_link/3`:
     - Highest priority, overrides global settings
     - Useful for isolated simulations or testing components independently
     - Each server can have its own timeline

  2. **Global Clock** - Use `set_virtual_clock/1`:
     - Inherited by all child processes
     - Essential for coordinated actor systems where timing relationships matter
     - All actors share the same timeline

  3. **Real Time** - Pass `real_time: true` or use `use_real_time/0`:
     - Default behavior, uses `Process.send_after/3`
     - For production or integration tests with external systems

  See the "Development Documentation" for a detailed explanation of when to use
  global vs local clocks.
  """

  @doc """
  Sets the virtual clock for the current process.
  All child processes will inherit this setting.

  ## Example

      iex> {:ok, clock} = VirtualClock.start_link()
      iex> VirtualTimeGenServer.set_virtual_clock(clock)
      VirtualTimeBackend
      iex> VirtualTimeGenServer.get_time_backend()
      VirtualTimeBackend

  """
  def set_virtual_clock(clock) do
    # Get caller information from stacktrace
    caller_info = get_caller_info()

    # Emit a compilation warning to alert users about potential race conditions
    IO.warn(
      """
      ⚠️  GLOBAL VIRTUAL CLOCK INJECTION DETECTED ⚠️

      VirtualTimeGenServer.set_virtual_clock/1 sets a GLOBAL virtual clock that affects
      ALL child processes. This can cause race conditions in tests and production!

      Consider using test-local virtual clocks instead:

      # ❌ Global (can cause race conditions)
      VirtualTimeGenServer.set_virtual_clock(clock)
      {:ok, server} = MyServer.start_link([])

      # ✅ Test-local (isolated, safe)
      {:ok, server} = MyServer.start_link([], virtual_clock: clock)

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
      iex> VirtualTimeGenServer.set_virtual_clock(clock, :i_know_what_i_am_doing, "coordinated simulation")
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

      VirtualTimeGenServer.use_real_time/0 changes the GLOBAL time backend for
      ALL child processes. This can cause race conditions in tests and production!

      Consider using test-local time backend instead:

      # ❌ Global (can cause race conditions)
      VirtualTimeGenServer.use_real_time()
      {:ok, server} = MyServer.start_link([])

      # ✅ Test-local (isolated, safe)
      {:ok, server} = MyServer.start_link([], real_time: true)

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

      iex> VirtualTimeGenServer.use_real_time(:i_know_what_i_am_doing, "production mode")
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
  Sets a GLOBAL trace collector for all child processes.

  ⚠️  WARNING: This can cause race conditions in tests and production!

  Consider using test-local trace injection instead:

  ```elixir
  # ❌ Global (can cause race conditions)
  VirtualTimeGenServer.set_global_trace_collector(collector_pid)
  {:ok, server} = MyServer.start_link([])

  # ✅ Test-local (isolated, safe)
  {:ok, server} = MyServer.start_link([], trace_collector: collector_pid)
  ```

  For coordinated tracing, use global collectors intentionally.
  For isolated testing, use test-local trace injection.
  """
  def set_global_trace_collector(collector_pid) do
    # Get caller information from stacktrace
    caller_info = get_caller_info()

    # Emit a compilation warning to alert users about potential race conditions
    IO.warn(
      """
      ⚠️  GLOBAL TRACE COLLECTOR INJECTION DETECTED ⚠️

      VirtualTimeGenServer.set_global_trace_collector/1 sets a GLOBAL trace collector that affects
      ALL child processes. This can cause race conditions in tests and production!

      Consider using test-local trace collectors instead:

      # ❌ Global (can cause race conditions)
      VirtualTimeGenServer.set_global_trace_collector(collector_pid)
      {:ok, server} = MyServer.start_link([])

      # ✅ Test-local (isolated, safe)
      {:ok, server} = MyServer.start_link([], trace_collector: collector_pid)

      For coordinated tracing, use global collectors intentionally.
      For isolated testing, use test-local trace collectors.
      """,
      caller_info
    )

    Process.put(:global_trace_collector, collector_pid)
  end

  @doc """
  Warning-free version of set_global_trace_collector/1 for intentional global usage.
  """
  def set_global_trace_collector(collector_pid, :i_know_what_i_am_doing, explanation)
      when is_binary(explanation) do
    Process.put(:global_trace_collector, collector_pid)
  end

  @doc """
  Gets the current global trace collector.
  """
  def get_global_trace_collector do
    Process.get(:global_trace_collector)
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
  Sends a message immediately in virtual time.

  With virtual time, this schedules the message for the current virtual time,
  ensuring it gets processed in the next event cycle.
  With real time, this sends the message immediately.

  This is useful for triggering immediate responses or state changes
  within the virtual time simulation.

  ## Examples

      # Send immediate message to self
      VirtualTimeGenServer.send_immediately(self(), :process_now)

      # Send immediate message to another process
      VirtualTimeGenServer.send_immediately(other_pid, {:urgent, data})
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
  Sleeps for the specified duration (in milliseconds).

  With virtual time, this advances the actor's position in the timeline without
  consuming real time. With real time, this blocks using Process.sleep/1.

  This is useful for simulating work or processing delays within actors.

  ## Examples

      # In a GenServer callback - simulate 100ms of processing time
      def handle_call(:compute, _from, state) do
        VirtualTimeGenServer.sleep(100)  # Simulated work
        {:reply, :done, state}
      end

      # With virtual time: returns instantly but advances virtual clock
      # With real time: blocks for 100ms
  """
  def sleep(duration) do
    backend = get_time_backend()
    backend.sleep(duration)
  end

  defmacro __using__(_opts) do
    quote do
      use GenServer

      @doc """
      Sends a message to this process after a delay.
      Uses the appropriate backend based on the current process configuration.
      """
      def send_after_self(message, delay) do
        VirtualTimeGenServer.send_after(self(), message, delay)
      end
    end
  end

  # Custom start_link that propagates virtual clock to child process
  def start_link(module, init_arg, opts \\ []) do
    # Extract time-related options from opts
    {virtual_clock, opts} = Keyword.pop(opts, :virtual_clock)
    {real_time, opts} = Keyword.pop(opts, :real_time, false)

    # Determine which clock and backend to use
    # Priority: local options > global Process dictionary
    {final_clock, final_backend} = determine_time_config(virtual_clock, real_time)

    # Get stats tracking flag from parent process
    stats_enabled = Process.get(:__vtgs_stats_enabled__, false)

    # Use a wrapper to inject virtual clock into spawned process
    init_fun = fn ->
      if final_clock do
        Process.put(:virtual_clock, final_clock)
      end

      Process.put(:time_backend, final_backend)

      # Propagate stats tracking to child process
      if stats_enabled do
        Process.put(:__vtgs_stats_enabled__, true)
        Process.put(:__vtgs_stats__, %{sent_count: 0, received_count: 0})
      end

      case module.init(init_arg) do
        {:ok, state} -> {:ok, {module, state}}
        {:ok, state, {:continue, arg}} -> {:ok, {module, state}, {:continue, arg}}
        {:ok, state, timeout} -> {:ok, {module, state}, timeout}
        :ignore -> :ignore
        {:stop, reason} -> {:stop, reason}
      end
    end

    # Start with wrapper module
    case GenServer.start_link(VirtualTimeGenServer.Wrapper, {init_fun, module}, opts) do
      {:ok, pid} -> {:ok, pid}
      error -> error
    end
  end

  def start(module, init_arg, opts \\ []) do
    # Extract time-related options from opts
    {virtual_clock, opts} = Keyword.pop(opts, :virtual_clock)
    {real_time, opts} = Keyword.pop(opts, :real_time, false)

    # Determine which clock and backend to use
    {final_clock, final_backend} = determine_time_config(virtual_clock, real_time)

    # Get stats tracking flag from parent process
    stats_enabled = Process.get(:__vtgs_stats_enabled__, false)

    init_fun = fn ->
      if final_clock do
        Process.put(:virtual_clock, final_clock)
      end

      Process.put(:time_backend, final_backend)

      # Propagate stats tracking to child process
      if stats_enabled do
        Process.put(:__vtgs_stats_enabled__, true)
        Process.put(:__vtgs_stats__, %{sent_count: 0, received_count: 0})
      end

      case module.init(init_arg) do
        {:ok, state} -> {:ok, {module, state}}
        {:ok, state, {:continue, arg}} -> {:ok, {module, state}, {:continue, arg}}
        {:ok, state, timeout} -> {:ok, {module, state}, timeout}
        :ignore -> :ignore
        {:stop, reason} -> {:stop, reason}
      end
    end

    GenServer.start(VirtualTimeGenServer.Wrapper, {init_fun, module}, opts)
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

  @doc """
  Makes a synchronous call to a server.

  When stats tracking is enabled (in simulations), this tracks the sent message.
  Otherwise, it's a direct passthrough to GenServer.call with zero overhead.
  """
  def call(server, request, timeout \\ 5000) do
    # Only track if explicitly enabled - zero overhead otherwise
    if Process.get(:__vtgs_stats_enabled__) do
      track_sent_message(request, :call)
    end

    GenServer.call(server, request, timeout)
  end

  @doc """
  Sends an asynchronous request to a server.

  When stats tracking is enabled (in simulations), this tracks the sent message.
  Otherwise, it's a direct passthrough to GenServer.cast with zero overhead.
  """
  def cast(server, request) do
    # Only track if explicitly enabled - zero overhead otherwise
    if Process.get(:__vtgs_stats_enabled__) do
      track_sent_message(request, :cast)
    end

    GenServer.cast(server, request)
  end

  defdelegate stop(server, reason \\ :normal, timeout \\ :infinity), to: GenServer

  # Message tracking helpers (only used in simulations)
  defp track_sent_message(message, _type) do
    # Skip internal messages
    case message do
      :get_stats ->
        :ok

      :__vtgs_get_stats__ ->
        :ok

      {:start_sending, _, _} ->
        :ok

      _ ->
        stats = Process.get(:__vtgs_stats__, %{sent_count: 0, received_count: 0})
        new_stats = %{stats | sent_count: stats.sent_count + 1}
        Process.put(:__vtgs_stats__, new_stats)
    end
  end

  @doc false
  # Internal API for ActorSimulation to enable stats tracking
  def enable_stats_tracking do
    Process.put(:__vtgs_stats_enabled__, true)
    Process.put(:__vtgs_stats__, %{sent_count: 0, received_count: 0})
  end

  @doc false
  # Generate trace events for incoming messages (only used in simulations)
  def generate_incoming_trace_event(message, type) do
    # Skip internal messages
    case message do
      :get_stats -> :ok
      :__vtgs_get_stats__ -> :ok
      {:start_sending, _, _} -> :ok
      _ -> send_incoming_trace_event(message, type)
    end
  end

  defp send_incoming_trace_event(message, type) do
    case Process.whereis(:trace_collector) do
      nil ->
        :ok

      pid ->
        # Get actor name from process context
        actor_name = Process.get(:__vtgs_actor_name__)

        if actor_name do
          # For incoming messages, we don't know the sender, so we use a generic source
          # The diagram generator can infer connections from the message patterns
          VirtualTimeGenServer.send_immediately(pid, {:trace,
           %{
             timestamp: VirtualClock.now(Process.get(:virtual_clock)),
             # We don't know the sender for incoming messages
             from: :unknown,
             to: actor_name,
             message: message,
             type: type
           }})
        end
    end
  end

  @doc false
  # Internal API for ActorSimulation to get process stats
  def get_process_stats do
    stats = Process.get(:__vtgs_stats__, %{sent_count: 0, received_count: 0})

    %{
      sent_count: stats.sent_count,
      received_count: stats.received_count,
      sent_messages: [],
      received_messages: []
    }
  end

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
end
