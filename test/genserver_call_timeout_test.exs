defmodule GenServerCallTimeoutTest do
  use ExUnit.Case, async: true

  defmodule SlowServer do
    use VirtualTimeGenServer

    def start_link(opts \\ []) do
      VirtualTimeGenServer.start_link(__MODULE__, opts, [])
    end

    def init(_opts) do
      {:ok, %{}}
    end

    def handle_call(:slow_operation, _from, state) do
      # Simulate slow operation by delaying reply
      VirtualTimeGenServer.send_after(self(), {:reply_delayed, :result}, 2000)
      {:noreply, state}
    end

    def handle_call(:instant_operation, _from, state) do
      {:reply, :instant_result, state}
    end

    def handle_info({:reply_delayed, result}, state) do
      # This won't work - we already lost the from reference
      {:noreply, Map.put(state, :delayed_result, result)}
    end
  end

  describe "GenServer.call timeout (current limitation)" do
    @tag timeout: 5_000
    test "timeout uses real time (not virtual time yet)" do
      {:ok, clock} = VirtualClock.start_link()
      # Use test-local virtual clock instead of global to avoid race conditions

      {:ok, server} = SlowServer.start_link(virtual_clock: clock)

      # This timeout is in REAL time, not virtual time
      # So it will timeout in 100ms real time even if we advance virtual time
      assert_raise RuntimeError, fn ->
        try do
          GenServer.call(server, :slow_operation, 100)
        catch
          :exit, {:timeout, _} -> raise RuntimeError, "Timeout as expected"
        end
      end

      GenServer.stop(clock)
    end

    @tag timeout: 2_000
    test "instant operations work fine" do
      {:ok, clock} = VirtualClock.start_link()
      # Use test-local virtual clock instead of global to avoid race conditions

      {:ok, server} = SlowServer.start_link(virtual_clock: clock)

      result = GenServer.call(server, :instant_operation, 5000)
      assert result == :instant_result

      GenServer.stop(clock)
    end
  end

  describe "Workaround for timeout scenarios" do
    defmodule AsyncServer do
      use VirtualTimeGenServer

      def start_link(opts \\ []) do
        VirtualTimeGenServer.start_link(__MODULE__, nil, opts)
      end

      def init(_) do
        {:ok, %{pending_ops: %{}}}
      end

      def handle_cast({:start_slow_op, caller}, state) do
        # Schedule result delivery
        VirtualTimeGenServer.send_after(self(), {:complete_op, caller}, 2000)
        {:noreply, state}
      end

      def handle_info({:complete_op, caller}, state) do
        # Send result back to caller
        VirtualTimeGenServer.send_immediately(caller, {:op_result, :success})
        {:noreply, state}
      end
    end

    @tag timeout: 3_000
    test "use async pattern for virtual time delays" do
      {:ok, clock} = VirtualClock.start_link()
      # Use test-local virtual clock instead of global to avoid race conditions
      {:ok, server} = AsyncServer.start_link(virtual_clock: clock)

      # Start async operation
      GenServer.cast(server, {:start_slow_op, self()})

      # Small delay to ensure cast is processed before advancing
      Process.sleep(10)

      # Advance virtual time
      VirtualClock.advance(clock, 2000)

      # Receive result
      assert_receive {:op_result, :success}, 100

      GenServer.stop(clock)
    end
  end
end
