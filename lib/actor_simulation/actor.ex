defmodule ActorSimulation.Actor do
  @moduledoc """
  A simulated actor that can send and receive messages.
  """
  use VirtualTimeGenServer

  alias ActorSimulation.Definition

  defmodule State do
    @moduledoc false
    defstruct [
      :definition,
      :user_state,
      :actors_map,
      sent_count: 0,
      received_count: 0,
      sent_messages: [],
      received_messages: []
    ]
  end

  # Client API

  def start_link(definition, clock) do
    # Set up virtual time before starting
    VirtualTimeGenServer.set_virtual_clock(clock)
    VirtualTimeGenServer.start_link(__MODULE__, definition, [])
  end

  def start_sending(actor, actors_map) do
    VirtualTimeGenServer.call(actor, {:start_sending, actors_map})
  end

  def get_stats(actor) do
    VirtualTimeGenServer.call(actor, :get_stats)
  end

  # Server callbacks

  @impl true
  def init(definition) do
    state = %State{
      definition: definition,
      user_state: definition.initial_state,
      actors_map: %{}
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:start_sending, actors_map}, _from, state) do
    new_state = %{state | actors_map: actors_map}

    # Schedule first send if this actor has a send pattern
    new_state = if state.definition.send_pattern do
      interval = Definition.interval_for_pattern(state.definition.send_pattern)
      VirtualTimeGenServer.send_after(self(), :send_tick, interval)
      new_state
    else
      new_state
    end

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      sent_count: state.sent_count,
      received_count: state.received_count,
      sent_messages: Enum.reverse(state.sent_messages),
      received_messages: Enum.reverse(state.received_messages)
    }
    {:reply, stats, state}
  end

  @impl true
  def handle_info(:send_tick, state) do
    # Send messages based on pattern
    messages = Definition.messages_for_pattern(state.definition.send_pattern)

    # Send to all targets
    Enum.each(state.definition.targets, fn target_name ->
      case Map.get(state.actors_map, target_name) do
        nil -> :ok
        %{pid: target_pid} ->
          Enum.each(messages, fn msg ->
            send(target_pid, {:actor_message, state.definition.name, msg})
          end)
      end
    end)

    # Update stats
    sent_count = length(messages) * length(state.definition.targets)
    new_sent_messages = Enum.map(messages, & &1) ++ state.sent_messages

    # Schedule next send
    interval = Definition.interval_for_pattern(state.definition.send_pattern)
    VirtualTimeGenServer.send_after(self(), :send_tick, interval)

    {:noreply, %{state |
      sent_count: state.sent_count + sent_count,
      sent_messages: new_sent_messages
    }}
  end

  @impl true
  def handle_info({:actor_message, from, msg}, state) do
    # Track received message
    new_received_messages = [{from, msg} | state.received_messages]
    new_state = %{state |
      received_count: state.received_count + 1,
      received_messages: new_received_messages
    }

    # Call user's on_receive handler
    case state.definition.on_receive.(msg, new_state.user_state) do
      {:ok, user_state} ->
        {:noreply, %{new_state | user_state: user_state}}

      {:send, messages_to_send, user_state} ->
        # Send response messages
        Enum.each(messages_to_send, fn {target, message} ->
          case Map.get(new_state.actors_map, target) do
            nil -> :ok
            %{pid: target_pid} ->
              send(target_pid, {:actor_message, new_state.definition.name, message})
          end
        end)

        sent_count = length(messages_to_send)
        {:noreply, %{new_state |
          user_state: user_state,
          sent_count: new_state.sent_count + sent_count
        }}
    end
  end

end
