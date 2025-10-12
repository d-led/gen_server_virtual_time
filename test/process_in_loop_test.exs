defmodule ProcessInLoopTest do
  use ExUnit.Case, async: false

  # A real GenServer to test
  defmodule RealCounter do
    use VirtualTimeGenServer

    def init(initial) do
      {:ok, %{count: initial}}
    end

    def handle_call(:get, _from, state) do
      {:reply, state.count, state}
    end

    def handle_call(:increment, _from, state) do
      {:reply, :ok, %{state | count: state.count + 1}}
    end

    def handle_cast(:increment, state) do
      {:noreply, %{state | count: state.count + 1}}
    end

    def handle_info({:actor_message, _from, :increment}, state) do
      {:noreply, %{state | count: state.count + 1}}
    end
  end

  describe "Process-in-the-Loop" do
    test "can add real GenServer to simulation" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_process(:counter, module: RealCounter, args: 0)

      assert Map.has_key?(simulation.actors, :counter)
      assert simulation.actors[:counter].type == :real_process

      ActorSimulation.stop(simulation)
    end

    test "simulated actor can send messages to real process" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_process(:counter, module: RealCounter, args: 0)
        |> ActorSimulation.add_actor(:incrementer,
          send_pattern: {:periodic, 100, :increment},
          targets: [:counter]
        )
        |> ActorSimulation.run(duration: 1000)

      # Get the counter value
      counter_pid = simulation.actors[:counter].pid
      count = GenServer.call(counter_pid, :get)

      # Should have incremented 10 times
      assert count == 10

      ActorSimulation.stop(simulation)
    end

    test "synchronous calls to real process work" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_process(:counter, module: RealCounter, args: 5)
        |> ActorSimulation.add_actor(:caller,
          send_pattern: {:periodic, 100, {:call, :get}},
          targets: [:counter]
        )
        |> ActorSimulation.run(duration: 500)

      # Verify simulation ran
      stats = ActorSimulation.get_stats(simulation)
      assert stats.actors[:caller].sent_count == 5

      ActorSimulation.stop(simulation)
    end
  end

  describe "Pattern matching responses" do
    test "responds to messages based on pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:responder,
          on_match: [
            {:ping, fn state -> {:reply, :pong, state} end},
            {:hello, fn state -> {:reply, :world, state} end}
          ]
        )
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :ping},
          targets: [:responder]
        )
        |> ActorSimulation.run(duration: 500)

      stats = ActorSimulation.get_stats(simulation)
      assert stats.actors[:sender].sent_count == 5
      assert stats.actors[:responder].received_count == 5

      ActorSimulation.stop(simulation)
    end

    test "pattern matching with function predicates" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:matcher,
          on_match: [
            {fn
               {:add, _a, _b} -> true
               _ -> false
             end,
             fn state ->
               {:reply, 42, state}
             end}
          ]
        )
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, {:add, 1, 2}},
          targets: [:matcher]
        )
        |> ActorSimulation.run(duration: 300)

      stats = ActorSimulation.get_stats(simulation)
      assert stats.actors[:sender].sent_count == 3

      ActorSimulation.stop(simulation)
    end
  end

  describe "Sync and async messaging" do
    test "synchronous calls with {:call, message}" do
      on_receive = fn msg, state ->
        case msg do
          {:call, :ping} -> {:reply, :pong, state}
          _ -> {:ok, state}
        end
      end

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:server, on_receive: on_receive)
        |> ActorSimulation.add_actor(:client,
          send_pattern: {:periodic, 100, {:call, :ping}},
          targets: [:server]
        )
        |> ActorSimulation.run(duration: 500)

      stats = ActorSimulation.get_stats(simulation)
      assert stats.actors[:client].sent_count == 5
      assert stats.actors[:server].received_count == 5

      ActorSimulation.stop(simulation)
    end

    test "asynchronous casts with {:cast, message}" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, {:cast, :notify}},
          targets: [:receiver]
        )
        |> ActorSimulation.run(duration: 500)

      stats = ActorSimulation.get_stats(simulation)
      assert stats.actors[:sender].sent_count == 5
      assert stats.actors[:receiver].received_count == 5

      ActorSimulation.stop(simulation)
    end
  end

  describe "Message tracing" do
    test "captures message traces when enabled" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :hello},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 300)

      trace = ActorSimulation.get_trace(simulation)

      assert length(trace) == 3

      assert Enum.all?(trace, fn event ->
               event.from == :sender and
                 event.to == :receiver and
                 event.message == :hello and
                 event.type == :send
             end)

      ActorSimulation.stop(simulation)
    end

    test "generates Mermaid sequence diagram" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:client,
          send_pattern: {:periodic, 100, :request},
          targets: [:server]
        )
        |> ActorSimulation.add_actor(:server,
          on_match: [
            {:request, fn state -> {:send, [{:client, :response}], state} end}
          ]
        )
        |> ActorSimulation.run(duration: 200)



      ActorSimulation.stop(simulation)
    end

    test "generates Mermaid sequence diagram with enhanced features" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:alice,
          send_pattern: {:periodic, 100, :hello},
          targets: [:bob]
        )
        |> ActorSimulation.add_actor(:bob,
          on_match: [
            {:hello, fn state -> {:send, [{:alice, :hi}], state} end}
          ]
        )
        |> ActorSimulation.run(duration: 200)

      mermaid = ActorSimulation.trace_to_mermaid(simulation)

      assert String.contains?(mermaid, "sequenceDiagram")
      assert String.contains?(mermaid, "alice")
      assert String.contains?(mermaid, "bob")
      assert String.contains?(mermaid, "->>")
      assert String.contains?(mermaid, ":hello")

      ActorSimulation.stop(simulation)
    end

    test "trace includes timestamps from virtual clock" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :tick},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 300)

      trace = ActorSimulation.get_trace(simulation)

      # Timestamps should be approximately 100ms apart (virtual time)
      timestamps = Enum.map(trace, & &1.timestamp)
      assert length(timestamps) == 3
      # First event at ~100ms, second at ~200ms, third at ~300ms
      assert Enum.all?(timestamps, &(&1 > 0))

      ActorSimulation.stop(simulation)
    end

    test "trace distinguishes call, cast, and send" do
      # Send three different types of messages in separate patterns
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.add_actor(:regular_sender,
          send_pattern: {:periodic, 100, :regular},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:call_sender,
          send_pattern: {:periodic, 100, {:call, :sync}},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:cast_sender,
          send_pattern: {:periodic, 100, {:cast, :async}},
          targets: [:receiver]
        )
        |> ActorSimulation.run(duration: 150)

      trace = ActorSimulation.get_trace(simulation)

      types = Enum.map(trace, & &1.type)
      assert :send in types
      assert :call in types
      assert :cast in types

      ActorSimulation.stop(simulation)
    end
  end
end
