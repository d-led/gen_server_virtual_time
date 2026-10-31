defmodule MyApp.Ticker do
  use VirtualTimeGenServer, restart: :transient

  def init(:ok) do
    VirtualTimeGenServer.send_after(self(), :tick, 1000)
    {:ok, %{}}
  end

  def handle_info(:tick, state) do
    VirtualTimeGenServer.sleep(10)
    VirtualTimeGenServer.send_after(500, self(), :tick)
    {:noreply, state}
  end
end
