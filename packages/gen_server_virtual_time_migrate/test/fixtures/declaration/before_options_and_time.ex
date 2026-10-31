defmodule MyApp.Ticker do
  use GenServer, restart: :transient

  def init(:ok) do
    Process.send_after(self(), :tick, 1000)
    {:ok, %{}}
  end

  def handle_info(:tick, state) do
    Process.sleep(10)
    :erlang.send_after(500, self(), :tick)
    {:noreply, state}
  end
end
