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
      :trace_collector_pid,
      sent_count: 0,
      received_count: 0,
      sent_messages: [],
      received_messages: []
    ]
  end

  # Client API

  def start_link(definition, clock, opts \\ []) do
    # Use test-local virtual clock injection instead of global
    # Also support trace collector injection
    trace_collector = Keyword.get(opts, :trace_collector)

    VirtualTimeGenServer.start_link(__MODULE__, {definition, trace_collector},
      virtual_clock: clock
    )
  end

  def start_sending(actor, actors_map) do
    VirtualTimeGenServer.call(actor, {:start_sending, actors_map})
  end

  def get_stats(actor) do
    VirtualTimeGenServer.call(actor, :get_stats)
  end

  # Server callbacks

  @impl true
  def init({definition, trace_collector}) do
    state = %State{
      definition: definition,
      user_state: definition.initial_state,
      actors_map: %{},
      trace_collector_pid: trace_collector
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:start_sending, actors_map}, _from, state) do
    new_state = %{state | actors_map: actors_map}

    # Schedule first send if this actor has a send pattern
    new_state =
      if state.definition.send_pattern do
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
        nil ->
          :ok

        target_info ->
          Enum.each(messages, fn msg ->
            send_message(state, target_name, target_info, msg)
          end)
      end
    end)

    # Update stats
    sent_count = length(messages) * length(state.definition.targets)
    new_sent_messages = Enum.map(messages, & &1) ++ state.sent_messages

    # Schedule next send
    interval = Definition.interval_for_pattern(state.definition.send_pattern)
    VirtualTimeGenServer.send_after(self(), :send_tick, interval)

    {:noreply,
     %{state | sent_count: state.sent_count + sent_count, sent_messages: new_sent_messages}}
  end

  @impl true
  def handle_info({:delayed_send, messages_to_send}, state) do
    # Handle delayed sends (from send_after return value)
    # This simulates processing time in virtual time
    Enum.each(messages_to_send, fn
      {target, message} ->
        target_info =
          if target == state.definition.name do
            %{pid: self(), type: :simulated}
          else
            Map.get(state.actors_map, target)
          end

        case target_info do
          nil -> :ok
          info -> send_message(state, target, info, message)
        end

      message when is_tuple(message) and tuple_size(message) == 2 ->
        {target, msg} = message

        target_info =
          if target == state.definition.name do
            %{pid: self(), type: :simulated}
          else
            Map.get(state.actors_map, target)
          end

        case target_info do
          nil -> :ok
          info -> send_message(state, target, info, msg)
        end
    end)

    sent_count = length(messages_to_send)

    {:noreply, %{state | sent_count: state.sent_count + sent_count}}
  end

  @impl true
  def handle_info({:actor_message, from, msg}, state) do
    # Track received message
    new_received_messages = [{from, msg} | state.received_messages]

    new_state = %{
      state
      | received_count: state.received_count + 1,
        received_messages: new_received_messages
    }

    # First try pattern matching
    result =
      case Definition.match_message(state.definition, msg) do
        {:matched, response} when is_function(response, 1) ->
          # Response function takes state
          response.(new_state.user_state)

        {:matched, response} ->
          # Static response
          {:send, response, new_state.user_state}

        nil ->
          # No match, try on_receive handler
          if state.definition.on_receive do
            state.definition.on_receive.(msg, new_state.user_state)
          else
            {:ok, new_state.user_state}
          end
      end

    # Process the result
    case result do
      {:ok, user_state} ->
        {:noreply, %{new_state | user_state: user_state}}

      {:reply, _reply, user_state} ->
        # Reply from pattern match but in async context, just ignore reply
        {:noreply, %{new_state | user_state: user_state}}

      {:send_after, duration, messages_to_send, user_state} ->
        # Schedule messages to be sent after a delay (simulating processing time)
        # This is non-blocking and works with virtual time
        messages_to_send =
          if is_list(messages_to_send), do: messages_to_send, else: [messages_to_send]

        # Schedule a self-message to trigger the actual sends later
        VirtualTimeGenServer.send_after(self(), {:delayed_send, messages_to_send}, duration)

        {:noreply, %{new_state | user_state: user_state}}

      {:send, messages_to_send, user_state} ->
        # Send response messages
        messages_to_send =
          if is_list(messages_to_send), do: messages_to_send, else: [messages_to_send]

        Enum.each(messages_to_send, fn
          {target, message} ->
            # Handle self-messages
            target_info =
              if target == new_state.definition.name do
                %{pid: self(), type: :simulated}
              else
                Map.get(new_state.actors_map, target)
              end

            case target_info do
              nil -> :ok
              info -> send_message(new_state, target, info, message)
            end

          message when is_tuple(message) and tuple_size(message) == 2 ->
            {target, msg} = message

            # Handle self-messages
            target_info =
              if target == new_state.definition.name do
                %{pid: self(), type: :simulated}
              else
                Map.get(new_state.actors_map, target)
              end

            case target_info do
              nil -> :ok
              info -> send_message(new_state, target, info, msg)
            end
        end)

        sent_count = length(messages_to_send)

        {:noreply,
         %{new_state | user_state: user_state, sent_count: new_state.sent_count + sent_count}}
    end
  end

  @impl true
  def handle_info({:actor_call, from, ref, msg}, state) do
    # Handle synchronous call
    new_received_messages = [{from, {:call, msg}} | state.received_messages]

    new_state = %{
      state
      | received_count: state.received_count + 1,
        received_messages: new_received_messages
    }

    # Try pattern matching
    result =
      case Definition.match_message(state.definition, msg) do
        {:matched, response} when is_function(response, 1) ->
          response.(new_state.user_state)

        {:matched, response} ->
          {:reply, response, new_state.user_state}

        nil ->
          if state.definition.on_receive do
            state.definition.on_receive.(msg, new_state.user_state)
          else
            {:reply, :ok, new_state.user_state}
          end
      end

    case result do
      {:reply, reply, user_state} ->
        # Send reply back - 'from' is actor name, need to get pid
        case Map.get(new_state.actors_map, from) do
          nil ->
            :ok

          from_info ->
            VirtualTimeGenServer.send_immediately(from_info.pid, {:actor_reply, ref, reply})
        end

        {:noreply, %{new_state | user_state: user_state}}

      {:ok, user_state} ->
        case Map.get(new_state.actors_map, from) do
          nil ->
            :ok

          from_info ->
            VirtualTimeGenServer.send_immediately(from_info.pid, {:actor_reply, ref, :ok})
        end

        {:noreply, %{new_state | user_state: user_state}}

      {:send, messages_to_send, user_state} ->
        # Send messages but also reply to caller
        messages_to_send =
          if is_list(messages_to_send), do: messages_to_send, else: [messages_to_send]

        Enum.each(messages_to_send, fn
          {target, message} ->
            case Map.get(new_state.actors_map, target) do
              nil ->
                :ok

              target_info ->
                send_message(new_state, target, target_info, message)
            end
        end)

        # Send default :ok reply to caller
        case Map.get(new_state.actors_map, from) do
          nil ->
            :ok

          from_info ->
            VirtualTimeGenServer.send_immediately(from_info.pid, {:actor_reply, ref, :ok})
        end

        {:noreply,
         %{
           new_state
           | user_state: user_state,
             sent_count: new_state.sent_count + length(messages_to_send)
         }}
    end
  end

  # Private helpers

  defp send_message(state, target_name, target_info, msg) do
    case msg do
      {:call, message} ->
        # Synchronous call
        trace_event(state, target_name, message, :call)

        case target_info.type do
          :real_process ->
            # For real processes, use GenServer.call
            try do
              GenServer.call(target_info.pid, message)
            catch
              :exit, _ -> :timeout
            end

          :simulated ->
            # For simulated actors, use our custom protocol
            ref = make_ref()

            VirtualTimeGenServer.send_immediately(
              target_info.pid,
              {:actor_call, state.definition.name, ref, message}
            )

            receive do
              {:actor_reply, ^ref, reply} -> reply
            after
              5000 -> :timeout
            end
        end

      {:cast, message} ->
        # Asynchronous cast
        trace_event(state, target_name, message, :cast)

        case target_info.type do
          :real_process ->
            GenServer.cast(target_info.pid, message)

          :simulated ->
            VirtualTimeGenServer.send_immediately(
              target_info.pid,
              {:actor_message, state.definition.name, message}
            )
        end

      message ->
        # Regular send
        trace_event(state, target_name, message, :send)

        VirtualTimeGenServer.send_immediately(
          target_info.pid,
          {:actor_message, state.definition.name, message}
        )
    end
  end

  defp trace_event(state, target, message, type) do
    if state.trace_collector_pid do
      # Get the virtual clock from the process dictionary (injected by VirtualTimeGenServer)
      clock = Process.get(:virtual_clock)
      timestamp = if clock, do: VirtualClock.now(clock), else: 0

      send(
        state.trace_collector_pid,
        {:trace,
         %{
           timestamp: timestamp,
           from: state.definition.name,
           to: target,
           message: message,
           type: type
         }}
      )
    end
  end
end
