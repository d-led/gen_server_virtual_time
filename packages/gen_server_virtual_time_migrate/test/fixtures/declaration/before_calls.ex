defmodule MyApp.Client do
  use GenServer

  def init(:ok), do: {:ok, %{}}

  def call_counter do
    GenServer.call(MyApp.Counter, :get)
  end

  def call_plain do
    GenServer.call(MyApp.Plain, :get)
  end

  def call_dynamic(pid) do
    GenServer.cast(pid, :ping)
  end
end
