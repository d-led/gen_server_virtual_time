defmodule MyApp.Counter do
  use GenServer

  def init(:ok), do: {:ok, 0}

  def handle_call(:get, _from, state), do: {:reply, state, state}
end
