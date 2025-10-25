defmodule ActorSimulation do
  @moduledoc """
  A DSL for simulating actor systems with message rates and statistics.

  This module provides a way to define actors, their message sending patterns,
  and simulate their interactions using virtual time.

  ## Example

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
            send_pattern: {:periodic, 100, {:data, :id}},
            targets: [:consumer])
        |> ActorSimulation.add_actor(:consumer,
            on_receive: fn msg, state ->
              # Process message and maybe send response
              {:ok, state}
            end)
        |> ActorSimulation.run(duration: 5000)

      stats = ActorSimulation.get_stats(simulation)
      IO.inspect(stats)
  """

  alias ActorSimulation.{Actor, Definition, MermaidReportGenerator, Stats}

  defstruct [
    :clock,
    :actors,
    :stats,
    :running,
    :trace,
    :trace_enabled,
    :actual_duration,
    :terminated_early,
    :termination_reason
  ]

  @doc """
  Creates a new actor simulation.

  Options:
  - `:trace` - Enable message tracing for sequence diagrams (default: false)

  ## Example

      iex> simulation = ActorSimulation.new()
      iex> is_pid(simulation.clock)
      true
      iex> simulation.actors
      %{}

  """
  def new(opts \\ []) do
    clock = Keyword.get(opts, :clock)

    clock =
      if clock,
        do: clock,
        else:
          (fn ->
             {:ok, c} = VirtualClock.start_link()
             c
           end).()

    trace_enabled = Keyword.get(opts, :trace, false)

    %__MODULE__{
      clock: clock,
      actors: %{},
      stats: Stats.new(),
      running: false,
      trace: [],
      trace_enabled: trace_enabled,
      actual_duration: 0
    }
  end

  @doc """
  Helper to collect current stats during simulation (for termination conditions).
  Can be called from terminate_when functions.

  Note: This is a live snapshot and may be called multiple times during run/2.
  """
  def collect_current_stats(simulation) do
    Enum.reduce(simulation.actors, Stats.new(), fn {name, actor_info}, stats ->
      case actor_info.type do
        :simulated ->
          actor_stats = Actor.get_stats(actor_info.pid)
          Stats.add_actor_stats(stats, name, actor_stats)

        :real_process ->
          # Get stats from VirtualTimeGenServer's built-in tracking
          real_stats = GenServer.call(actor_info.pid, :__vtgs_get_stats__)
          Stats.add_actor_stats(stats, name, real_stats)
      end
    end)
  end

  @doc """
  Enables message tracing for the simulation.
  """
  def enable_trace(simulation) do
    %{simulation | trace_enabled: true}
  end

  @doc """
  Adds an actor to the simulation.

  Options:
  - `:send_pattern` - How this actor sends messages:
    - `{:periodic, interval, message}` - Send message every interval ms
    - `{:rate, messages_per_second, message}` - Send at a specific rate
    - `{:burst, count, interval, message}` - Send count messages every interval
  - `:targets` - List of actor names to send messages to
  - `:on_receive` - Function called when receiving a message: `fn msg, state -> {:ok, new_state} | {:send, msgs, new_state} end`
  - `:on_match` - Pattern matching responses: `[{pattern, response_fn}]`
  - `:initial_state` - Initial state for the actor (default: %{})
  """
  def add_actor(simulation, name, opts \\ []) do
    actor_def = Definition.new(name, opts)

    # Inject trace collector if tracing is enabled and stats tracking
    actor_opts =
      if simulation.trace_enabled do
        [trace_collector: self(), stats_enabled: true]
      else
        [stats_enabled: true]
      end

    {:ok, pid} = Actor.start_link(actor_def, simulation.clock, actor_opts)

    actors =
      Map.put(simulation.actors, name, %{pid: pid, definition: actor_def, type: :simulated})

    %{simulation | actors: actors}
  end

  @doc """
  Adds a real GenServerVirtualTime process to the simulation ("Process in the Loop").

  This allows you to test real GenServer implementations alongside simulated actors.

  Options:
  - `:module` - The GenServer module to start (required)
  - `:args` - Arguments to pass to the module's init/1
  - `:targets` - List of actor names this process can send to (optional)

  ## Example

      defmodule MyRealServer do
        use VirtualTimeGenServer

        def init(args), do: {:ok, args}
        def handle_call(:ping, _from, state), do: {:reply, :pong, state}
      end

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_process(:my_server, module: MyRealServer, args: %{})
        |> ActorSimulation.add_actor(:pinger,
            send_pattern: {:periodic, 100, {:call, :my_server, :ping}})
  """
  def add_process(simulation, name, opts \\ []) do
    module = Keyword.fetch!(opts, :module)
    args = Keyword.get(opts, :args, nil)
    targets = Keyword.get(opts, :targets, [])

    # Start the real GenServer with the simulation's local virtual clock and stats injection
    # This avoids setting global state and affecting other tests
    {:ok, pid} =
      VirtualTimeGenServer.start_link(module, args,
        name: name,
        virtual_clock: simulation.clock,
        stats_enabled: true
      )

    # Set up actor name context for trace generation
    Process.put(:__vtgs_actor_name__, name)

    actors =
      Map.put(simulation.actors, name, %{
        pid: pid,
        type: :real_process,
        module: module,
        targets: targets
      })

    %{simulation | actors: actors}
  end

  @doc """
  Runs the simulation for the specified duration (in milliseconds).

  Options:
  - `:duration` - Maximum duration in milliseconds (default: 10,000)
  - `:terminate_when` - Function that takes simulation and returns true to stop
  - `:check_interval` - How often to check termination condition in ms (default: 100)

  ## Boundary Condition Handling

  The simulation automatically handles boundary conditions where events are scheduled
  at exactly the end time. For example, a rate pattern sending 50 messages per second
  over 1000ms will send messages at times 0, 20, 40, ..., 980, 1000. The simulation
  advances the clock one tick beyond the specified duration and waits for quiescence
  to ensure all boundary events are processed.

  ## Example

      # Run for fixed duration (backward compatible)
      simulation = ActorSimulation.run(simulation, duration: 5000)

      # Run until condition met (new feature)
      simulation = ActorSimulation.run(simulation,
        max_duration: 10_000,
        terminate_when: fn sim ->
          # Stop when all actors have sent at least 10 messages
          stats = ActorSimulation.collect_current_stats(sim)
          Enum.all?(stats.actors, fn {_name, s} -> s.sent_count >= 10 end)
        end
      )
  """
  def run(simulation, opts \\ []) do
    duration = Keyword.get(opts, :duration) || Keyword.get(opts, :max_duration, 10_000)
    terminate_when = Keyword.get(opts, :terminate_when)
    check_interval = Keyword.get(opts, :check_interval, 100)

    # Start all actors (only simulated actors need setup)
    # Trace collector is already injected at start_link time
    Enum.each(simulation.actors, fn {_name, actor_info} ->
      case actor_info.type do
        :simulated ->
          Actor.start_sending(actor_info.pid, simulation.actors)

        :real_process ->
          # Real processes are already started and don't need actor map
          :ok
      end
    end)

    # Measure real time for simulation execution
    start_time = System.monotonic_time(:millisecond)

    # Advance virtual time with optional termination check
    {actual_duration, accumulated_trace, termination_reason} =
      cond do
        terminate_when == :quiescence ->
          {dur, tr} = advance_until_quiescence(simulation, duration)
          {dur, tr, :quiescence}

        is_function(terminate_when) ->
          {dur, tr} = advance_with_condition(simulation, duration, terminate_when, check_interval)
          {dur, tr, :condition}

        true ->
          # Simple advance: just advance to the target time
          # The VirtualClock.advance already handles quiescence at the target time
          VirtualClock.advance(simulation.clock, duration)
          {duration, [], :max_time}
      end

    end_time = System.monotonic_time(:millisecond)
    real_elapsed = end_time - start_time

    # Mark if terminated early due to condition or quiescence
    terminated_early =
      case termination_reason do
        :condition -> actual_duration < duration
        :quiescence -> actual_duration < duration
        _ -> false
      end

    # Update simulation with timing info before collecting stats
    # (stats need actual_duration for rate calculations)
    simulation_with_timing =
      simulation
      |> Map.put(:actual_duration, actual_duration)
      |> Map.put(:max_duration, duration)
      |> Map.put(:terminated_early, terminated_early)
      |> Map.put(:real_time_elapsed, real_elapsed)
      |> Map.put(:termination_reason, termination_reason)

    # Collect statistics and trace (now that actual_duration is set)
    stats = collect_stats(simulation_with_timing)
    # If we accumulated trace during termination checks, use it and collect any remaining messages
    # Otherwise collect fresh trace
    trace =
      if simulation.trace_enabled do
        remaining_trace = collect_trace()
        accumulated_trace ++ remaining_trace
      else
        []
      end

    # Return enhanced simulation state with timing information
    %{simulation_with_timing | stats: stats, trace: trace, running: false}
  end

  @doc """
  Gets statistics from the simulation.
  """
  def get_stats(simulation) do
    simulation.stats
  end

  @doc """
  Gets the message trace from the simulation.
  Returns a list of trace events for building sequence diagrams.

  Each event is a map with:
  - `:timestamp` - Virtual time when message was sent
  - `:from` - Sender actor name
  - `:to` - Receiver actor name
  - `:message` - The message sent
  - `:type` - `:cast`, `:call`, or `:send`
  """
  def get_trace(simulation) do
    simulation.trace
  end

  @doc """
  Formats the trace as a Mermaid sequence diagram with enhanced styling.

  Mermaid is widely supported in GitHub, GitLab, and many markdown viewers.
  Uses features from [Mermaid sequence diagrams](https://docs.mermaidchart.com/mermaid-oss/syntax/sequenceDiagram.html):
  - Different arrow types for call/cast/send
  - Activation boxes for processing
  - Notes with timestamps
  - Background highlighting for grouped interactions
  - Termination indicators showing when simulation stopped

  ## Example

      iex> simulation = %ActorSimulation{trace: [
      ...>   %{from: :alice, to: :bob, message: :hello, type: :send, timestamp: 100},
      ...>   %{from: :bob, to: :alice, message: :hi, type: :send, timestamp: 200}
      ...> ]}
      iex> mermaid = ActorSimulation.trace_to_mermaid(simulation)
      iex> String.contains?(mermaid, "sequenceDiagram")
      true
      iex> String.contains?(mermaid, "alice->>bob")
      true

  """
  def trace_to_mermaid(simulation, opts \\ []) do
    enhanced = Keyword.get(opts, :enhanced, true)
    show_timestamps = Keyword.get(opts, :timestamps, false)
    show_termination = Keyword.get(opts, :show_termination, true)

    lines = ["sequenceDiagram"]

    # Group events by time ranges for background highlighting
    message_lines =
      if enhanced do
        generate_enhanced_mermaid(simulation.trace, show_timestamps)
      else
        generate_simple_mermaid(simulation.trace)
      end

    # Add termination indicator if simulation ended early
    final_lines =
      if show_termination && Map.get(simulation, :terminated_early, false) do
        # Get all unique actors from trace
        actors =
          simulation.trace
          |> Enum.flat_map(fn event -> [event.from, event.to] end)
          |> Enum.uniq()

        termination_note =
          case {actors, Map.get(simulation, :actual_duration)} do
            {[], _} ->
              []

            {[single], duration} ->
              ["    Note over #{single}: ⚡ Terminated at t=#{duration}ms (goal achieved)"]

            {[first, second | _], duration} ->
              [
                "    Note over #{first},#{second}: ⚡ Terminated at t=#{duration}ms (goal achieved)"
              ]
          end

        message_lines ++ termination_note
      else
        message_lines
      end

    (lines ++ final_lines)
    |> Enum.join("\n")
  end

  defp generate_enhanced_mermaid(trace, show_timestamps) do
    trace
    |> Enum.map(fn event ->
      # Different arrow styles based on message type
      # See: https://docs.mermaidchart.com/mermaid-oss/syntax/sequenceDiagram.html#messages
      arrow =
        case event.type do
          # Solid line with arrowhead (synchronous)
          :call -> "->>"
          # Dotted line with arrowhead (asynchronous)
          :cast -> "-->>"
          # Solid line with arrowhead
          :send -> "->>"
        end

      msg = inspect(event.message)

      # Add activation for calls (shows processing)
      lines =
        if event.type == :call do
          [
            "    activate #{event.to}",
            "    #{event.from}#{arrow}#{event.to}: #{msg}",
            "    deactivate #{event.to}"
          ]
        else
          ["    #{event.from}#{arrow}#{event.to}: #{msg}"]
        end

      # Add timestamp note if requested
      if show_timestamps && event.timestamp do
        lines ++ ["    Note over #{event.from},#{event.to}: t=#{event.timestamp}ms"]
      else
        lines
      end
    end)
    |> List.flatten()
  end

  defp generate_simple_mermaid(trace) do
    Enum.map(trace, fn event ->
      arrow =
        case event.type do
          :call -> "->>"
          :cast -> "->>"
          :send -> "->>"
        end

      msg = inspect(event.message)
      "    #{event.from}#{arrow}#{event.to}: #{msg}"
    end)
  end

  @doc """
  Generates a Mermaid flowchart report showing actor topology and statistics.

  This creates a visual report with:
  - Actor topology as a flowchart
  - Statistics embedded in nodes (message counts, rates)
  - Activity-based styling (color coding by traffic)
  - Complete HTML page with stats table

  ## Options

  - `:title` - Report title (default: "Simulation Report")
  - `:show_stats_on_nodes` - Show stats on nodes (default: true)
  - `:show_message_labels` - Show message types on edges (default: true)
  - `:layout` - Direction: "TB", "LR", "RL", "BT" (default: "TB")
  - `:style_by_activity` - Color by activity level (default: true)

  ## Example

      simulation = ActorSimulation.new()
        |> add_actor(:producer, send_pattern: {:periodic, 100, :data}, targets: [:consumer])
        |> add_actor(:consumer)
        |> run(duration: 1000)

      html = ActorSimulation.generate_flowchart_report(simulation,
        title: "My System",
        layout: "LR")

      File.write!("report.html", html)

  Based on [Mermaid Flowchart Syntax](https://mermaid.js.org/syntax/flowchart.html)
  """
  def generate_flowchart_report(simulation, opts \\ []) do
    MermaidReportGenerator.generate_report(simulation, opts)
  end

  @doc """
  Writes a flowchart report directly to a file.

  Same options as `generate_flowchart_report/2`.

  ## Example

      simulation = ActorSimulation.new()
        |> add_actor(:source, send_pattern: {:periodic, 100, :msg}, targets: [:sink])
        |> add_actor(:sink)
        |> run(duration: 500)

      {:ok, path} = ActorSimulation.write_flowchart_report(
        simulation,
        "my_report.html",
        title: "Production System")
  """
  def write_flowchart_report(simulation, filename, opts \\ []) do
    MermaidReportGenerator.write_report(simulation, filename, opts)
  end

  @doc """
  Stops the simulation and cleans up resources.
  """
  def stop(simulation) do
    Enum.each(simulation.actors, fn {_name, %{pid: pid}} ->
      GenServer.stop(pid, :normal, :infinity)
    end)

    GenServer.stop(simulation.clock)
    :ok
  end

  # Private functions

  defp advance_with_condition(simulation, max_duration, condition_fn, check_interval) do
    # Start with empty accumulated trace
    advance_with_condition_loop(simulation, max_duration, condition_fn, check_interval, 0, [])
  end

  defp advance_with_condition_loop(
         simulation,
         max_duration,
         condition_fn,
         check_interval,
         elapsed,
         accumulated_trace
       ) do
    if elapsed >= max_duration do
      {max_duration, accumulated_trace}
    else
      # Advance by check_interval
      step = min(check_interval, max_duration - elapsed)
      VirtualClock.advance(simulation.clock, step)
      new_elapsed = elapsed + step

      # Collect new trace messages and accumulate them
      # This allows terminate_when to access the trace accumulated so far
      {current_simulation, new_accumulated_trace} =
        if simulation.trace_enabled do
          new_trace_messages = collect_trace()
          full_trace = accumulated_trace ++ new_trace_messages
          {%{simulation | trace: full_trace}, full_trace}
        else
          {simulation, accumulated_trace}
        end

      # Check termination condition
      if condition_fn.(current_simulation) do
        {new_elapsed, new_accumulated_trace}
      else
        advance_with_condition_loop(
          simulation,
          max_duration,
          condition_fn,
          check_interval,
          new_elapsed,
          new_accumulated_trace
        )
      end
    end
  end

  # Advance until quiescence or max_duration
  # Quiescence: no scheduled timers and mailbox drains to empty across all simulated actors
  defp advance_until_quiescence(simulation, max_duration) do
    advance_until_quiescence_loop(simulation, max_duration, 0, [])
  end

  defp advance_until_quiescence_loop(simulation, max_duration, elapsed, accumulated_trace) do
    if elapsed >= max_duration do
      {max_duration, accumulated_trace}
    else
      # If no timers scheduled, we are quiescent
      if VirtualClock.scheduled_count(simulation.clock) == 0 do
        {elapsed, accumulated_trace}
      else
        # Advance to next scheduled event to let messages flow
        advance = VirtualClock.advance_to_next(simulation.clock)
        new_elapsed = elapsed + advance

        {acc_sim, acc_trace} =
          if simulation.trace_enabled do
            new_msgs = collect_trace()
            {%{simulation | trace: accumulated_trace ++ new_msgs}, accumulated_trace ++ new_msgs}
          else
            {simulation, accumulated_trace}
          end

        advance_until_quiescence_loop(acc_sim, max_duration, new_elapsed, acc_trace)
      end
    end
  end

  defp collect_stats(simulation) do
    # Get the actual duration that was simulated
    actual_duration = Map.get(simulation, :actual_duration, 0)

    stats =
      Enum.reduce(simulation.actors, simulation.stats, fn {name, actor_info}, stats ->
        case actor_info.type do
          :simulated ->
            actor_stats = Actor.get_stats(actor_info.pid)
            Stats.add_actor_stats(stats, name, actor_stats)

          :real_process ->
            # Get stats from VirtualTimeGenServer's built-in tracking
            real_stats = GenServer.call(actor_info.pid, :__vtgs_get_stats__)
            Stats.add_actor_stats(stats, name, real_stats)
        end
      end)

    # Set the time range for rate calculations
    %{stats | start_time: 0, end_time: actual_duration}
  end

  defp collect_trace do
    # Collect all trace messages
    collect_trace_messages([])
  end

  defp collect_trace_messages(acc) do
    receive do
      {:trace, event} -> collect_trace_messages([event | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end
