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
    defstruct current_time: 0, scheduled: []
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

    new_scheduled = [event | state.scheduled]
    {:reply, ref, %{state | scheduled: new_scheduled}}
  end

  @impl true
  def handle_call({:cancel_timer, ref}, _from, state) do
    new_scheduled = Enum.reject(state.scheduled, fn event -> event.ref == ref end)
    result = if length(new_scheduled) < length(state.scheduled), do: :ok, else: false
    {:reply, result, %{state | scheduled: new_scheduled}}
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
    case find_next_event_time(state.scheduled) do
      nil ->
        {:reply, 0, state}

      next_time ->
        amount = next_time - state.current_time
        {triggered, remaining} = split_events(state.scheduled, next_time)

        Enum.each(triggered, fn event ->
          send(event.dest, event.message)
        end)

        {:reply, amount, %{state | current_time: next_time, scheduled: remaining}}
    end
  end

  @impl true
  def handle_call(:scheduled_count, _from, state) do
    {:reply, length(state.scheduled), state}
  end

  @impl true
  def handle_info({:do_advance, target_time, from}, state) do
    case find_next_event_time_up_to(state.scheduled, target_time) do
      nil ->
        # No more events, finish advance
        new_state = %{state | current_time: target_time}
        GenServer.reply(from, {:ok, target_time})
        {:noreply, new_state}

      next_time ->
        # Trigger all events at this exact time
        {triggered, remaining} = split_events_at_time(state.scheduled, next_time)

        Enum.each(triggered, fn event ->
          send(event.dest, event.message)
        end)

        # Update state and continue advancing
        # Add a tiny delay to allow other processes to handle messages
        new_state = %{state | current_time: next_time, scheduled: remaining}

        # Schedule continuation with a tiny delay for message processing
        # The delay allows triggered processes to handle their messages
        # and make new send_after calls that we'll process
        :erlang.send_after(0, self(), {:do_advance, target_time, from})
        {:noreply, new_state}
    end
  end

  # Private helpers

  defp split_events(scheduled, time) do
    Enum.split_with(scheduled, fn event -> event.trigger_time <= time end)
  end

  defp split_events_at_time(scheduled, time) do
    Enum.split_with(scheduled, fn event -> event.trigger_time == time end)
  end

  defp find_next_event_time([]), do: nil
  defp find_next_event_time(scheduled) do
    scheduled
    |> Enum.map(& &1.trigger_time)
    |> Enum.min()
  end

  defp find_next_event_time_up_to([], _target), do: nil
  defp find_next_event_time_up_to(scheduled, target_time) do
    scheduled
    |> Enum.filter(fn event -> event.trigger_time <= target_time end)
    |> case do
      [] -> nil
      events -> events |> Enum.map(& &1.trigger_time) |> Enum.min()
    end
  end
end
