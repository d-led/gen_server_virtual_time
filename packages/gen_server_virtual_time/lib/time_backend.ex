defmodule TimeBackend do
  @moduledoc """
  Behaviour for time backends (real or virtual).
  """

  @callback send_after(pid(), term(), non_neg_integer()) :: reference()
  # delay_ms: delay in milliseconds
  @callback send_immediately(pid(), term()) :: :ok
  @callback cancel_timer(reference()) :: non_neg_integer() | false
  @callback sleep(non_neg_integer()) :: :ok
  # duration_ms: duration in milliseconds
end

defmodule RealTimeBackend do
  @moduledoc """
  Real time backend using Process.send_after/3.
  """
  @behaviour TimeBackend

  @impl true
  def send_after(dest, message, delay_ms) do
    Process.send_after(dest, message, delay_ms)
  end

  @impl true
  def send_immediately(dest, message) do
    send(dest, message)
    :ok
  end

  @impl true
  def cancel_timer(ref) do
    Process.cancel_timer(ref)
  end

  @impl true
  def sleep(duration_ms) do
    Process.sleep(duration_ms)
  end
end

defmodule VirtualTimeBackend do
  @moduledoc """
  Virtual time backend using VirtualClock.
  """
  @behaviour TimeBackend

  @impl true
  def send_after(dest, message, delay_ms) do
    clock = get_virtual_clock()
    VirtualClock.send_after(clock, dest, message, delay_ms)
  end

  @impl true
  def send_immediately(dest, message) do
    # Send immediately without scheduling - this is synchronous within virtual time
    # If we schedule at current time, it causes infinite loops in advance processing
    send(dest, message)
    :ok
  end

  @impl true
  def cancel_timer(ref) do
    clock = get_virtual_clock()
    VirtualClock.cancel_timer(clock, ref)
  end

  @impl true
  def sleep(duration_ms) do
    # Schedule a wake-up message in virtual time and wait for it
    ref = make_ref()
    send_after(self(), {:__vtgs_sleep_done__, ref}, duration_ms)

    receive do
      {:__vtgs_sleep_done__, ^ref} -> :ok
    end
  end

  defp get_virtual_clock do
    case Process.get(:virtual_clock) do
      nil ->
        raise "Virtual clock not set. Use VirtualTimeGenServer.set_virtual_clock/1"

      clock ->
        clock
    end
  end
end
