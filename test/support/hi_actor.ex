defmodule HiActor do
  @moduledoc """
  A GenServer actor that sends random :hi messages to other actors.

  This module demonstrates how to create real actors using VirtualTimeGenServer
  that can participate in actor simulations with virtual time.
  """

  use VirtualTimeGenServer
  require Logger

  defstruct [:name, :targets, :all_actors]

  @doc """
  Starts a new HiActor with the given name and target actors.
  """
  def start_link(name, targets, all_actors) do
    args = [name, targets, all_actors]
    VirtualTimeGenServer.start_link(__MODULE__, args, name: name)
  end

  @doc """
  Gets the current message counts for this actor.
  """
  def get_stats(pid) do
    VirtualTimeGenServer.call(pid, :get_stats)
  end

  @impl true
  def init(args) do
    # Convert args to state map
    [name, targets, all_actors] = args
    state = %__MODULE__{
      name: name,
      targets: targets,
      all_actors: all_actors
    }
    
    # Debug: Check time backend
    # backend = VirtualTimeGenServer.get_time_backend()
    # clock = Process.get(:virtual_clock)
    # IO.puts("HiActor #{name} init: backend=#{inspect(backend)}, clock=#{inspect(clock)}")
    
    # Set random seed for reproducible results
    :rand.seed(:exs1024, {12345, 67890, 11111})
    
    # Schedule the first random message
    schedule_random_message()
    
    {:ok, state}
  end

  # No need for custom get_stats - VirtualTimeGenServer handles this automatically

  @impl true
  def handle_cast({:hi, from}, state) do
    # Received a :hi message (stats tracked automatically by VirtualTimeGenServer)

    # Randomly choose a target and send :hi back (excluding sender)
    available_targets = Enum.reject(state.all_actors, fn target -> target == from end)

    if length(available_targets) > 0 do
      target = Enum.random(available_targets)

      # Send :hi message to random target
      case Process.whereis(target) do
        nil ->
          # Target not found, just continue
          :ok
        target_pid ->
          VirtualTimeGenServer.cast(target_pid, {:hi, state.name})
      end
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:send_random_message, state) do
    # Choose a random target from available targets (stats tracked automatically)
    available_targets = state.targets
    
    if length(available_targets) > 0 do
      target = Enum.random(available_targets)
      
      # Send :hi message to random target
      case Process.whereis(target) do
        nil ->
          # Target not found, just continue
          :ok
        target_pid ->
          VirtualTimeGenServer.cast(target_pid, {:hi, state.name})
      end
    end
    
    # Schedule the next random message
    schedule_random_message()
    {:noreply, state}
  end

  defp schedule_random_message do
    # Random delay between 200-300ms
    delay = :rand.uniform(101) + 200  # 200-300ms
    
    VirtualTimeGenServer.send_after(self(), :send_random_message, delay)
  end
end
