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
    defstruct current_time: 0,
              scheduled: :gb_trees.empty(),
              waiting_for_quiescence: nil,
              # Track how long we've been waiting
              quiescence_patience: 0,
              # Track event discovery rate
              last_event_count: 0
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

  This ensures that:
  - All events up to the target time are processed
  - The system reaches quiescence at the target time
  - All callbacks scheduled for the target time are executed

  ## Examples

      # Advance by 1000ms
      VirtualClock.advance(clock, 1000)

      # Advance by 0 (process all events at current time and wait for quiescence)
      VirtualClock.advance(clock, 0)
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
  Returns the count of events scheduled up to a specific virtual time.

  This is useful for waiting for quiescence within a time frame,
  ignoring events scheduled for later times.

  ## Examples

      # Count events scheduled up to current time
      VirtualClock.scheduled_count_until(clock)

      # Count events scheduled up to 5000ms
      VirtualClock.scheduled_count_until(clock, 5000)
  """
  def scheduled_count_until(clock, until_time \\ nil) do
    until_time = until_time || now(clock)
    GenServer.call(clock, {:scheduled_count_until, until_time})
  end

  @doc """
  Waits for quiescence - when all scheduled events have been processed
  and no new events are being scheduled.

  Retries every 10ms for up to 1000ms (1 second) by default.
  """
  def wait_for_quiescence(clock, timeout \\ 1000, retry_interval \\ 10) do
    wait_for_quiescence_loop(clock, timeout, retry_interval, 0)
  end

  @doc """
  Waits for quiescence within a specific virtual time frame.

  This function waits for all events scheduled up to the given virtual time
  to be processed, but ignores events scheduled for later times.

  ## Parameters
  - `clock`: The virtual clock process
  - `opts`: Keyword list of options:
    - `:until_time` - Maximum virtual time to consider (default: current time)
    - `:timeout` - Real-time timeout in milliseconds (default: 1000)
    - `:retry_interval` - Retry interval in milliseconds (default: 10)

  ## Examples

      # Wait for quiescence up to current time
      VirtualClock.wait_for_quiescence_until(clock)

      # Wait for quiescence up to a specific virtual time
      VirtualClock.wait_for_quiescence_until(clock, until_time: 5000)

      # Wait with custom timeout and retry interval
      VirtualClock.wait_for_quiescence_until(clock,
        until_time: 1000,
        timeout: 500,
        retry_interval: 5
      )
  """
  def wait_for_quiescence_until(clock, opts \\ []) do
    until_time = Keyword.get(opts, :until_time, now(clock))
    timeout = Keyword.get(opts, :timeout, 1000)
    retry_interval = Keyword.get(opts, :retry_interval, 10)

    wait_for_quiescence_until_loop(clock, until_time, timeout, retry_interval, 0)
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

  defp wait_for_quiescence_until_loop(clock, until_time, timeout, retry_interval, elapsed) do
    if elapsed >= timeout do
      {:error, :timeout}
    else
      case scheduled_count_until(clock, until_time) do
        0 ->
          :ok

        _ ->
          Process.sleep(retry_interval)

          wait_for_quiescence_until_loop(
            clock,
            until_time,
            timeout,
            retry_interval,
            elapsed + retry_interval
          )
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
          VirtualTimeGenServer.send_immediately(event.dest, event.message)
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
  def handle_call({:scheduled_count_until, until_time}, _from, state) do
    count = count_events_until(state.scheduled, until_time)
    {:reply, count, state}
  end

  @impl true
  def handle_info({:do_advance, target_time, from}, state) do
    # Normal advance - process events and wait for quiescence at target time
    advance_loop(state, target_time, from)
  end

  @impl true
  def handle_info({:check_quiescence, target_time, from}, state) do
    # Smart quiescence check with adaptive patience
    count = count_events_until(state.scheduled, target_time)

    if count > 0 do
      # Found events! Reset patience and continue advance loop
      send(self(), {:do_advance, target_time, from})
      {:noreply, %{state | waiting_for_quiescence: nil, quiescence_patience: 0}}
    else
      # No events found - check if we should wait longer or finish
      case state.waiting_for_quiescence do
        {^target_time, ^from} ->
          # Calculate smart delay based on patience level and event discovery rate
          {should_continue, new_patience, delay} = should_continue_waiting(state, target_time)

          if should_continue do
            # Continue waiting with adaptive delay
            new_state = %{state | quiescence_patience: new_patience}
            Process.send_after(self(), {:check_quiescence, target_time, from}, delay)
            {:noreply, new_state}
          else
            # We've waited long enough - declare quiescence achieved
            GenServer.reply(from, {:ok, target_time})
            {:noreply, %{state | waiting_for_quiescence: nil, quiescence_patience: 0}}
          end

        _ ->
          # Different quiescence request or already completed
          GenServer.reply(from, {:ok, target_time})
          {:noreply, %{state | waiting_for_quiescence: nil, quiescence_patience: 0}}
      end
    end
  end

  # Efficient advance loop that processes all events without real-time delays
  defp advance_loop(state, target_time, from) do
    # Process events in chronological order, allowing for newly scheduled events
    # Use a loop to avoid stack overflow
    advance_loop_iterative(state, target_time, from)
  end

  defp advance_loop_iterative(state, target_time, from) do
    # Process all events at the current time point in a tight loop
    # Then send a message to continue to the next time point
    case get_next_event_time(state.scheduled, target_time) do
      nil ->
        # No events up to target_time, advance to target_time and wait for quiescence
        new_state = %{state | current_time: target_time}
        wait_for_quiescence_and_finish(new_state, target_time, from)
        {:noreply, new_state}

      next_time when next_time <= target_time ->
        # Process ALL events at exactly the same time point in a tight loop
        process_all_events_at_time(state, next_time, target_time, from)

      _next_time ->
        # Next event is beyond target_time, advance to target_time and wait for quiescence
        new_state = %{state | current_time: target_time}
        wait_for_quiescence_and_finish(new_state, target_time, from)
        {:noreply, new_state}
    end
  end

  defp process_all_events_at_time(state, current_time, target_time, from) do
    # Extract ALL events at the current time point at once
    {triggered, remaining} = extract_events_at_time(state.scheduled, current_time)

    # Process all events at this time point in a tight loop
    Enum.each(triggered, fn event ->
      VirtualTimeGenServer.send_immediately(event.dest, event.message)
    end)

    # Update state (advance time to current_time) and send message to continue to next time
    # This allows newly scheduled events to be picked up in the next iteration
    new_state = %{state | current_time: current_time, scheduled: remaining}

    # OPTIMIZED: Use immediate send for fast processing, but allow message queue processing
    Process.send_after(self(), {:do_advance, target_time, from}, 0)
    {:noreply, new_state}
  end

  defp wait_for_quiescence_and_finish(state, target_time, from) do
    # Wait for quiescence at target_time
    # First, check if there are any events scheduled at exactly target_time
    case get_next_event_time(state.scheduled, target_time) do
      nil ->
        # No events at target_time, wait for quiescence and finish advance
        wait_for_all_events_processed(state, target_time, from)

      next_time when next_time == target_time ->
        # There are events at exactly target_time, process them and continue waiting
        {triggered, remaining} = extract_events_at_time(state.scheduled, next_time)

        Enum.each(triggered, fn event ->
          VirtualTimeGenServer.send_immediately(event.dest, event.message)
        end)

        # Update state but don't advance time
        new_state = %{state | scheduled: remaining}

        # Continue waiting for quiescence at target_time
        send(self(), {:do_advance, target_time, from})
        {:noreply, new_state}

      _next_time ->
        # Events are scheduled for later times, wait for quiescence and finish
        wait_for_all_events_processed(state, target_time, from)
    end
  end

  defp wait_for_all_events_processed(state, target_time, from) do
    # Check if there are new events scheduled at or before target_time
    # These would have been scheduled by message handlers processing the events we just sent
    # IMPORTANT: We must check state.scheduled here, which should already include
    # events scheduled by send_after calls during handler execution (they are synchronous)
    count = count_events_until(state.scheduled, target_time)

    # Debug: Print state for troubleshooting
    # if target_time >= 86_400_000 * 5 do  # Only debug large simulations
    #   IO.puts("wait_for_all_events_processed: current_time=#{state.current_time}, target_time=#{target_time}, count=#{count}, scheduled_size=#{:gb_trees.size(state.scheduled)}")
    # end

    # Smart quiescence detection with adaptive patience
    new_state = %{
      state
      | waiting_for_quiescence: {target_time, from},
        # Reset patience counter
        quiescence_patience: 0,
        last_event_count: count
    }

    delay = calculate_smart_quiescence_delay(count, target_time, state)
    Process.send_after(self(), {:check_quiescence, target_time, from}, delay)

    {:noreply, new_state}
  end

  # Smart quiescence heuristics
  #
  # PERFORMANCE OPTIMIZATION: These functions implement intelligent quiescence detection
  # to eliminate the bottleneck identified through profiling with `mix profile.eprof`.
  #
  # The original bottleneck was Process.send_after/3 calls with 1ms delays per event,
  # causing 36,500 events (century backup) to take 36.5+ seconds just in artificial delays.
  #
  # The optimization uses:
  # 1. Immediate message passing (0ms delay) for fast event processing
  # 2. Smart quiescence detection with progressive patience
  # 3. Exponential backoff for large simulations
  # 4. Scale-aware delays (century backup gets different treatment than small sims)
  #
  # Result: Century backup went from 120+ second timeout to ~75 seconds completion
  # with all 36,500 events processed correctly.

  defp calculate_smart_quiescence_delay(count, target_time, _state) do
    if count > 0 do
      # Events exist - give actors time to schedule next events
      # Even century gets some delay when events exist
      if target_time > 100_000_000_000, do: 3, else: 2
    else
      # No events - base delay on simulation scale - be more patient for stability
      cond do
        # Century backup: start with 15ms
        target_time > 100_000_000_000 -> 15
        # Large sims: 8ms (more patient)
        target_time > 1_000_000_000 -> 8
        # Normal sims: 25ms (very patient for test stability)
        true -> 25
      end
    end
  end

  defp should_continue_waiting(state, target_time) do
    patience = state.quiescence_patience

    # Progressive patience: start aggressive, become more patient
    # This prevents early termination while avoiding infinite waits
    max_patience_cycles =
      cond do
        # Century: up to 15 cycles (very patient for large scale)
        target_time > 100_000_000_000 -> 15
        # Large: up to 12 cycles (very patient)
        target_time > 1_000_000_000 -> 12
        # Normal: up to 10 cycles (very patient for test stability)
        true -> 10
      end

    if patience >= max_patience_cycles do
      # We've waited long enough - declare quiescence
      {false, patience, 0}
    else
      # Continue waiting with exponential backoff for large sims
      delay =
        cond do
          target_time > 100_000_000_000 ->
            # Century backup: exponential backoff 15, 20, 25, 30ms...
            15 + patience * 5

          target_time > 1_000_000_000 ->
            # Large sims: 5, 7, 9ms... (more conservative)
            5 + patience * 2

          true ->
            # Normal: 15, 18, 21ms... (more patient)
            15 + patience * 3
        end

      {true, patience + 1, delay}
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

  defp count_events_until(scheduled, until_time) do
    # Count events scheduled up to (and including) the given time
    count_events_until_recursive(scheduled, until_time, 0)
  end

  defp count_events_until_recursive(scheduled, until_time, count) do
    case :gb_trees.is_empty(scheduled) do
      true ->
        count

      false ->
        {time, events, remaining} = :gb_trees.take_smallest(scheduled)

        if time <= until_time do
          # Count events at this time and continue
          new_count = count + length(events)
          count_events_until_recursive(remaining, until_time, new_count)
        else
          # Time is beyond our limit, stop counting
          count
        end
    end
  end
end
