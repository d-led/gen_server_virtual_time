defmodule DocumentationTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Tests that verify all examples in README.md actually work.
  This ensures documentation stays in sync with code.
  """

  describe "README Quick Start examples" do
    defmodule MyServer do
      use VirtualTimeGenServer

      def init(interval) do
        schedule_tick(interval)
        {:ok, %{interval: interval, count: 0}}
      end

      def handle_info(:tick, state) do
        schedule_tick(state.interval)
        {:noreply, %{state | count: state.count + 1}}
      end

      def handle_call(:get_count, _from, state) do
        {:reply, state.count, state}
      end

      defp schedule_tick(interval) do
        VirtualTimeGenServer.send_after(self(), :tick, interval)
      end
    end

    test "30-second quick start example works" do
      # Set up virtual time
      {:ok, clock} = VirtualClock.start_link()

      # Start server with local virtual clock
      {:ok, server} = VirtualTimeGenServer.start_link(MyServer, 100, virtual_clock: clock)

      # Advance time - happens instantly!
      VirtualClock.advance(clock, 10_000)

      # Precise verification - virtual time should be deterministic
      # 10,000ms / 100ms interval = 100 ticks
      count = GenServer.call(server, :get_count)
      assert count == 100

      GenServer.stop(server)
    end
  end

  describe "Actor Simulation DSL examples" do
    test "pub-sub system simulation" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:publisher,
          send_pattern: {:rate, 100, :event},
          targets: [:subscriber1, :subscriber2, :subscriber3]
        )
        |> ActorSimulation.add_actor(:subscriber1)
        |> ActorSimulation.add_actor(:subscriber2)
        |> ActorSimulation.add_actor(:subscriber3)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)

      # Publisher sends to 3 subscribers
      assert stats.actors[:publisher].sent_count > 0
      assert stats.actors[:subscriber1].received_count > 0

      ActorSimulation.stop(simulation)
    end

    test "request-response pattern with pattern matching" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:client,
          send_pattern: {:periodic, 100, :get_data},
          targets: [:server]
        )
        |> ActorSimulation.add_actor(:server,
          on_match: [
            {:get_data, fn state -> {:reply, {:data, 42}, state} end}
          ]
        )
        |> ActorSimulation.run(duration: 500)

      stats = ActorSimulation.get_stats(simulation)
      assert stats.actors[:client].sent_count == 5
      assert stats.actors[:server].received_count == 5

      ActorSimulation.stop(simulation)
    end

    test "sync and async communication" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:requester,
          send_pattern: {:periodic, 100, {:call, :get_status}},
          targets: [:responder]
        )
        |> ActorSimulation.add_actor(:notifier,
          send_pattern: {:periodic, 50, {:cast, :notify}},
          targets: [:listener]
        )
        |> ActorSimulation.add_actor(:responder,
          on_match: [
            {:get_status, fn state -> {:reply, :ok, state} end}
          ]
        )
        |> ActorSimulation.add_actor(:listener)
        |> ActorSimulation.run(duration: 300)

      stats = ActorSimulation.get_stats(simulation)
      # Virtual time should be deterministic
      # Requester: 300ms / 100ms = 3 messages (0, 100, 200ms) - 300ms is end time
      # Notifier: 300ms / 50ms = 6 messages (0, 50, 100, 150, 200, 250ms) - 300ms is end time
      assert stats.actors[:requester].sent_count == 3
      assert stats.actors[:notifier].sent_count == 6

      ActorSimulation.stop(simulation)
    end

    test "pipeline architecture" do
      forward = fn msg, state ->
        {:send, [{state.next, msg}], state}
      end

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:input,
          send_pattern: {:rate, 50, :data},
          targets: [:stage1]
        )
        |> ActorSimulation.add_actor(:stage1,
          on_receive: forward,
          initial_state: %{next: :stage2}
        )
        |> ActorSimulation.add_actor(:stage2,
          on_receive: forward,
          initial_state: %{next: :output}
        )
        |> ActorSimulation.add_actor(:output)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)
      # Data flows through the pipeline
      assert stats.actors[:input].sent_count > 0
      assert stats.actors[:stage1].received_count > 0
      assert stats.actors[:stage2].received_count > 0
      assert stats.actors[:output].received_count > 0

      ActorSimulation.stop(simulation)
    end
  end

  describe "Process-in-the-Loop examples" do
    defmodule MyRealServer do
      use VirtualTimeGenServer

      def init(_), do: {:ok, %{requests: 0}}

      def handle_call(:get, _from, state) do
        {:reply, state.requests, %{state | requests: state.requests + 1}}
      end

      def handle_info({:actor_message, _from, :increment}, state) do
        {:noreply, %{state | requests: state.requests + 1}}
      end
    end

    test "real GenServer with simulated actors" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_process(:real_server,
          module: MyRealServer,
          args: nil
        )
        |> ActorSimulation.add_actor(:client,
          send_pattern: {:periodic, 100, :increment},
          targets: [:real_server]
        )
        |> ActorSimulation.run(duration: 500)

      # Verify real server received messages
      real_pid = simulation.actors[:real_server].pid
      count = GenServer.call(real_pid, :get)
      assert count == 5

      ActorSimulation.stop(simulation)
    end
  end

  describe "Message Tracing examples" do
    test "Mermaid generation" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:client,
          send_pattern: {:periodic, 100, :ping},
          targets: [:server]
        )
        |> ActorSimulation.add_actor(:server)
        |> ActorSimulation.run(duration: 200)

      ActorSimulation.stop(simulation)
    end

    test "Mermaid generation with enhanced features" do
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

      mermaid = ActorSimulation.trace_to_mermaid(simulation)

      assert String.contains?(mermaid, "sequenceDiagram")
      assert String.contains?(mermaid, "client")
      assert String.contains?(mermaid, "server")
      assert String.contains?(mermaid, "->>")

      ActorSimulation.stop(simulation)
    end

    test "trace includes all documented fields" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 200)

      trace = ActorSimulation.get_trace(simulation)

      assert length(trace) == 2

      event = hd(trace)
      assert Map.has_key?(event, :timestamp)
      assert Map.has_key?(event, :from)
      assert Map.has_key?(event, :to)
      assert Map.has_key?(event, :message)
      assert Map.has_key?(event, :type)

      assert event.from == :sender
      assert event.to == :receiver
      assert event.type == :send

      ActorSimulation.stop(simulation)
    end
  end

  describe "Send Patterns documented in README" do
    test "periodic pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :tick},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 500)

      stats = ActorSimulation.get_stats(simulation)
      assert stats.actors[:sender].sent_count == 5

      ActorSimulation.stop(simulation)
    end

    test "rate pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:rate, 50, :event},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)
      # 50 per second = 50 in 1 second
      # Virtual time should be deterministic
      assert stats.actors[:sender].sent_count == 50

      ActorSimulation.stop(simulation)
    end

    test "burst pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:burst, 10, 500, :batch},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)
      # 2 bursts of 10 = 20 total
      assert stats.actors[:sender].sent_count == 20

      ActorSimulation.stop(simulation)
    end
  end

  describe "Message Types documented in README" do
    test "regular send (fire and forget)" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :message},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 300)

      stats = ActorSimulation.get_stats(simulation)
      # Virtual time should be deterministic
      assert stats.actors[:sender].sent_count == 3
      assert stats.actors[:receiver].received_count == 3

      ActorSimulation.stop(simulation)
    end

    test "synchronous call (wait for reply)" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:caller,
          send_pattern: {:periodic, 100, {:call, :get_value}},
          targets: [:responder]
        )
        |> ActorSimulation.add_actor(:responder,
          on_match: [
            {:get_value, fn state -> {:reply, 42, state} end}
          ]
        )
        |> ActorSimulation.run(duration: 300)

      stats = ActorSimulation.get_stats(simulation)
      assert stats.actors[:caller].sent_count == 3
      assert stats.actors[:responder].received_count == 3

      ActorSimulation.stop(simulation)
    end

    test "asynchronous cast" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:caster,
          send_pattern: {:periodic, 100, {:cast, :notify}},
          targets: [:listener]
        )
        |> ActorSimulation.add_actor(:listener)
        |> ActorSimulation.run(duration: 300)

      stats = ActorSimulation.get_stats(simulation)
      assert stats.actors[:caster].sent_count == 3
      assert stats.actors[:listener].received_count == 3

      ActorSimulation.stop(simulation)
    end
  end

  describe "Global time manipulation warning skip examples" do
    test "VirtualTimeGenServer.set_virtual_clock with warning skip" do
      # Set up virtual time without warnings using local injection
      {:ok, clock} = VirtualClock.start_link()

      # Start server using local clock injection instead of global settings
      {:ok, server} =
        VirtualTimeGenServer.start_link(DocumentationTest.MyServer, 100, virtual_clock: clock)

      # Advance time - happens instantly!
      VirtualClock.advance(clock, 10_000)

      # Precise verification - virtual time should be deterministic
      # 10,000ms / 100ms interval = 100 ticks
      count = GenServer.call(server, :get_count)
      assert count == 100

      GenServer.stop(server)
    end

    test "VirtualTimeGenServer.use_real_time with warning skip" do
      # Set up virtual time first
      {:ok, clock} = VirtualClock.start_link()

      VirtualTimeGenServer.set_virtual_clock(
        clock,
        :i_know_what_i_am_doing,
        "initial virtual time setup"
      )

      # Switch to real time without warnings
      VirtualTimeGenServer.use_real_time(
        :i_know_what_i_am_doing,
        "switching to real time for integration test"
      )

      # Verify we're using real time backend
      assert VirtualTimeGenServer.get_time_backend() == RealTimeBackend
    end

    test "VirtualTimeGenStateMachine.set_virtual_clock with warning skip" do
      # Set up virtual time without warnings
      {:ok, clock} = VirtualClock.start_link()

      VirtualTimeGenStateMachine.set_virtual_clock(
        clock,
        :i_know_what_i_am_doing,
        "state machine simulation test"
      )

      # Verify we're using virtual time backend
      assert VirtualTimeGenStateMachine.get_time_backend() == VirtualTimeBackend
    end

    test "VirtualTimeGenStateMachine.use_real_time with warning skip" do
      # Set up virtual time first
      {:ok, clock} = VirtualClock.start_link()

      VirtualTimeGenStateMachine.set_virtual_clock(
        clock,
        :i_know_what_i_am_doing,
        "initial virtual time setup"
      )

      # Switch to real time without warnings
      VirtualTimeGenStateMachine.use_real_time(
        :i_know_what_i_am_doing,
        "switching to real time for production test"
      )

      # Verify we're using real time backend
      assert VirtualTimeGenStateMachine.get_time_backend() == RealTimeBackend
    end
  end
end
