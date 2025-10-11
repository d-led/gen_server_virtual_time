defmodule TimeBackend do
  @moduledoc """
  Behaviour for time backends (real or virtual).
  """

  @callback send_after(pid(), term(), non_neg_integer()) :: reference()
  @callback cancel_timer(reference()) :: non_neg_integer() | false
end

defmodule RealTimeBackend do
  @moduledoc """
  Real time backend using Process.send_after/3.
  """
  @behaviour TimeBackend

  @impl true
  def send_after(dest, message, delay) do
    Process.send_after(dest, message, delay)
  end

  @impl true
  def cancel_timer(ref) do
    Process.cancel_timer(ref)
  end
end

defmodule VirtualTimeBackend do
  @moduledoc """
  Virtual time backend using VirtualClock.
  """
  @behaviour TimeBackend

  @impl true
  def send_after(dest, message, delay) do
    clock = get_virtual_clock()
    VirtualClock.send_after(clock, dest, message, delay)
  end

  @impl true
  def cancel_timer(ref) do
    clock = get_virtual_clock()
    VirtualClock.cancel_timer(clock, ref)
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
