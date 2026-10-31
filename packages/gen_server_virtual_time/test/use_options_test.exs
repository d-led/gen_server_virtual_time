defmodule UseOptionsTest do
  use ExUnit.Case, async: true

  defmodule TransientServer do
    use VirtualTimeGenServer, restart: :transient

    def init(:ok), do: {:ok, %{}}
  end

  defmodule DefaultServer do
    use VirtualTimeGenServer

    def init(:ok), do: {:ok, %{}}
  end

  describe "the options given to `use`" do
    test "reach GenServer, so a restart strategy means what it means there" do
      assert TransientServer.child_spec([])[:restart] == :transient
    end

    test "leave GenServer's own defaults alone when none are given" do
      refute Map.has_key?(DefaultServer.child_spec([]), :restart)
    end
  end
end
