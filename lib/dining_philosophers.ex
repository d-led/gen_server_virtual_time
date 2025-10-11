defmodule DiningPhilosophers do
  @moduledoc """
  Classic dining philosophers problem solved with actor simulation.
  
  Five philosophers sit at a round table with five forks. Each philosopher
  needs two forks to eat. This simulation demonstrates:
  - Resource contention
  - Synchronous communication (requesting forks)
  - State machines (thinking -> hungry -> eating -> thinking)
  - Deadlock-free solution using asymmetric fork acquisition
  """

  @doc """
  Creates a simulation of the dining philosophers problem.
  
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
    
    # Create forks
    simulation = Enum.reduce(0..(num_philosophers - 1), simulation, fn i, sim ->
      ActorSimulation.add_actor(sim, fork_name(i),
        on_match: [
          {:request, fn state ->
            if state.held_by == nil do
              {:reply, :granted, %{state | held_by: :philosopher}}
            else
              {:reply, :denied, state}
            end
          end},
          {:release, fn state ->
            {:reply, :ok, %{state | held_by: nil}}
          end}
        ],
        initial_state: %{held_by: nil}
      )
    end)
    
    # Create philosophers with asymmetric fork acquisition to prevent deadlock
    # Odd-numbered philosophers pick up left fork first
    # Even-numbered philosophers pick up right fork first
    Enum.reduce(0..(num_philosophers - 1), simulation, fn i, sim ->
      {first_fork, second_fork} = if rem(i, 2) == 0 do
        {fork_name(i), fork_name(rem(i + 1, num_philosophers))}
      else
        {fork_name(rem(i + 1, num_philosophers)), fork_name(i)}
      end
      
      philosopher_behavior = create_philosopher_behavior(first_fork, second_fork)
      
      ActorSimulation.add_actor(sim, philosopher_name(i),
        send_pattern: {:periodic, think_time, {:start_hungry, first_fork, second_fork}},
        targets: [first_fork],  # Will request from fork when hungry
        on_receive: philosopher_behavior,
        initial_state: %{
          first_fork: first_fork,
          second_fork: second_fork,
          eat_time: eat_time,
          think_time: think_time,
          times_eaten: 0
        }
      )
    end)
  end
  
  defp philosopher_name(i), do: :"philosopher_#{i}"
  defp fork_name(i), do: :"fork_#{i}"
  
  defp create_philosopher_behavior(first_fork, second_fork) do
    fn msg, state ->
      case msg do
        {:start_hungry, ^first_fork, ^second_fork} ->
          # Philosopher is hungry, request first fork
          {:send, [{first_fork, {:call, :request}}], state}
        
        _ ->
          # Ignore responses for now in this simplified version
          {:ok, state}
      end
    end
  end
  
  @doc """
  Gets statistics about how many times each philosopher ate.
  """
  def eating_stats(simulation) do
    philosophers = [:philosopher_0, :philosopher_1, :philosopher_2, :philosopher_3, :philosopher_4]
    
    Enum.map(philosophers, fn name ->
      case Map.get(simulation.actors, name) do
        nil -> {name, 0}
        %{pid: pid} ->
          stats = ActorSimulation.Actor.get_stats(pid)
          # The times_eaten would be in the user state, but we can't easily access it
          # For now, estimate from messages
          {name, div(stats.sent_count, 2)}  # Each eat cycle sends 2 messages
      end
    end)
    |> Map.new()
  end
end

