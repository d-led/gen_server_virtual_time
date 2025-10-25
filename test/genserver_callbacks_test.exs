defmodule GenServerCallbacksTest do
  use ExUnit.Case, async: true

  # Test server that uses all GenServer callbacks
  defmodule TestServer do
    use VirtualTimeGenServer

    def start_link(opts \\ []) do
      VirtualTimeGenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    # Client API
    def get_state(server \\ __MODULE__) do
      GenServer.call(server, :get_state)
    end

    def async_increment(server \\ __MODULE__) do
      GenServer.cast(server, :increment)
    end

    def schedule_work(server \\ __MODULE__, delay) do
      send(server, {:schedule, delay})
    end

    # Callbacks
    @impl true
    def init(opts) do
      initial_count = Keyword.get(opts, :initial_count, 0)
      {:ok, %{count: initial_count, messages_received: []}}
    end

    @impl true
    def handle_call(:get_state, _from, state) do
      {:reply, state, state}
    end

    @impl true
    def handle_call({:sync_increment, amount}, _from, state) do
      new_count = state.count + amount
      {:reply, new_count, %{state | count: new_count}}
    end

    @impl true
    def handle_cast(:increment, state) do
      {:noreply, %{state | count: state.count + 1}}
    end

    @impl true
    def handle_info({:schedule, delay}, state) do
      # Use VirtualTimeGenServer.send_after for virtual time
      VirtualTimeGenServer.send_after(self(), :delayed_work, delay)
      {:noreply, state}
    end

    @impl true
    def handle_info(:delayed_work, state) do
      new_state = %{
        state
        | count: state.count + 10,
          messages_received: [:delayed_work | state.messages_received]
      }

      {:noreply, new_state}
    end

    @impl true
    def handle_info(msg, state) do
      {:noreply, %{state | messages_received: [msg | state.messages_received]}}
    end
  end

  describe "handle_call (synchronous RPC)" do
    test "works with virtual time" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = TestServer.start_link(initial_count: 5)

      # Synchronous call
      result = GenServer.call(server, {:sync_increment, 3})
      assert result == 8

      state = TestServer.get_state(server)
      assert state.count == 8

      GenServer.stop(clock)
    end

    test "multiple calls in sequence" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = TestServer.start_link(initial_count: 0)

      assert GenServer.call(server, {:sync_increment, 1}) == 1
      assert GenServer.call(server, {:sync_increment, 2}) == 3
      assert GenServer.call(server, {:sync_increment, 3}) == 6

      GenServer.stop(clock)
    end
  end

  describe "handle_cast (async messages)" do
    test "processes async messages" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = TestServer.start_link(initial_count: 0)

      # Send multiple casts
      TestServer.async_increment(server)
      TestServer.async_increment(server)
      TestServer.async_increment(server)

      # Give time for messages to process
      Process.sleep(10)

      state = TestServer.get_state(server)
      assert state.count == 3

      GenServer.stop(clock)
    end
  end

  describe "handle_info with send_after (virtual time)" do
    test "send_after triggers handle_info after virtual time" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = TestServer.start_link(initial_count: 0)

      # Schedule work for 1000ms in the future
      TestServer.schedule_work(server, 1000)

      # Immediately check - work not done yet
      Process.sleep(10)
      state = TestServer.get_state(server)
      assert state.count == 0

      # Advance virtual time
      VirtualClock.advance(clock, 1000)

      # Now work should be done
      Process.sleep(10)
      state = TestServer.get_state(server)
      assert state.count == 10
      assert :delayed_work in state.messages_received

      GenServer.stop(clock)
    end

    test "multiple send_after with different delays (using advance)" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = TestServer.start_link(initial_count: 0)

      # Schedule multiple works at different times
      TestServer.schedule_work(server, 100)
      TestServer.schedule_work(server, 200)
      TestServer.schedule_work(server, 300)

      # Advance to each event and let it process
      VirtualClock.advance(clock, 150)
      # Sync point
      _ = TestServer.get_state(server)

      VirtualClock.advance(clock, 100)
      # Sync point
      _ = TestServer.get_state(server)

      VirtualClock.advance(clock, 250)
      # Sync point
      _ = TestServer.get_state(server)

      state = TestServer.get_state(server)
      # All 3 should have triggered
      assert state.count == 30
      assert length(state.messages_received) >= 3

      GenServer.stop(clock)
    end
  end

  describe "immediate sends (handle_info)" do
    test "immediate send via send/2" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = TestServer.start_link()

      # Immediate send
      send(server, :immediate_message)

      Process.sleep(10)

      state = TestServer.get_state(server)
      assert :immediate_message in state.messages_received

      GenServer.stop(clock)
    end

    test "send_after with delay 0 is immediate" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = TestServer.start_link(initial_count: 0)

      VirtualTimeGenServer.send_after(server, :work, 0)

      # Should be scheduled in virtual clock at current time
      VirtualClock.advance(clock, 0)
      Process.sleep(10)

      state = TestServer.get_state(server)
      assert :work in state.messages_received

      GenServer.stop(clock)
    end
  end

  describe "combining all callback types" do
    test "call, cast, and timed messages work together" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = TestServer.start_link(initial_count: 0)

      # Synchronous call
      # count = 5
      GenServer.call(server, {:sync_increment, 5})

      # Async cast
      # count = 6
      GenServer.cast(server, :increment)
      Process.sleep(5)

      # Schedule delayed work
      TestServer.schedule_work(server, 500)

      # Check state before delay
      state = TestServer.get_state(server)
      assert state.count == 6

      # Advance time
      VirtualClock.advance(clock, 500)
      Process.sleep(10)

      # Check state after delay
      state = TestServer.get_state(server)
      # 6 + 10 from delayed work
      assert state.count == 16

      GenServer.stop(clock)
    end
  end
end
