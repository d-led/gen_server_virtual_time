defmodule VirtualTimeGenServer.Wrapper do
  @moduledoc false
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct [:module, :module_state, :instrumentation]

    def new(module, module_state, instrumentation) do
      %__MODULE__{module: module, module_state: module_state, instrumentation: instrumentation}
    end
  end

  # The library's own query. It is deliberately not reported to the observer:
  # an observer sees the traffic of the observed code, not of the library.
  @snapshot_request :__virtual_time_gen_server_snapshot__

  @impl true
  def init({init_fun, module, instrumentation}) do
    case init_fun.() do
      {:ok, module_state} ->
        {:ok, State.new(module, module_state, instrumentation)}

      {:ok, module_state, action} ->
        {:ok, State.new(module, module_state, instrumentation), action}

      other ->
        other
    end
  end

  @impl true
  def handle_call(@snapshot_request, _from, %State{instrumentation: nil} = state) do
    {:reply, {:error, :not_instrumented}, state}
  end

  def handle_call(@snapshot_request, _from, %State{} = state) do
    {:reply, {:ok, snapshot(state)}, state}
  end

  def handle_call(request, from, %State{} = state) do
    observe_receive(state, {:call, request})
    reply(state, state.module.handle_call(request, from, state.module_state))
  end

  @impl true
  def handle_cast(request, %State{} = state) do
    observe_receive(state, {:cast, request})
    noreply(state, state.module.handle_cast(request, state.module_state))
  end

  # A delivery from the VirtualClock. The token identifies this exact delivery;
  # acknowledging it is what lets the clock move past the event's timestamp.
  @impl true
  def handle_info({:__vtgs_delivered__, token, message}, %State{} = state) do
    observe_receive(state, {:info, message})
    result = noreply(state, state.module.handle_info(message, state.module_state))
    send_ack_to_virtual_clock(token)
    result
  end

  # Anything else an actor receives (calls, casts, messages from other actors)
  # is not a clock delivery, so it must not be acknowledged - an acknowledgement
  # here would let the clock advance while the delivered event is still queued.
  def handle_info(message, %State{} = state) do
    observe_receive(state, {:info, message})
    noreply(state, state.module.handle_info(message, state.module_state))
  end

  @impl true
  def handle_continue(arg, %State{} = state) do
    if function_exported?(state.module, :handle_continue, 2) do
      noreply(state, state.module.handle_continue(arg, state.module_state))
    else
      {:noreply, state}
    end
  end

  @impl true
  def terminate(reason, %State{module: module, module_state: module_state}) do
    if function_exported?(module, :terminate, 2) do
      module.terminate(reason, module_state)
    else
      :ok
    end
  end

  @impl true
  def code_change(old_vsn, %State{} = state, extra) do
    if function_exported?(state.module, :code_change, 3) do
      case state.module.code_change(old_vsn, state.module_state, extra) do
        {:ok, module_state} -> {:ok, keep(state, module_state)}
        other -> other
      end
    else
      {:ok, state}
    end
  end

  @doc false
  def snapshot_request, do: @snapshot_request

  # Re-wraps what the observed module returned for a call, keeping the observed
  # state next to the observer's configuration.
  defp reply(state, result) do
    case result do
      {:reply, reply, module_state} ->
        {:reply, reply, keep(state, module_state)}

      {:reply, reply, module_state, action} ->
        {:reply, reply, keep(state, module_state), action}

      {:noreply, module_state} ->
        {:noreply, keep(state, module_state)}

      {:noreply, module_state, action} ->
        {:noreply, keep(state, module_state), action}

      {:stop, reason, reply, module_state} ->
        {:stop, reason, reply, keep(state, module_state)}

      {:stop, reason, module_state} ->
        {:stop, reason, keep(state, module_state)}
    end
  end

  defp noreply(state, result) do
    case result do
      {:noreply, module_state} ->
        {:noreply, keep(state, module_state)}

      {:noreply, module_state, action} ->
        {:noreply, keep(state, module_state), action}

      {:stop, reason, module_state} ->
        {:stop, reason, keep(state, module_state)}
    end
  end

  defp keep(state, module_state), do: %{state | module_state: module_state}

  defp observe_receive(%State{instrumentation: nil}, _event), do: :ok

  defp observe_receive(%State{instrumentation: {observer, context}} = state, event) do
    observer.on_receive(event, %{module: state.module, server: self(), context: context})
  end

  defp snapshot(%State{instrumentation: {observer, context}}), do: observer.snapshot(context)

  # Send acknowledgment to VirtualClock that this actor finished processing
  defp send_ack_to_virtual_clock(token) do
    # Only send ack if we're using virtual time (not real time)
    case Process.get(:virtual_clock) do
      clock_pid when is_pid(clock_pid) ->
        send(clock_pid, {:actor_processed, self(), token})

      _ ->
        :ok
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

  ## Observing a server

  Counting messages, tracing them or drawing diagrams of them is a different
  concern from controlling time, so this library does none of it. It offers a
  port instead: a module implementing `VirtualTimeGenServer.Instrumentation`
  sees every message a server receives and sends, and `snapshot/1` asks it what
  it collected.
  """

  alias VirtualTimeGenServer.Instrumentation

  @instrumentation_key :virtual_time_gen_server_instrumentation

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
  Instruments the calling process with `instrumentation`.

  Every message the calling process sends through `call/3` or `cast/2` is then
  reported to the observer's `on_send/2` callback. Starting a server with the
  `:instrumentation` option instruments that server in the same way, so a server
  reports both what it sends and what it receives.

  `instrumentation` is a module implementing `VirtualTimeGenServer.Instrumentation`,
  or `{module, context}` when the callbacks need context. Pass `nil` to stop
  observing.

  ## Example

      defmodule MyServer do
        use VirtualTimeGenServer
        # ...
      end

      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.instrument({MessageCounter, %{label: :test}})

      {:ok, server} =
        VirtualTimeGenServer.start_link(MyServer, :ok, virtual_clock: clock)

      VirtualTimeGenServer.call(server, :ping)
  """
  @spec instrument(VirtualTimeGenServer.Instrumentation.t()) :: :ok
  def instrument(instrumentation) do
    case Instrumentation.normalize(instrumentation) do
      nil ->
        Process.delete(@instrumentation_key)
        :ok

      normalized ->
        Process.put(@instrumentation_key, normalized)
        :ok
    end
  end

  @doc """
  Asks an instrumented server what its observer collected.

  The observer's `snapshot/1` runs in the server process, so it can read state
  the observer keeps there. The result is the observer's own term, handed back
  unchanged.

  ## Example

      {:ok, clock} = VirtualClock.start_link()

      {:ok, server} =
        VirtualTimeGenServer.start_link(MyServer, :ok,
          virtual_clock: clock,
          instrumentation: MessageCounter
        )

      VirtualTimeGenServer.call(server, :ping)
      {:ok, %{received: 1}} = VirtualTimeGenServer.snapshot(server)
  """
  @spec snapshot(GenServer.server()) :: {:ok, term} | {:error, :not_instrumented}
  def snapshot(server) do
    GenServer.call(server, VirtualTimeGenServer.Wrapper.snapshot_request())
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
  Sleeps for the specified duration in milliseconds.

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
  def sleep(duration_ms) do
    backend = get_time_backend()
    backend.sleep(duration_ms)
  end

  defmacro __using__(_opts) do
    quote do
      use GenServer

      @doc """
      Sends a message to this process after a delay in milliseconds.
      Uses the appropriate backend based on the current process configuration.
      """
      def send_after_self(message, delay_ms) do
        VirtualTimeGenServer.send_after(self(), message, delay_ms)
      end
    end
  end

  # Custom start_link that propagates virtual clock to child process
  def start_link(module, init_arg, opts \\ []) do
    # Extract time-related options from opts
    {virtual_clock, opts} = Keyword.pop(opts, :virtual_clock)
    {real_time, opts} = Keyword.pop(opts, :real_time, false)
    {instrumentation, opts} = Keyword.pop(opts, :instrumentation)
    instrumentation = Instrumentation.normalize(instrumentation)

    # Determine which clock and backend to use
    # Priority: local options > global Process dictionary
    {final_clock, final_backend} = determine_time_config(virtual_clock, real_time)

    # Use a wrapper to inject virtual clock into spawned process
    init_fun = fn ->
      if final_clock do
        Process.put(:virtual_clock, final_clock)
      end

      Process.put(:time_backend, final_backend)
      instrument(instrumentation)

      module.init(init_arg)
    end

    # Start with wrapper module
    case GenServer.start_link(
           VirtualTimeGenServer.Wrapper,
           {init_fun, module, instrumentation},
           opts
         ) do
      {:ok, pid} -> {:ok, pid}
      error -> error
    end
  end

  def start(module, init_arg, opts \\ []) do
    # Extract time-related options from opts
    {virtual_clock, opts} = Keyword.pop(opts, :virtual_clock)
    {real_time, opts} = Keyword.pop(opts, :real_time, false)
    {instrumentation, opts} = Keyword.pop(opts, :instrumentation)
    instrumentation = Instrumentation.normalize(instrumentation)

    # Determine which clock and backend to use
    {final_clock, final_backend} = determine_time_config(virtual_clock, real_time)

    init_fun = fn ->
      if final_clock do
        Process.put(:virtual_clock, final_clock)
      end

      Process.put(:time_backend, final_backend)
      instrument(instrumentation)

      module.init(init_arg)
    end

    GenServer.start(VirtualTimeGenServer.Wrapper, {init_fun, module, instrumentation}, opts)
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

  If the calling process is instrumented (see `instrument/1`), the message is
  reported to the observer before it leaves. Otherwise this is a direct
  passthrough to `GenServer.call/3`.
  """
  def call(server, request, timeout \\ 5000) do
    report_send({:call, request})
    GenServer.call(server, request, timeout)
  end

  @doc """
  Sends an asynchronous request to a server.

  If the calling process is instrumented (see `instrument/1`), the message is
  reported to the observer before it leaves. Otherwise this is a direct
  passthrough to `GenServer.cast/2`.
  """
  def cast(server, request) do
    report_send({:cast, request})
    GenServer.cast(server, request)
  end

  defdelegate stop(server, reason \\ :normal, timeout \\ :infinity), to: GenServer

  defp report_send(event) do
    case Process.get(@instrumentation_key) do
      nil -> :ok
      {observer, context} -> observer.on_send(event, %{sender: self(), context: context})
    end
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
