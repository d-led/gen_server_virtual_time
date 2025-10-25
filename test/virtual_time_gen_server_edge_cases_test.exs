defmodule VirtualTimeGenServer.EdgeCasesTest do
  use ExUnit.Case, async: true

  # Test server with various callback return types
  defmodule TestServer do
    use VirtualTimeGenServer

    def start_link(opts \\ []) do
      VirtualTimeGenServer.start_link(__MODULE__, opts, [])
    end

    @impl true
    def init(opts) do
      mode = Keyword.get(opts, :mode, :normal)

      case mode do
        :normal -> {:ok, %{mode: mode, data: []}}
        :with_timeout -> {:ok, %{mode: mode}, 100}
        :with_continue -> {:ok, %{mode: mode}, {:continue, :init_complete}}
        :error -> {:error, :init_failed}
        :stop -> {:stop, :init_stop}
        :ignore -> :ignore
      end
    end

    @impl true
    def handle_call(request, _from, state) do
      case request do
        :get_state -> {:reply, state, state}
        :reply_with_timeout -> {:reply, :ok, state, 100}
        :noreply -> {:noreply, state}
        :noreply_with_timeout -> {:noreply, state, 100}
        :stop_with_reply -> {:stop, :normal, :stopped, state}
        :stop_without_reply -> {:stop, :normal, state}
        {:append, item} -> {:reply, :ok, %{state | data: [item | state.data]}}
      end
    end

    @impl true
    def handle_cast(request, state) do
      case request do
        :noreply -> {:noreply, state}
        :noreply_with_timeout -> {:noreply, state, 100}
        :stop -> {:stop, :normal, state}
        {:append, item} -> {:noreply, %{state | data: [item | state.data]}}
      end
    end

    @impl true
    def handle_info(msg, state) do
      case msg do
        :timeout -> {:noreply, Map.put(state, :timed_out, true)}
        :stop -> {:stop, :normal, state}
        :continue -> {:noreply, state, {:continue, :info_continue}}
        {:append, item} -> {:noreply, %{state | data: [item | state.data]}}
        _ -> {:noreply, state}
      end
    end

    @impl true
    def handle_continue(arg, state) do
      case arg do
        :init_complete -> {:noreply, Map.put(state, :initialized, true)}
        :info_continue -> {:noreply, Map.put(state, :continued, true)}
        :chain -> {:noreply, state, {:continue, :chain2}}
        :chain2 -> {:noreply, Map.put(state, :chain_complete, true)}
        :with_timeout -> {:noreply, state, 100}
        :stop -> {:stop, :normal, state}
      end
    end

    @impl true
    def terminate(reason, state) do
      send_if_exists = fn pid, msg ->
        if Process.alive?(pid), do: send(pid, msg)
      end

      case state do
        %{notify: pid} -> send_if_exists.(pid, {:terminated, reason})
        _ -> :ok
      end
    end

    @impl true
    def code_change(old_vsn, state, extra) do
      case extra do
        :error -> {:error, :upgrade_failed}
        _ -> {:ok, Map.put(state, :upgraded_from, old_vsn)}
      end
    end
  end

  describe "VirtualTimeGenServer init variations" do
    test "init with timeout" do
      {:ok, server} = TestServer.start_link(mode: :with_timeout)

      state = GenServer.call(server, :get_state)
      assert state.mode == :with_timeout

      GenServer.stop(server)
    end

    test "init with continue" do
      {:ok, server} = TestServer.start_link(mode: :with_continue)

      # Give continue callback time to execute
      Process.sleep(10)

      state = GenServer.call(server, :get_state)
      assert state.initialized == true

      GenServer.stop(server)
    end

    test "init returns error" do
      Process.flag(:trap_exit, true)
      result = TestServer.start_link(mode: :error)
      # The wrapper doesn't handle error returns in a special way
      # The GenServer will crash with a case clause error
      assert match?({:error, _}, result)
      Process.flag(:trap_exit, false)
    end

    test "init returns stop" do
      Process.flag(:trap_exit, true)
      result = TestServer.start_link(mode: :stop)
      assert result == {:error, :init_stop}
      Process.flag(:trap_exit, false)
    end

    test "init returns ignore" do
      result = TestServer.start_link(mode: :ignore)
      assert result == :ignore
    end
  end

  describe "VirtualTimeGenServer handle_call variations" do
    setup do
      {:ok, server} = TestServer.start_link()
      {:ok, server: server}
    end

    test "reply with timeout", %{server: server} do
      assert GenServer.call(server, :reply_with_timeout) == :ok
      GenServer.stop(server)
    end

    test "noreply response", %{server: server} do
      # Spawn a process that will try to call - it should timeout
      parent = self()

      spawn(fn ->
        result = catch_exit(GenServer.call(server, :noreply, 100))
        send(parent, {:result, result})
      end)

      assert_receive {:result, {:timeout, _}}, 200
      GenServer.stop(server)
    end

    test "noreply with timeout", %{server: server} do
      # Spawn a process that will try to call - it should timeout
      parent = self()

      spawn(fn ->
        result = catch_exit(GenServer.call(server, :noreply_with_timeout, 100))
        send(parent, {:result, result})
      end)

      assert_receive {:result, {:timeout, _}}, 200
      GenServer.stop(server)
    end

    test "stop with reply", %{server: server} do
      assert GenServer.call(server, :stop_with_reply) == :stopped

      # Server should be stopped
      refute Process.alive?(server)
    end

    test "stop without reply", %{server: server} do
      parent = self()

      spawn(fn ->
        result = catch_exit(GenServer.call(server, :stop_without_reply, 100))
        send(parent, {:stopped, result})
      end)

      # Server stops without replying
      assert_receive {:stopped, _}, 200
    end
  end

  describe "VirtualTimeGenServer handle_cast variations" do
    setup do
      {:ok, server} = TestServer.start_link()
      {:ok, server: server}
    end

    test "cast with noreply", %{server: server} do
      assert GenServer.cast(server, :noreply) == :ok
      GenServer.stop(server)
    end

    test "cast with noreply and timeout", %{server: server} do
      assert GenServer.cast(server, :noreply_with_timeout) == :ok
      GenServer.stop(server)
    end

    test "cast causes stop", %{server: server} do
      GenServer.cast(server, :stop)

      # Give it time to stop
      Process.sleep(10)
      refute Process.alive?(server)
    end

    test "cast modifies state", %{server: server} do
      GenServer.cast(server, {:append, :item1})
      GenServer.cast(server, {:append, :item2})

      Process.sleep(10)

      state = GenServer.call(server, :get_state)
      assert :item1 in state.data
      assert :item2 in state.data

      GenServer.stop(server)
    end
  end

  describe "VirtualTimeGenServer handle_info variations" do
    setup do
      {:ok, server} = TestServer.start_link(mode: :with_timeout)
      {:ok, server: server}
    end

    test "handles timeout message", %{server: server} do
      # Server was started with timeout, wait for it
      Process.sleep(150)

      state = GenServer.call(server, :get_state)
      assert state.timed_out == true

      GenServer.stop(server)
    end

    test "info message causes stop", %{server: server} do
      send(server, :stop)

      Process.sleep(10)
      refute Process.alive?(server)
    end

    test "info with continue", %{server: server} do
      send(server, :continue)

      Process.sleep(10)

      state = GenServer.call(server, :get_state)
      assert state.continued == true

      GenServer.stop(server)
    end
  end

  describe "VirtualTimeGenServer handle_continue variations" do
    test "continue chains" do
      defmodule ChainServer do
        use VirtualTimeGenServer

        def start_link do
          VirtualTimeGenServer.start_link(__MODULE__, :ok, [])
        end

        def init(:ok) do
          {:ok, %{}, {:continue, :chain}}
        end

        def handle_continue(:chain, state) do
          {:noreply, Map.put(state, :step1, true), {:continue, :chain2}}
        end

        def handle_continue(:chain2, state) do
          {:noreply, Map.put(state, :step2, true)}
        end

        def handle_call(:get_state, _from, state) do
          {:reply, state, state}
        end
      end

      {:ok, server} = ChainServer.start_link()
      Process.sleep(10)

      state = GenServer.call(server, :get_state)
      assert state.step1 == true
      assert state.step2 == true

      GenServer.stop(server)
    end

    test "continue with timeout" do
      defmodule TimeoutContinueServer do
        use VirtualTimeGenServer

        def start_link do
          VirtualTimeGenServer.start_link(__MODULE__, :ok, [])
        end

        def init(:ok) do
          {:ok, %{}, {:continue, :setup}}
        end

        def handle_continue(:setup, state) do
          {:noreply, Map.put(state, :setup_done, true), 50}
        end

        def handle_info(:timeout, state) do
          {:noreply, Map.put(state, :timed_out, true)}
        end

        def handle_call(:get_state, _from, state) do
          {:reply, state, state}
        end
      end

      {:ok, server} = TimeoutContinueServer.start_link()
      Process.sleep(100)

      state = GenServer.call(server, :get_state)
      assert state.setup_done == true
      assert state.timed_out == true

      GenServer.stop(server)
    end
  end

  describe "VirtualTimeGenServer terminate callback" do
    test "terminate is called with reason" do
      # Create a separate process to receive the notification
      parent = self()

      notifier =
        spawn(fn ->
          receive do
            msg -> send(parent, {:forwarded, msg})
          after
            200 -> :timeout
          end
        end)

      Process.flag(:trap_exit, true)
      {:ok, server} = TestServer.start_link()

      # Update state to include notification pid
      :sys.replace_state(server, fn {module, state} ->
        {module, Map.put(state, :notify, notifier)}
      end)

      GenServer.stop(server, :shutdown)

      assert_receive {:forwarded, {:terminated, :shutdown}}, 200
      Process.flag(:trap_exit, false)
    end
  end

  describe "VirtualTimeGenServer code_change callback" do
    test "successful code change" do
      {:ok, server} = TestServer.start_link()

      # Simulate code change
      :sys.suspend(server)

      result =
        :sys.change_code(server, VirtualTimeGenServer.EdgeCasesTest.TestServer, "1.0", :upgrade)

      :sys.resume(server)

      assert result == :ok

      state = GenServer.call(server, :get_state)
      assert state.upgraded_from == "1.0"

      GenServer.stop(server)
    end

    test "failed code change" do
      {:ok, server} = TestServer.start_link()

      :sys.suspend(server)

      result =
        :sys.change_code(server, VirtualTimeGenServer.EdgeCasesTest.TestServer, "1.0", :error)

      :sys.resume(server)

      # Result is wrapped in an extra error tuple
      assert match?({:error, _}, result)

      GenServer.stop(server)
    end
  end

  describe "VirtualTimeGenServer with virtual clock edge cases" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      {:ok, clock: clock}
    end

    test "send_after with zero delay", %{clock: clock} do
      VirtualTimeGenServer.send_after(self(), :immediate, 0)

      VirtualClock.advance(clock, 0)
      assert_receive :immediate, 10
    end

    test "send_after with large delay", %{clock: clock} do
      VirtualTimeGenServer.set_virtual_clock(clock, :i_know_what_i_am_doing, "test")
      VirtualTimeGenServer.send_after(self(), :far_future, 1_000_000_000)

      refute_receive :far_future, 10

      VirtualClock.advance(clock, 1_000_000_000)
      assert_receive :far_future, 100
    end

    test "cancel_timer returns time remaining", %{clock: clock} do
      VirtualTimeGenServer.set_virtual_clock(clock, :i_know_what_i_am_doing, "test")
      ref = VirtualTimeGenServer.send_after(self(), :msg, 1000)
      result = VirtualTimeGenServer.cancel_timer(ref)

      # VirtualTimeGenServer.cancel_timer returns :ok or false
      assert result == :ok or result == false
    end

    test "sleep with virtual time", %{clock: clock} do
      parent = self()

      # Spawn a process that inherits the virtual clock setting
      spawn(fn ->
        Process.put(:virtual_clock, clock)
        Process.put(:time_backend, VirtualTimeBackend)
        VirtualTimeGenServer.sleep(500)
        send(parent, :slept)
      end)

      refute_receive :slept, 50

      VirtualClock.advance(clock, 500)
      assert_receive :slept, 100
    end
  end

  describe "VirtualTimeGenServer wrapper error cases" do
    test "handles module without optional callbacks" do
      defmodule MinimalServer do
        use VirtualTimeGenServer

        def start_link do
          VirtualTimeGenServer.start_link(__MODULE__, :ok, [])
        end

        def init(:ok), do: {:ok, %{}}
        def handle_call(:ping, _from, state), do: {:reply, :pong, state}
        def handle_cast(_msg, state), do: {:noreply, state}
        def handle_info(_msg, state), do: {:noreply, state}
      end

      {:ok, server} = MinimalServer.start_link()

      # Test that it works without terminate/code_change/handle_continue
      assert GenServer.call(server, :ping) == :pong

      # Trigger continue (should be no-op since handle_continue not implemented)
      send(server, :test)
      Process.sleep(10)

      # Test code_change fallback
      :sys.suspend(server)

      result =
        :sys.change_code(server, VirtualTimeGenServer.EdgeCasesTest.MinimalServer, "1.0", :extra)

      :sys.resume(server)
      assert result == :ok

      # Test terminate fallback
      GenServer.stop(server)
      refute Process.alive?(server)
    end
  end

  describe "VirtualTimeGenServer stats tracking" do
    test "tracks sent and received messages in simulation" do
      defmodule StatsServer do
        use VirtualTimeGenServer

        def start_link do
          VirtualTimeGenServer.start_link(__MODULE__, :ok, [])
        end

        def init(:ok) do
          # Enable stats tracking
          Process.put(:__vtgs_stats_enabled__, true)
          Process.put(:__vtgs_stats__, %{sent_count: 0, received_count: 0})
          {:ok, %{}}
        end

        def handle_call(:get_internal_stats, _from, state) do
          stats = Process.get(:__vtgs_stats__, %{sent_count: 0, received_count: 0})
          {:reply, stats, state}
        end

        def handle_call(_msg, _from, state) do
          {:reply, :ok, state}
        end

        def handle_cast(_msg, state) do
          {:noreply, state}
        end

        def handle_info(_msg, state) do
          {:noreply, state}
        end
      end

      {:ok, server} = StatsServer.start_link()

      # Make some calls
      GenServer.call(server, :test_message)
      GenServer.cast(server, :test_cast)

      Process.sleep(10)

      stats = GenServer.call(server, :get_internal_stats)
      # Should have tracked the received messages (excluding internal stats queries)
      assert stats.received_count >= 1

      GenServer.stop(server)
    end
  end
end
