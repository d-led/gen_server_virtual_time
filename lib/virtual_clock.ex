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
              scheduler_pid: nil,
              pending_acks: MapSet.new(),  # Track which processes we're waiting for acks from
              advance_caller: nil,         # Track who is waiting for advance to complete
              target_time: nil             # Track the target time for current advance
  end

  defmodule ScheduledEvent do
    @moduledoc false
    defstruct [:trigger_time, :dest, :message, :ref]
  end

  # VirtualScheduler - Normal priority process that handles event scheduling

  # TODO: FUTURE ARCHITECTURE - 2-Process Design
  # Currently we have VirtualClock (low priority) + VirtualScheduler (normal priority)
  # which works well, but we could explore a more decoupled design:
  # - VirtualClock: Pure time coordination (low priority)
  # - VirtualScheduler: Event scheduling competing fairly with actors (normal priority)
  # This would eliminate any remaining synchronization complexity and give
  # actors and scheduler completely equal scheduling opportunities.
  defmodule VirtualScheduler do
    use GenServer

    defmodule SchedulerState do
      defstruct scheduled: :gb_trees.empty(), clock_pid: nil
    end

    def start_link(clock_pid) do
      GenServer.start_link(__MODULE__, clock_pid)
    end

    def send_after(scheduler_pid, dest, message, delay) do
      GenServer.call(scheduler_pid, {:send_after, dest, message, delay})
    end

    def cancel_timer(scheduler_pid, ref) do
      GenServer.call(scheduler_pid, {:cancel_timer, ref})
    end

    def get_next_events_until(scheduler_pid, target_time) do
      GenServer.call(scheduler_pid, {:get_next_events_until, target_time})
    end

    def get_current_time(scheduler_pid) do
      GenServer.call(scheduler_pid, :get_current_time)
    end

    def set_current_time(scheduler_pid, new_time) do
      GenServer.call(scheduler_pid, {:set_current_time, new_time})
    end

    @impl true
    def init(clock_pid) do
      {:ok, %SchedulerState{clock_pid: clock_pid}}
    end

  @impl true
  def handle_call({:send_after, dest, message, delay}, from, state) do
    # Get current time from VirtualClock asynchronously to avoid deadlock
    GenServer.cast(state.clock_pid, {:get_time_for_scheduling, self(), from, dest, message, delay})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:time_response_for_scheduling, current_time, original_from, dest, message, delay}, state) do
    ref = make_ref()
    trigger_time = current_time + delay

    # IO.puts("DEBUG SCHEDULER: Scheduling event for #{inspect(dest)} at time #{trigger_time} (current: #{current_time}, delay: #{delay})")

    event = %ScheduledEvent{
      trigger_time: trigger_time,
      dest: dest,
      message: message,
      ref: ref
    }

    new_scheduled =
      case :gb_trees.lookup(trigger_time, state.scheduled) do
        :none ->
          :gb_trees.insert(trigger_time, [event], state.scheduled)
        {:value, existing_events} ->
          updated_events = [event | existing_events]
          :gb_trees.update(trigger_time, updated_events, state.scheduled)
      end

    # Reply to original caller with the reference
    GenServer.reply(original_from, ref)
    {:noreply, %{state | scheduled: new_scheduled}}
  end

    @impl true
    def handle_call({:cancel_timer, ref}, _from, state) do
      case find_and_remove_by_ref(state.scheduled, ref) do
        {new_scheduled, true} -> {:reply, :ok, %{state | scheduled: new_scheduled}}
        {new_scheduled, false} -> {:reply, false, %{state | scheduled: new_scheduled}}
      end
    end

    @impl true
    def handle_call({:get_next_events_until, target_time}, _from, state) do
      case get_next_event_time(state.scheduled, target_time) do
        nil ->
          {:reply, {nil, []}, state}
        next_time when next_time <= target_time ->
          {triggered, remaining} = extract_events_at_time(state.scheduled, next_time)
          {:reply, {next_time, triggered}, %{state | scheduled: remaining}}
        _next_time ->
          {:reply, {nil, []}, state}
      end
    end

    @impl true
    def handle_call(:scheduled_count, _from, state) do
      count = :gb_trees.size(state.scheduled)
      {:reply, count, state}
    end

    @impl true
    def handle_cast({:count_events_until, until_time, reply_to}, state) do
      count = count_events_until(state.scheduled, until_time)
      # IO.puts("DEBUG SCHEDULER: Counting events until #{until_time}, found #{count} events")
      GenServer.cast(reply_to, {:event_count_response, count, until_time})
      {:noreply, state}
    end

    # Helper functions for VirtualScheduler
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
      case :gb_trees.lookup(time, scheduled) do
        :none ->
          {[], scheduled}
        {:value, events} ->
          new_scheduled = :gb_trees.delete(time, scheduled)
          {events, new_scheduled}
      end
    end

    defp find_and_remove_by_ref(scheduled, ref) do
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
              new_scheduled_with_events = :gb_trees.insert(time, updated_events, new_scheduled)
              find_and_remove_by_ref_recursive(remaining, ref, new_scheduled_with_events)
            {_removed_event, updated_events} ->
              final_scheduled =
                if updated_events == [] do
                  merge_trees(remaining, new_scheduled)
                else
                  new_scheduled_with_remaining = :gb_trees.insert(time, updated_events, new_scheduled)
                  merge_trees(remaining, new_scheduled_with_remaining)
                end
              {final_scheduled, true}
          end
      end
    end

    defp find_and_remove_from_list(events, ref) do
      case Enum.find_index(events, fn event -> event.ref == ref end) do
        nil -> {nil, events}
        index ->
          {removed_event, updated_events} = List.pop_at(events, index)
          {removed_event, updated_events}
      end
    end

    defp merge_trees(tree1, tree2) do
      merge_trees_recursive(tree1, tree2)
    end

    defp merge_trees_recursive(tree1, tree2) do
      case :gb_trees.is_empty(tree1) do
        true -> tree2
        false ->
          {key, value, remaining} = :gb_trees.take_smallest(tree1)
          new_tree2 = :gb_trees.insert(key, value, tree2)
          merge_trees_recursive(remaining, new_tree2)
      end
    end

    defp count_events_until(scheduled, until_time) do
      count_events_until_recursive(scheduled, until_time, 0)
    end

    defp count_events_until_recursive(scheduled, until_time, count) do
      case :gb_trees.is_empty(scheduled) do
        true -> count
        false ->
          {time, events, remaining} = :gb_trees.take_smallest(scheduled)
          if time <= until_time do
            new_count = count + length(events)
            count_events_until_recursive(remaining, until_time, new_count)
          else
            count
          end
      end
    end
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
    # Delegate to the scheduler process for fair competition
    scheduler_pid = GenServer.call(clock, :get_scheduler)
    VirtualScheduler.send_after(scheduler_pid, dest, message, delay)
  end

  @doc """
  Cancels a scheduled timer.
  """
  def cancel_timer(clock, ref) do
    # Delegate to the scheduler process
    scheduler_pid = GenServer.call(clock, :get_scheduler)
    VirtualScheduler.cancel_timer(scheduler_pid, ref)
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
    scheduler_pid = GenServer.call(clock, :get_scheduler)
    GenServer.call(scheduler_pid, :scheduled_count)
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
    scheduler_pid = GenServer.call(clock, :get_scheduler)
    GenServer.call(scheduler_pid, {:scheduled_count_until, until_time})
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
    # Set low priority so actor processes get scheduled first when we yield
    # This works in combination with yielding for reliable message ordering
    Process.flag(:priority, :low)

    # Start the scheduler process at normal priority for fair competition
    {:ok, scheduler_pid} = VirtualScheduler.start_link(self())

    {:ok, %State{scheduler_pid: scheduler_pid}}
  end

  @impl true
  def handle_call(:now, _from, state) do
    {:reply, state.current_time, state}
  end

  @impl true
  def handle_call(:get_scheduler, _from, state) do
    {:reply, state.scheduler_pid, state}
  end

  @impl true
  def handle_call({:advance, amount}, from, state) do
    target_time = state.current_time + amount
    # Start the advance process immediately, then yield
      send(self(), {:do_advance, target_time, from})
    :erlang.yield()
      {:noreply, state}
  end

  @impl true
  def handle_call(:advance_to_next, _from, state) do
    case VirtualScheduler.get_next_events_until(state.scheduler_pid, :infinity) do
      {nil, []} ->
        {:reply, 0, state}

      {next_time, triggered} ->
        amount = next_time - state.current_time

        Enum.each(triggered, fn event ->
          VirtualTimeGenServer.send_immediately(event.dest, event.message)
        end)

        {:reply, amount, %{state | current_time: next_time}}
    end
  end

  @impl true
  def handle_info({:do_advance, target_time, from}, state) do
    advance_loop(state, target_time, from)
  end

  @impl true
  def handle_info({:continue_advance_after_acks, from, target_time}, state) do
    # Continue advance after all acks received
    send(self(), {:do_advance, target_time, from})
    {:noreply, state}
  end

  defp advance_loop(state, target_time, from) do
    # Get next events from scheduler until target_time
    case VirtualScheduler.get_next_events_until(state.scheduler_pid, target_time) do
      {nil, []} ->
        # No events up to target_time - advance to target and check quiescence
        new_state = %{state | current_time: target_time}
        wait_for_scheduler_quiescence(new_state, target_time, from)

      {next_time, triggered} when next_time <= target_time ->
        # Process events at next_time - track who we're sending to for acks
        actor_pids = Enum.map(triggered, fn event ->
          VirtualTimeGenServer.send_immediately(event.dest, event.message)
          event.dest
        end)

        # Track pending acks and update time
        new_pending = MapSet.new(actor_pids) |> MapSet.union(state.pending_acks)
        new_state = %{state | current_time: next_time, pending_acks: new_pending}

        # IO.puts("DEBUG: Sent #{length(actor_pids)} messages at time #{next_time}, pending_acks: #{MapSet.size(new_pending)}")

        # Don't immediately continue - wait for acks first, then check scheduler
        if MapSet.size(new_pending) > 0 do
          # Actors are processing - store caller and wait for all acks
          {:noreply, %{new_state | advance_caller: from, target_time: target_time}}
        else
          # No actors to wait for - continue immediately
          send(self(), {:do_advance, target_time, from})
          :erlang.yield()
        {:noreply, new_state}
        end

      _future_events ->
        # Next events are beyond target_time - advance to target and check quiescence
        new_state = %{state | current_time: target_time}
        wait_for_scheduler_quiescence(new_state, target_time, from)
    end
  end

  defp wait_for_scheduler_quiescence(state, target_time, from) do
    # Only check scheduler if no actors are still processing
    if MapSet.size(state.pending_acks) > 0 do
      # Still have actors processing - wait for them first
      # IO.puts("DEBUG: Waiting for #{MapSet.size(state.pending_acks)} pending acks before checking scheduler")
      {:noreply, %{state | advance_caller: from, target_time: target_time}}
    else
      # No pending acks - safe to check scheduler
      # IO.puts("DEBUG: No pending acks, checking scheduler for events")
      GenServer.cast(state.scheduler_pid, {:count_events_until, target_time, self()})
      {:noreply, %{state | advance_caller: from, target_time: target_time}}
    end
  end

  @impl true
  def handle_cast({:get_time_for_scheduling, scheduler_pid, original_from, dest, message, delay}, state) do
    # Reply to scheduler with current time
    GenServer.cast(scheduler_pid, {:time_response_for_scheduling, state.current_time, original_from, dest, message, delay})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:event_count_response, count, target_time}, state) do
    # Response from scheduler about event count
    pending_acks = MapSet.size(state.pending_acks)
    # IO.puts("DEBUG: Scheduler reports #{count} events, pending_acks: #{pending_acks}")

    if count > 0 do
      # More events found - continue processing
      # IO.puts("DEBUG: More events found - continuing advance")
      send(self(), {:do_advance, target_time, state.advance_caller})
      :erlang.yield()
      {:noreply, %{state | advance_caller: nil}}
    else
      # Check if we're still waiting for acks from actors
      if pending_acks > 0 do
        # Still waiting for actors to acknowledge - keep waiting
        # IO.puts("DEBUG: No scheduler events, but waiting for #{pending_acks} acks")
        {:noreply, state}
      else
        # No pending events and no pending acks - advance complete!
        # IO.puts("DEBUG: Quiescence achieved at #{target_time}")
        if state.advance_caller do
          GenServer.reply(state.advance_caller, {:ok, target_time})
        end
        {:noreply, %{state | advance_caller: nil}}
      end
    end
  end

  # Handle acknowledgment from actors that they've finished processing
  @impl true
  def handle_info({:actor_processed, actor_pid}, state) do
    new_pending = MapSet.delete(state.pending_acks, actor_pid)
    new_state = %{state | pending_acks: new_pending}

    # IO.puts("DEBUG: Received ack from #{inspect(actor_pid)}, remaining: #{MapSet.size(new_pending)}")

    # If no more pending acks and someone is waiting for advance to complete
    if MapSet.size(new_pending) == 0 and state.advance_caller do
      # We need to continue advancing to the target time!
      # All acks received - continue advancing
      send(self(), {:continue_advance_after_acks, state.advance_caller, state.target_time})
      {:noreply, %{new_state | advance_caller: nil, target_time: nil}}
    else
      {:noreply, new_state}
    end
  end

end
