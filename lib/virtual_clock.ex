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
              # Track which processes we're waiting for acks from
              pending_acks: MapSet.new(),
              # Track who is waiting for advance to complete
              advance_caller: nil,
              # Track the target time for current advance
              target_time: nil,
              # Pending ack watchdog, cancelled when the wait completes
              ack_timeout_ref: nil
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
    @moduledoc false
    use GenServer

    defmodule SchedulerState do
      @moduledoc false
      defstruct scheduled: :gb_trees.empty(), clock_pid: nil
    end

    def start_link(clock_pid) do
      GenServer.start_link(__MODULE__, clock_pid)
    end

    def send_after(scheduler_pid, dest, message, delay_ms) do
      GenServer.call(scheduler_pid, {:send_after, dest, message, delay_ms})
    end

    def cancel_timer(scheduler_pid, ref) do
      GenServer.call(scheduler_pid, {:cancel_timer, ref})
    end

    def get_next_events_until(scheduler_pid, target_time_ms) do
      GenServer.call(scheduler_pid, {:get_next_events_until, target_time_ms})
    end

    @impl true
    def init(clock_pid) do
      {:ok, %SchedulerState{clock_pid: clock_pid}}
    end

    @impl true
    def handle_call({:send_after, dest, message, delay_ms}, from, state) do
      # Get current time from VirtualClock asynchronously to avoid deadlock
      GenServer.cast(
        state.clock_pid,
        {:get_time_for_scheduling, self(), from, dest, message, delay_ms}
      )

      {:noreply, state}
    end

    def handle_call({:cancel_timer, ref}, _from, state) do
      case find_and_remove_by_ref(state.scheduled, ref) do
        {:found, trigger_time, new_scheduled} ->
          {:reply, {:ok, trigger_time}, %{state | scheduled: new_scheduled}}

        {:not_found, new_scheduled} ->
          {:reply, :not_found, %{state | scheduled: new_scheduled}}
      end
    end

    def handle_call({:get_next_events_until, target_time_ms}, _from, state) do
      case get_next_event_time(state.scheduled, target_time_ms) do
        nil ->
          {:reply, {nil, []}, state}

        next_time ->
          {triggered, remaining} = extract_events_at_time(state.scheduled, next_time)
          {:reply, {next_time, triggered}, %{state | scheduled: remaining}}
      end
    end

    def handle_call(:scheduled_count, _from, state) do
      {:reply, count_events_until(state.scheduled, :infinity), state}
    end

    def handle_call({:scheduled_count_until, until_time_ms}, _from, state) do
      count = count_events_until(state.scheduled, until_time_ms)
      {:reply, count, state}
    end

    @impl true
    def handle_cast(
          {:time_response_for_scheduling, current_time, original_from, dest, message, delay_ms},
          state
        ) do
      ref = make_ref()
      trigger_time = current_time + delay_ms

      # IO.puts("DEBUG SCHEDULER: Scheduling event for #{inspect(dest)} at time #{trigger_time} (current: #{current_time}, delay: #{delay_ms})")

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

    # Helper functions for VirtualScheduler
    defp get_next_event_time(scheduled, target_time_ms) do
      case :gb_trees.is_empty(scheduled) do
        true ->
          nil

        false ->
          {min_time, _event} = :gb_trees.smallest(scheduled)
          if within_horizon?(min_time, target_time_ms), do: min_time, else: nil
      end
    end

    defp within_horizon?(_time, :infinity), do: true
    defp within_horizon?(time, until_time_ms), do: time <= until_time_ms

    # Events at the same instant are prepended on insert (cheap), so the stored
    # list is newest-first. Reverse it so events due at the same time fire in
    # the order they were scheduled, exactly like real timers.
    defp extract_events_at_time(scheduled, time_ms) do
      case :gb_trees.lookup(time_ms, scheduled) do
        :none ->
          {[], scheduled}

        {:value, events} ->
          new_scheduled = :gb_trees.delete(time_ms, scheduled)
          {Enum.reverse(events), new_scheduled}
      end
    end

    defp find_and_remove_by_ref(scheduled, ref) do
      find_and_remove_by_ref_recursive(scheduled, ref, :gb_trees.empty())
    end

    defp find_and_remove_by_ref_recursive(scheduled, ref, new_scheduled) do
      case :gb_trees.is_empty(scheduled) do
        true ->
          {:not_found, new_scheduled}

        false ->
          {time, events, remaining} = :gb_trees.take_smallest(scheduled)

          case find_and_remove_from_list(events, ref) do
            {nil, updated_events} ->
              new_scheduled_with_events = :gb_trees.insert(time, updated_events, new_scheduled)
              find_and_remove_by_ref_recursive(remaining, ref, new_scheduled_with_events)

            {_removed_event, updated_events} ->
              final_scheduled =
                merge_trees(remaining, tree_at(time, updated_events, new_scheduled))

              {:found, time, final_scheduled}
          end
      end
    end

    defp tree_at(_time, [], tree), do: tree
    defp tree_at(time, events, tree), do: :gb_trees.insert(time, events, tree)

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

    defp count_events_until(scheduled, until_time_ms) do
      count_events_until_recursive(scheduled, until_time_ms, 0)
    end

    defp count_events_until_recursive(scheduled, until_time_ms, count) do
      case :gb_trees.is_empty(scheduled) do
        true ->
          count

        false ->
          {time, events, remaining} = :gb_trees.take_smallest(scheduled)

          if within_horizon?(time, until_time_ms) do
            count_events_until_recursive(remaining, until_time_ms, count + length(events))
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
  Schedules a message to be sent after a delay in virtual time (in milliseconds).
  Returns a reference that can be used to cancel the timer.
  """
  def send_after(clock, dest, message, delay_ms) do
    # Delegate to the scheduler process for fair competition
    scheduler_pid = GenServer.call(clock, :get_scheduler)
    VirtualScheduler.send_after(scheduler_pid, dest, message, delay_ms)
  end

  @doc """
  Cancels a scheduled timer.

  Mirrors `Process.cancel_timer/1`: returns the remaining virtual time in
  milliseconds until the cancelled event would have fired, or `false` if no
  event is scheduled under that reference.

  ## Examples

      iex> {:ok, clock} = VirtualClock.start_link()
      iex> ref = VirtualClock.send_after(clock, self(), :later, 500)
      iex> VirtualClock.cancel_timer(clock, ref)
      500
      iex> VirtualClock.cancel_timer(clock, ref)
      false

  """
  def cancel_timer(clock, ref) do
    GenServer.call(clock, {:cancel_timer, ref})
  end

  @doc """
  Advances the virtual clock by the specified amount of milliseconds.
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
  def advance(clock, amount_ms) do
    GenServer.call(clock, {:advance, amount_ms}, :infinity)
  end

  @doc """
  Advances the virtual clock to the next scheduled event.
  Returns the amount advanced in milliseconds, or 0 if no events are scheduled.
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
  def scheduled_count_until(clock, until_time_ms \\ nil) do
    until_time_ms = until_time_ms || now(clock)
    scheduler_pid = GenServer.call(clock, :get_scheduler)
    GenServer.call(scheduler_pid, {:scheduled_count_until, until_time_ms})
  end

  @doc """
  Waits for quiescence - when all scheduled events have been processed
  and no new events are being scheduled.

  Retries every 10ms for up to 1000ms (1 second) by default.

  ## Parameters
  - `clock`: The virtual clock process
  - `timeout_ms`: Real-time timeout in milliseconds (default: 1000)
  - `retry_interval_ms`: Retry interval in milliseconds (default: 10)
  """
  def wait_for_quiescence(clock, timeout_ms \\ 1000, retry_interval_ms \\ 10) do
    wait_for_quiescence_loop(clock, timeout_ms, retry_interval_ms, 0)
  end

  @doc """
  Waits for quiescence within a specific virtual time frame.

  This function waits for all events scheduled up to the given virtual time
  to be processed, but ignores events scheduled for later times.

  ## Parameters
  - `clock`: The virtual clock process
  - `opts`: Keyword list of options:
    - `:until_time_ms` - Maximum virtual time in milliseconds to consider (default: current time)
    - `:timeout_ms` - Real-time timeout in milliseconds (default: 1000)
    - `:retry_interval_ms` - Retry interval in milliseconds (default: 10)

  ## Examples

      # Wait for quiescence up to current time
      VirtualClock.wait_for_quiescence_until(clock)

      # Wait for quiescence up to a specific virtual time
      VirtualClock.wait_for_quiescence_until(clock, until_time_ms: 5000)

      # Wait with custom timeout and retry interval
      VirtualClock.wait_for_quiescence_until(clock,
        until_time_ms: 1000,
        timeout_ms: 500,
        retry_interval_ms: 5
      )
  """
  def wait_for_quiescence_until(clock, opts \\ []) do
    until_time_ms = Keyword.get(opts, :until_time_ms, now(clock))
    timeout_ms = Keyword.get(opts, :timeout_ms, 1000)
    retry_interval_ms = Keyword.get(opts, :retry_interval_ms, 10)

    wait_for_quiescence_until_loop(clock, until_time_ms, timeout_ms, retry_interval_ms, 0)
  end

  defp wait_for_quiescence_loop(clock, timeout_ms, retry_interval_ms, elapsed) do
    if elapsed >= timeout_ms do
      {:error, :timeout}
    else
      case scheduled_count(clock) do
        0 ->
          :ok

        _ ->
          Process.sleep(retry_interval_ms)

          wait_for_quiescence_loop(
            clock,
            timeout_ms,
            retry_interval_ms,
            elapsed + retry_interval_ms
          )
      end
    end
  end

  defp wait_for_quiescence_until_loop(
         clock,
         until_time_ms,
         timeout_ms,
         retry_interval_ms,
         elapsed
       ) do
    if elapsed >= timeout_ms do
      {:error, :timeout}
    else
      case scheduled_count_until(clock, until_time_ms) do
        0 ->
          :ok

        _ ->
          Process.sleep(retry_interval_ms)

          wait_for_quiescence_until_loop(
            clock,
            until_time_ms,
            timeout_ms,
            retry_interval_ms,
            elapsed + retry_interval_ms
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
  def handle_call({:cancel_timer, ref}, _from, state) do
    case VirtualScheduler.cancel_timer(state.scheduler_pid, ref) do
      {:ok, trigger_time} ->
        {:reply, max(trigger_time - state.current_time, 0), state}

      :not_found ->
        {:reply, false, state}
    end
  end

  @impl true
  def handle_call({:advance, amount_ms}, from, state) do
    target_time = state.current_time + amount_ms
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
        amount_ms = next_time - state.current_time

        Enum.each(triggered, fn event ->
          VirtualTimeGenServer.send_immediately(event.dest, event.message)
        end)

        {:reply, amount_ms, %{state | current_time: next_time}}
    end
  end

  @impl true
  def handle_info({:do_advance, target_time, from}, state) do
    advance_loop(state, target_time, from)
  end

  def handle_info({:continue_advance_after_acks, from, target_time}, state) do
    # Continue advance after all acks received
    send(self(), {:do_advance, target_time, from})
    {:noreply, state}
  end

  def handle_info({:ack_timeout, timed_out_acks}, state) do
    # Timeout for ack wait - remove the timed-out deliveries from pending
    require Logger

    process_info = Enum.map_join(timed_out_acks, ", ", &describe_ack/1)

    Logger.warning(
      "VirtualClock ACK timeout: #{length(timed_out_acks)} deliveries were not acknowledged in time. Deliveries: #{process_info}"
    )

    new_pending = MapSet.difference(state.pending_acks, MapSet.new(timed_out_acks))

    # If we had an advance in progress and all acks are now received (or timed out), continue
    if MapSet.size(new_pending) == 0 and state.advance_caller do
      Logger.warning(
        "VirtualClock ACK timeout: Continuing advance after timeout at virtual time #{state.target_time}"
      )

      send(self(), {:continue_advance_after_acks, state.advance_caller, state.target_time})

      {:noreply,
       %{
         state
         | pending_acks: new_pending,
           advance_caller: nil,
           target_time: nil,
           ack_timeout_ref: nil
       }}
    else
      {:noreply, %{state | pending_acks: new_pending, ack_timeout_ref: nil}}
    end
  end

  # Token acknowledgement from a VirtualTimeGenServer actor. Only a token the
  # clock is actually waiting for counts; anything else is ignored, which is
  # what makes the wait immune to unrelated actor traffic.
  def handle_info({:actor_processed, _actor_pid, token}, state) do
    if MapSet.member?(state.pending_acks, token) do
      continue_or_wait(%{state | pending_acks: MapSet.delete(state.pending_acks, token)})
    else
      {:noreply, state}
    end
  end

  def handle_info({:actor_processed, actor_pid}, state) do
    new_pending = MapSet.delete(state.pending_acks, actor_pid)
    continue_or_wait(%{state | pending_acks: new_pending})
  end

  # Resume the advance once every outstanding acknowledgement has arrived, or
  # keep waiting if some deliveries are still being processed.
  defp continue_or_wait(state) do
    if MapSet.size(state.pending_acks) == 0 and state.advance_caller do
      cancel_ack_timeout(state)
      send(self(), {:continue_advance_after_acks, state.advance_caller, state.target_time})
      {:noreply, %{state | advance_caller: nil, target_time: nil, ack_timeout_ref: nil}}
    else
      {:noreply, state}
    end
  end

  defp cancel_ack_timeout(%{ack_timeout_ref: nil}), do: :ok

  defp cancel_ack_timeout(%{ack_timeout_ref: ref}) do
    Process.cancel_timer(ref)
    :ok
  end

  # How a destination acknowledges a delivery:
  #
  #   * `:token` - a VirtualTimeGenServer actor. The delivery is tagged with a
  #     fresh token, and only that exact token is accepted as the
  #     acknowledgement. An unrelated message the actor happens to handle can
  #     therefore never satisfy a pending delivery.
  #   * `:pid` - a VirtualTimeGenStateMachine actor, which acknowledges every
  #     message it handles with its own pid.
  #   * `:none` - anything else (plain processes); never tracked.
  defp ack_mode(pid) do
    case Process.info(pid, :dictionary) do
      {:dictionary, dict} when is_list(dict) ->
        if Keyword.has_key?(dict, :virtual_clock), do: actor_ack_mode(pid, dict), else: :none

      _ ->
        :none
    end
  end

  defp actor_ack_mode(pid, dict) do
    case Keyword.get(dict, :"$initial_call") do
      {VirtualTimeGenServer.Wrapper, _, _} -> :token
      {VirtualTimeGenStateMachine.Wrapper, _, _} -> :pid
      _ -> if gen_server_process?(pid), do: :pid, else: :none
    end
  end

  defp gen_server_process?(pid) do
    case Process.info(pid, :current_function) do
      {:current_function, {mod, _, _}} -> mod in [:gen_server, :gen_statem]
      _ -> false
    end
  end

  # Pending acknowledgements are keyed either by destination pid (actors that
  # acknowledge every message) or by delivery token (actors that acknowledge
  # only the deliveries addressed to them).
  defp describe_ack(pid) when is_pid(pid) do
    name =
      case Process.info(pid, :registered_name) do
        {:registered_name, n} when is_atom(n) -> "name=#{n}"
        _ -> "pid=#{inspect(pid)}"
      end

    case Process.info(pid, :current_function) do
      {:current_function, {mod, _, _}} -> "#{name} module=#{mod}"
      _ -> name
    end
  end

  defp describe_ack(token) when is_reference(token), do: "delivery=#{inspect(token)}"

  defp advance_loop(state, target_time, from) do
    # Cancel any timeout left over from the previous step of this advance.
    if state.ack_timeout_ref, do: Process.cancel_timer(state.ack_timeout_ref)

    case VirtualScheduler.get_next_events_until(state.scheduler_pid, target_time) do
      # Nothing left to deliver up to the target: jump to the target and finish,
      # unless actors are still working through what we already delivered.
      {nil, []} ->
        state
        |> jump_to(target_time)
        |> wait_for_acks_or_finish(from, target_time)

      {next_time, triggered} when next_time <= target_time ->
        new_pending = deliver_events(triggered, state.pending_acks)
        new_state = %{state | current_time: next_time, pending_acks: new_pending}

        if MapSet.size(new_pending) > 0 do
          # Wait for the actors to process what we just delivered before moving on.
          {:noreply, arm_ack_timeout(new_state, from, target_time, target_time - next_time)}
        else
          # Nobody to wait for - carry on with the next instant immediately.
          send(self(), {:do_advance, target_time, from})
          :erlang.yield()
          {:noreply, new_state}
        end

      _future_events ->
        # Everything left is beyond the target: jump to it and finish.
        state
        |> jump_to(target_time)
        |> wait_for_acks_or_finish(from, target_time)
    end
  end

  defp jump_to(state, target_time), do: %{state | current_time: target_time}

  # Records which destinations must acknowledge before the clock may move past
  # this instant, tagging each delivery so only that exact acknowledgement counts.
  defp deliver_events(triggered, pending) do
    Enum.reduce(triggered, pending, fn event, acc ->
      case ack_mode(event.dest) do
        :token ->
          token = make_ref()
          send(event.dest, {:__vtgs_delivered__, token, event.message})
          MapSet.put(acc, token)

        :pid ->
          VirtualTimeGenServer.send_immediately(event.dest, event.message)
          MapSet.put(acc, event.dest)

        :none ->
          VirtualTimeGenServer.send_immediately(event.dest, event.message)
          acc
      end
    end)
  end

  defp wait_for_acks_or_finish(state, from, target_time) do
    if MapSet.size(state.pending_acks) > 0 do
      remaining_ms = target_time - state.current_time
      {:noreply, arm_ack_timeout(state, from, target_time, remaining_ms)}
    else
      if from, do: GenServer.reply(from, {:ok, target_time})
      {:noreply, state}
    end
  end

  # Arms the watchdog for the current wait and remembers who to answer once every
  # acknowledgement has arrived.
  defp arm_ack_timeout(state, from, target_time, remaining_ms) do
    ref =
      Process.send_after(
        self(),
        {:ack_timeout, MapSet.to_list(state.pending_acks)},
        ack_timeout_ms(remaining_ms)
      )

    %{state | advance_caller: from, target_time: target_time, ack_timeout_ref: ref}
  end

  # Long advances get a longer budget, capped at 30s, so that a simulation of
  # hours does not abort while its actors are still working.
  defp ack_timeout_ms(remaining_ms) do
    if remaining_ms > 100_000, do: min(trunc(remaining_ms / 1000), 30_000), else: 2_000
  end

  @impl true
  def handle_cast(
        {:get_time_for_scheduling, scheduler_pid, original_from, dest, message, delay_ms},
        state
      ) do
    # Reply to scheduler with current time
    GenServer.cast(
      scheduler_pid,
      {:time_response_for_scheduling, state.current_time, original_from, dest, message, delay_ms}
    )

    {:noreply, state}
  end
end
