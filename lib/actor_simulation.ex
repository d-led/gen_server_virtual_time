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

  alias ActorSimulation.{Definition, Actor, Stats}

  defstruct [:clock, :actors, :stats, :running, :trace, :trace_enabled]

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
    {:ok, clock} = VirtualClock.start_link()
    trace_enabled = Keyword.get(opts, :trace, false)

    %__MODULE__{
      clock: clock,
      actors: %{},
      stats: Stats.new(),
      running: false,
      trace: [],
      trace_enabled: trace_enabled
    }
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
    {:ok, pid} = Actor.start_link(actor_def, simulation.clock)

    actors = Map.put(simulation.actors, name, %{pid: pid, definition: actor_def, type: :simulated})
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

    # Start the real GenServer with virtual time
    VirtualTimeGenServer.set_virtual_clock(simulation.clock)
    {:ok, pid} = VirtualTimeGenServer.start_link(module, args, [])

    actors = Map.put(simulation.actors, name, %{
      pid: pid,
      type: :real_process,
      module: module,
      targets: targets
    })
    %{simulation | actors: actors}
  end

  @doc """
  Runs the simulation for the specified duration (in milliseconds).
  """
  def run(simulation, opts \\ []) do
    duration = Keyword.get(opts, :duration, 10_000)

    # Register trace collector if tracing enabled
    if simulation.trace_enabled do
      # Unregister if already exists
      case Process.whereis(:trace_collector) do
        nil -> Process.register(self(), :trace_collector)
        pid when pid == self() -> :ok  # Already registered to us
        _other -> Process.unregister(:trace_collector); Process.register(self(), :trace_collector)
      end
    end

    # Start all actors (only simulated actors need setup)
    Enum.each(simulation.actors, fn {_name, actor_info} ->
      case actor_info.type do
        :simulated ->
          Actor.start_sending(actor_info.pid, simulation.actors, simulation.trace_enabled)
        :real_process ->
          # Real processes are already started and don't need actor map
          :ok
      end
    end)

    # Advance virtual time
    VirtualClock.advance(simulation.clock, duration)

    # Collect statistics and trace
    stats = collect_stats(simulation)
    trace = if simulation.trace_enabled, do: collect_trace(), else: []

    %{simulation | stats: stats, trace: trace, running: false}
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
  Formats the trace as a PlantUML sequence diagram.

  ## Example

      simulation = ActorSimulation.new(trace: true)
        |> add_actor(:client, send_pattern: {:periodic, 100, :ping}, targets: [:server])
        |> add_actor(:server)
        |> run(duration: 200)

      plantuml = ActorSimulation.trace_to_plantuml(simulation)
      File.write!("sequence.puml", plantuml)
  """
  def trace_to_plantuml(simulation) do
    lines = ["@startuml", ""]

    message_lines = Enum.map(simulation.trace, fn event ->
      arrow = case event.type do
        :call -> "->>"
        :cast -> "->>"
        :send -> "->"
      end

      msg = inspect(event.message)
      "#{event.from} #{arrow} #{event.to}: #{msg}"
    end)

    lines ++ message_lines ++ ["", "@enduml"]
    |> Enum.join("\n")
  end

  @doc """
  Formats the trace as a Mermaid sequence diagram with enhanced styling.
  
  Mermaid is widely supported in GitHub, GitLab, and many markdown viewers.
  Uses features from [Mermaid sequence diagrams](https://docs.mermaidchart.com/mermaid-oss/syntax/sequenceDiagram.html):
  - Different arrow types for call/cast/send
  - Activation boxes for processing
  - Notes with timestamps
  - Background highlighting for grouped interactions
  
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
    
    lines = ["sequenceDiagram"]
    
    # Group events by time ranges for background highlighting
    message_lines = if enhanced do
      generate_enhanced_mermaid(simulation.trace, show_timestamps)
    else
      generate_simple_mermaid(simulation.trace)
    end
    
    (lines ++ message_lines)
    |> Enum.join("\n")
  end
  
  defp generate_enhanced_mermaid(trace, show_timestamps) do
    trace
    |> Enum.map(fn event ->
      # Different arrow styles based on message type
      # See: https://docs.mermaidchart.com/mermaid-oss/syntax/sequenceDiagram.html#messages
      arrow = case event.type do
        :call -> "->>"   # Solid line with arrowhead (synchronous)
        :cast -> "-->>"  # Dotted line with arrowhead (asynchronous)
        :send -> "->>"   # Solid line with arrowhead
      end
      
      msg = inspect(event.message)
      
      # Add activation for calls (shows processing)
      lines = if event.type == :call do
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
      arrow = case event.type do
        :call -> "->>"
        :cast -> "->>"
        :send -> "->>"
      end
      
      msg = inspect(event.message)
      "    #{event.from}#{arrow}#{event.to}: #{msg}"
    end)
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

  defp collect_stats(simulation) do
    Enum.reduce(simulation.actors, simulation.stats, fn {name, actor_info}, stats ->
      case actor_info.type do
        :simulated ->
          actor_stats = Actor.get_stats(actor_info.pid)
          Stats.add_actor_stats(stats, name, actor_stats)
        :real_process ->
          # For real processes, we can't easily get stats unless they implement a stats protocol
          # For now, add empty stats
          Stats.add_actor_stats(stats, name, %{sent_count: 0, received_count: 0, sent_messages: [], received_messages: []})
      end
    end)
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
