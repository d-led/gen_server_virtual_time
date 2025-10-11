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

  defstruct [:clock, :actors, :stats, :running]

  @doc """
  Creates a new actor simulation.
  """
  def new do
    {:ok, clock} = VirtualClock.start_link()
    %__MODULE__{
      clock: clock,
      actors: %{},
      stats: Stats.new(),
      running: false
    }
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
  - `:initial_state` - Initial state for the actor (default: %{})
  """
  def add_actor(simulation, name, opts \\ []) do
    actor_def = Definition.new(name, opts)
    {:ok, pid} = Actor.start_link(actor_def, simulation.clock)

    actors = Map.put(simulation.actors, name, %{pid: pid, definition: actor_def})
    %{simulation | actors: actors}
  end

  @doc """
  Runs the simulation for the specified duration (in milliseconds).
  """
  def run(simulation, opts \\ []) do
    duration = Keyword.get(opts, :duration, 10_000)

    # Start all actors
    Enum.each(simulation.actors, fn {_name, %{pid: pid}} ->
      Actor.start_sending(pid, simulation.actors)
    end)

    # Advance virtual time
    VirtualClock.advance(simulation.clock, duration)

    # Collect statistics
    stats = collect_stats(simulation)

    %{simulation | stats: stats, running: false}
  end

  @doc """
  Gets statistics from the simulation.
  """
  def get_stats(simulation) do
    simulation.stats
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
    Enum.reduce(simulation.actors, simulation.stats, fn {name, %{pid: pid}}, stats ->
      actor_stats = Actor.get_stats(pid)
      Stats.add_actor_stats(stats, name, actor_stats)
    end)
  end
end
