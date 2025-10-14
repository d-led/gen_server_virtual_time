defmodule DiningPhilosophers do
  @moduledoc false
  @doc """
  Classic dining philosophers problem solved with actor simulation.

  Five philosophers sit at a round table with five forks. Each philosopher
  needs two forks to eat. This simulation demonstrates:
  - Resource contention
  - Synchronous communication (requesting forks)
  - State machines (thinking -> hungry -> eating -> thinking)
  - Deadlock-free solution using asymmetric fork acquisition

  create_simulation Creates a simulation of the dining philosophers problem.

  Options:
  - `:num_philosophers` - Number of philosophers (default: 5)
  - `:think_time` - Time spent thinking in ms (default: 100)
  - `:eat_time` - Time spent eating in ms (default: 50)
  - `:trace` - Enable message tracing (default: true)

  ## Example

      simulation = DiningPhilosophers.create_simulation(
        num_philosophers: 5,
        think_time: 100,
        eat_time: 50,
        trace: true
      )

      simulation = ActorSimulation.run(simulation, duration: 5000)
      stats = ActorSimulation.get_stats(simulation)
  """
  def create_simulation(opts \\ []) do
    num_philosophers = Keyword.get(opts, :num_philosophers, 5)
    think_time = Keyword.get(opts, :think_time, 100)
    eat_time = Keyword.get(opts, :eat_time, 50)
    trace = Keyword.get(opts, :trace, true)

    simulation = ActorSimulation.new(trace: trace)

    # Create forks with proper protocol
    simulation =
      Enum.reduce(0..(num_philosophers - 1), simulation, fn i, sim ->
        fork_actor_name = fork_name(i)

        ActorSimulation.add_actor(sim, fork_actor_name,
          on_receive: fn msg, state ->
            case msg do
              {:request_fork, phil} ->
                # Send response back to philosopher asynchronously
                if state.held_by == nil do
                  {:send, [{phil, {:fork_granted, fork_actor_name}}], %{state | held_by: phil}}
                else
                  {:send, [{phil, {:fork_denied, fork_actor_name}}], state}
                end

              {:release_fork, phil} ->
                # Release if held by this philosopher
                if state.held_by == phil do
                  {:ok, %{state | held_by: nil}}
                else
                  {:ok, state}
                end

              _ ->
                {:ok, state}
            end
          end,
          initial_state: %{held_by: nil}
        )
      end)

    # Create philosophers with asymmetric fork acquisition to prevent deadlock
    # Odd-numbered philosophers pick up left fork first
    # Even-numbered philosophers pick up right fork first
    Enum.reduce(0..(num_philosophers - 1), simulation, fn i, sim ->
      {first_fork, second_fork} =
        if rem(i, 2) == 0 do
          {fork_name(i), fork_name(rem(i + 1, num_philosophers))}
        else
          {fork_name(rem(i + 1, num_philosophers)), fork_name(i)}
        end

      philosopher_behavior = create_philosopher_behavior(first_fork, second_fork)

      ActorSimulation.add_actor(sim, philosopher_name(i),
        send_pattern: {:periodic, think_time, {:start_hungry, first_fork, second_fork}},
        # Send to self to trigger behavior (which then sends mumbles and fork requests)
        targets: [philosopher_name(i)],
        on_receive: philosopher_behavior,
        initial_state: %{
          name: philosopher_name(i),
          first_fork: first_fork,
          second_fork: second_fork,
          eat_time: eat_time,
          think_time: think_time,
          times_eaten: 0,
          # Only mumble once at start
          mumbled_hungry: false,
          first_fork_held: false,
          second_fork_held: false
        }
      )
    end)
  end

  defp philosopher_name(i), do: :"philosopher_#{i}"
  defp fork_name(i), do: :"fork_#{i}"

  defp create_philosopher_behavior(first_fork, second_fork) do
    fn msg, state ->
      philosopher_name = state[:name] || :self

      case msg do
        {:start_hungry, ^first_fork, ^second_fork} ->
          # Only mumble on very first time
          if state[:mumbled_hungry] do
            # Already mumbled, just request fork (async to get response as message)
            {:send, [{first_fork, {:request_fork, philosopher_name}}], state}
          else
            # First time, mumble then request
            {:send,
             [
               {philosopher_name, {:mumble, "I'm hungry!"}},
               {first_fork, {:request_fork, philosopher_name}}
             ], Map.put(state, :mumbled_hungry, true)}
          end

        {:mumble, "I'm hungry!"} ->
          # First-time hunger acknowledged
          {:ok, state}

        {:mumble, "I'm full!"} ->
          # Finished eating - counter already incremented when we sent this message
          {:ok, state}

        {:fork_granted, fork} ->
          # Got a fork! Check if we have both
          if fork == first_fork && !state[:first_fork_held] do
            # Got first fork, try for second
            {:send, [{second_fork, {:request_fork, philosopher_name}}],
             Map.put(state, :first_fork_held, true)}
          else
            # Got second fork! We can eat now - sleep for eat_time, then mumble satisfaction
            new_state = %{state | second_fork_held: true}
            times_eaten = (state[:times_eaten] || 0) + 1
            eat_time = state[:eat_time] || 50

            # Use send_after to simulate eating time (non-blocking virtual time!)
            {:send_after, eat_time,
             [
               {philosopher_name, {:mumble, "I'm full!"}},
               {first_fork, {:release_fork, philosopher_name}},
               {second_fork, {:release_fork, philosopher_name}}
             ],
             %{
               new_state
               | first_fork_held: false,
                 second_fork_held: false,
                 times_eaten: times_eaten
             }}
          end

        {:fork_denied, _fork} ->
          # Fork denied, release any held forks and reset
          releases =
            if state[:first_fork_held] do
              [{first_fork, {:release_fork, philosopher_name}}]
            else
              []
            end

          {:send, releases, %{state | first_fork_held: false, second_fork_held: false}}

        _ ->
          # Ignore other messages
          {:ok, state}
      end
    end
  end

  @doc """
  Gets statistics about how many times each philosopher ate.
  """
  def eating_stats(simulation) do
    philosophers = [
      :philosopher_0,
      :philosopher_1,
      :philosopher_2,
      :philosopher_3,
      :philosopher_4
    ]

    Enum.map(philosophers, fn name ->
      case Map.get(simulation.actors, name) do
        nil ->
          {name, 0}

        %{pid: pid} ->
          stats = ActorSimulation.Actor.get_stats(pid)
          # The times_eaten would be in the user state, but we can't easily access it
          # For now, estimate from messages
          # Each eat cycle sends 2 messages
          {name, div(stats.sent_count, 2)}
      end
    end)
    |> Map.new()
  end
end
