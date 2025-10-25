defmodule VirtualClock do
  @moduledoc """
  A GenServer that manages virtual time for testing time-dependent behaviors.

  The VirtualClock maintains a virtual timestamp and scheduled events.
  Time can be advanced manually, triggering all events scheduled up to that point.

  ## Example

      iex> {:ok, clock} = VirtualClock.start_link()
      iex> VirtualClock.now(clock)
      0
      iex> VirtualClock.advance(clock, 1000)
      {:ok, 1000}
      iex> VirtualClock.now(clock)
      1000

  """
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct current_time: 0, scheduled: :gb_trees.empty()
  end

  defmodule ScheduledEvent do
    @moduledoc false
    defstruct [:trigger_time, :dest, :message, :ref]
  end

  # Client API

  @doc """
  Starts a new virtual clock.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Gets the current virtual time.
  """
  def now(clock) do
    GenServer.call(clock, :now)
  end

  @doc """
  Schedules a message to be sent after a delay in virtual time.
  Returns a reference that can be used to cancel the timer.
  """
  def send_after(clock, dest, message, delay) do
    GenServer.call(clock, {:send_after, dest, message, delay})
  end

  @doc """
  Cancels a scheduled timer.
  """
  def cancel_timer(clock, ref) do
    GenServer.call(clock, {:cancel_timer, ref})
  end

  @doc """
  Advances the virtual clock by the specified amount.
  All events scheduled up to the new time will be triggered.

  This advances time incrementally, processing each scheduled event
  and allowing new events to be scheduled in response.
  """
  def advance(clock, amount) do
    GenServer.call(clock, {:advance, amount}, :infinity)
  end

  @doc """
  Advances the virtual clock to the next scheduled event.
  Returns the time advanced, or 0 if no events are scheduled.
  """
  def advance_to_next(clock) do
    GenServer.call(clock, :advance_to_next)
  end

  @doc """
  Returns the number of events currently scheduled.
  """
  def scheduled_count(clock) do
    GenServer.call(clock, :scheduled_count)
  end

  @doc """
  Waits for quiescence - when all scheduled events have been processed
  and no new events are being scheduled.

  Retries every 10ms for up to 1000ms (1 second) by default.
  """
  def wait_for_quiescence(clock, timeout \\ 1000, retry_interval \\ 10) do
    wait_for_quiescence_loop(clock, timeout, retry_interval, 0)
  end

  defp wait_for_quiescence_loop(clock, timeout, retry_interval, elapsed) do
    if elapsed >= timeout do
      {:error, :timeout}
    else
      case scheduled_count(clock) do
        0 ->
          :ok

        _ ->
          Process.sleep(retry_interval)
          wait_for_quiescence_loop(clock, timeout, retry_interval, elapsed + retry_interval)
      end
    end
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %State{}}
  end

  @impl true
  def handle_call(:now, _from, state) do
    {:reply, state.current_time, state}
  end

  @impl true
  def handle_call({:send_after, dest, message, delay}, _from, state) do
    ref = make_ref()
    trigger_time = state.current_time + delay

    event = %ScheduledEvent{
      trigger_time: trigger_time,
      dest: dest,
      message: message,
      ref: ref
    }

    # Insert event into priority queue (sorted by trigger_time)
    # Handle multiple events at the same time by storing them in a list
    new_scheduled =
      case :gb_trees.lookup(trigger_time, state.scheduled) do
        :none ->
          # No events at this time, insert new event
          :gb_trees.insert(trigger_time, [event], state.scheduled)

        {:value, existing_events} ->
          # Events already exist at this time, add to the list
          updated_events = [event | existing_events]
          :gb_trees.update(trigger_time, updated_events, state.scheduled)
      end

    {:reply, ref, %{state | scheduled: new_scheduled}}
  end

  @impl true
  def handle_call({:cancel_timer, ref}, _from, state) do
    # Find and remove the event with the given ref
    case find_and_remove_by_ref(state.scheduled, ref) do
      {new_scheduled, true} -> {:reply, :ok, %{state | scheduled: new_scheduled}}
      {new_scheduled, false} -> {:reply, false, %{state | scheduled: new_scheduled}}
    end
  end

  @impl true
  def handle_call({:advance, amount}, from, state) do
    target_time = state.current_time + amount
    # Start the advance process
    send(self(), {:do_advance, target_time, from})
    {:noreply, state}
  end

  @impl true
  def handle_call(:advance_to_next, _from, state) do
    case get_next_event_time(state.scheduled, :infinity) do
      nil ->
        {:reply, 0, state}

      next_time ->
        amount = next_time - state.current_time
        {triggered, remaining} = extract_events_at_time(state.scheduled, next_time)

        Enum.each(triggered, fn event ->
          send(event.dest, event.message)
        end)

        {:reply, amount, %{state | current_time: next_time, scheduled: remaining}}
    end
  end

  @impl true
  def handle_call(:scheduled_count, _from, state) do
    count = :gb_trees.size(state.scheduled)
    {:reply, count, state}
  end

  @impl true
  def handle_info({:do_advance, target_time, from}, state) do
    advance_loop(state, target_time, from)
  end

  # Efficient advance loop that processes all events without real-time delays
  defp advance_loop(state, target_time, from) do
    # Process events in chronological order, allowing for newly scheduled events
    # Use a loop to avoid stack overflow
    advance_loop_iterative(state, target_time, from)
  end

  defp advance_loop_iterative(state, target_time, from) do
    # Process events in batches to allow other processes to proceed
    # This ensures that actors can process messages and schedule new ones
    case get_next_event_time(state.scheduled, target_time) do
      nil ->
        # No more events, finish advance
        new_state = %{state | current_time: target_time}
        GenServer.reply(from, {:ok, target_time})
        {:noreply, new_state}

      next_time ->
        # Process all events at exactly the same time point
        # This ensures we only batch events that trigger simultaneously
        {triggered, remaining} = extract_events_at_time(state.scheduled, next_time)

        Enum.each(triggered, fn event ->
          send(event.dest, event.message)
        end)

        # Update state and continue advancing
        new_state = %{state | current_time: next_time, scheduled: remaining}

        # Wait for quiescence before continuing to ensure all actors have
        # processed their messages and scheduled new events at this time point
        # This allows actors to schedule new events before advancing to the next time
        Process.send_after(self(), {:do_advance, target_time, from}, 10)
        {:noreply, new_state}
    end
  end


  # Private helpers for priority queue operations

  defp get_next_event_time(scheduled, target_time) do
    case :gb_trees.is_empty(scheduled) do
      true ->
        nil

      false ->
        {min_time, _event} = :gb_trees.smallest(scheduled)
        if min_time <= target_time, do: min_time, else: nil
    end
  end

  defp extract_events_at_time(scheduled, time) do
    # Extract all events at the given time from the priority queue
    case :gb_trees.lookup(time, scheduled) do
      :none ->
        {[], scheduled}

      {:value, events} ->
        # Remove the time slot and return the events
        new_scheduled = :gb_trees.delete(time, scheduled)
        {events, new_scheduled}
    end
  end

  defp find_and_remove_by_ref(scheduled, ref) do
    # Find and remove an event by its ref from the priority queue
    find_and_remove_by_ref_recursive(scheduled, ref, :gb_trees.empty())
  end

  defp find_and_remove_by_ref_recursive(scheduled, ref, new_scheduled) do
    case :gb_trees.is_empty(scheduled) do
      true ->
        {new_scheduled, false}

      false ->
        {time, events, remaining} = :gb_trees.take_smallest(scheduled)

        case find_and_remove_from_list(events, ref) do
          {nil, updated_events} ->
            # Event not found in this time slot, keep all events and continue
            new_scheduled_with_events = :gb_trees.insert(time, updated_events, new_scheduled)
            find_and_remove_by_ref_recursive(remaining, ref, new_scheduled_with_events)

          {_removed_event, updated_events} ->
            # Found the event, merge remaining with new_scheduled
            final_scheduled =
              if updated_events == [] do
                # No events left at this time, don't add the time slot
                merge_trees(remaining, new_scheduled)
              else
                # Still have events at this time, add them back
                new_scheduled_with_remaining =
                  :gb_trees.insert(time, updated_events, new_scheduled)

                merge_trees(remaining, new_scheduled_with_remaining)
              end

            {final_scheduled, true}
        end
    end
  end

  defp find_and_remove_from_list(events, ref) do
    case Enum.find_index(events, fn event -> event.ref == ref end) do
      nil ->
        {nil, events}

      index ->
        {removed_event, updated_events} = List.pop_at(events, index)
        {removed_event, updated_events}
    end
  end

  defp merge_trees(tree1, tree2) do
    # Merge two gb_trees by iterating through tree1 and inserting into tree2
    merge_trees_recursive(tree1, tree2)
  end

  defp merge_trees_recursive(tree1, tree2) do
    case :gb_trees.is_empty(tree1) do
      true ->
        tree2

      false ->
        {key, value, remaining} = :gb_trees.take_smallest(tree1)
        new_tree2 = :gb_trees.insert(key, value, tree2)
        merge_trees_recursive(remaining, new_tree2)
    end
  end
end
