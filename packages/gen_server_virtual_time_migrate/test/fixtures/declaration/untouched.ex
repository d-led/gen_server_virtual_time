defmodule MyApp.Untouched do
  use GenServer

  # GenServer.call(pid, :get) is not virtual here, and this comment must stay put
  @doc "calls GenServer.call/3"
  def get(pid) do
    GenServer.call(pid, :get)
  end

  def message, do: "GenServer.call(MyApp.Other, :get)"
end
