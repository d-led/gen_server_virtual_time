#!/usr/bin/env elixir

# Advanced Demo: Process-in-the-Loop, Pattern Matching, Message Tracing
#
# Run this with: mix run examples/advanced_demo.exs

defmodule RealCounterServer do
  @moduledoc """
  A real GenServer to demonstrate Process-in-the-Loop.
  """
  use VirtualTimeGenServer

  def init(initial) do
    IO.puts("  📌 Real GenServer initialized with count=#{initial}")
    {:ok, %{count: initial}}
  end

  def handle_call(:get, _from, state) do
    {:reply, state.count, state}
  end

  def handle_cast(:increment, state) do
    {:noreply, %{state | count: state.count + 1}}
  end

  def handle_info({:actor_message, _from, :increment}, state) do
    {:noreply, %{state | count: state.count + 1}}
  end
end

IO.puts("""
╔══════════════════════════════════════════════════════════════╗
║       GenServerVirtualTime - Advanced Features Demo          ║
║         Process-in-the-Loop | Pattern Matching | Tracing     ║
╚══════════════════════════════════════════════════════════════╝
""")

IO.puts("📚 Demo 1: Process-in-the-Loop (Hardware-in-the-Loop for Processes)")
IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
IO.puts("Testing REAL GenServers alongside simulated actors...")
IO.puts("")

simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_process(:real_counter,
    module: RealCounterServer,
    args: 0
  )
  |> ActorSimulation.add_actor(:incrementer,
    send_pattern: {:periodic, 100, :increment},
    targets: [:real_counter]
  )
  |> ActorSimulation.run(duration: 500)

counter_pid = simulation.actors[:real_counter].pid
final_count = GenServer.call(counter_pid, :get)

IO.puts("✅ Result: Real GenServer was incremented #{final_count} times by simulated actor")
IO.puts("   (Real process + Simulated actor working together)")
ActorSimulation.stop(simulation)

IO.puts("""

📚 Demo 2: Pattern Matching Responses
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Declarative message handling with pattern matching...
""")

simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:api_server,
    on_match: [
      {:get_user, fn state -> {:reply, {:ok, "John Doe"}, state} end},
      {:get_posts, fn state -> {:reply, {:ok, ["Post1", "Post2"]}, state} end},
      {:ping, fn state -> {:reply, :pong, state} end}
    ]
  )
  |> ActorSimulation.add_actor(:client,
    send_pattern: {:burst, 3, 100, [:ping, :get_user, :get_posts]},
    targets: [:api_server]
  )
  |> ActorSimulation.run(duration: 200)

stats = ActorSimulation.get_stats(simulation)
IO.puts("✅ Client sent: #{stats.actors[:client].sent_count} requests")
IO.puts("✅ Server received: #{stats.actors[:api_server].received_count} requests")
IO.puts("   (Pattern matching automatically routed messages)")
ActorSimulation.stop(simulation)

IO.puts("""

📚 Demo 3: Sync vs Async Communication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Demonstrating {:call, msg} and {:cast, msg} patterns...
""")

simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:responder,
    on_match: [
      {:sync_request, fn state -> {:reply, :sync_response, state} end}
    ]
  )
  |> ActorSimulation.add_actor(:sync_client,
    send_pattern: {:periodic, 100, {:call, :sync_request}},
    targets: [:responder]
  )
  |> ActorSimulation.add_actor(:async_client,
    send_pattern: {:periodic, 150, {:cast, :async_notify}},
    targets: [:responder]
  )
  |> ActorSimulation.run(duration: 500)

stats = ActorSimulation.get_stats(simulation)
IO.puts("✅ Sync client (call): #{stats.actors[:sync_client].sent_count} requests")
IO.puts("✅ Async client (cast): #{stats.actors[:async_client].sent_count} notifications")
IO.puts("   (Both patterns working in same simulation)")
ActorSimulation.stop(simulation)

IO.puts("""

📚 Demo 4: Message Tracing → Sequence Diagrams
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Capturing all messages for visualization...
""")

simulation =
  ActorSimulation.new(trace: true)
  |> ActorSimulation.add_actor(:client,
    send_pattern: {:periodic, 100, :request},
    targets: [:server]
  )
  |> ActorSimulation.add_actor(:server,
    on_match: [
      {:request,
       fn state ->
         {:send, [{:client, :response}, {:logger, :log_entry}], state}
       end}
    ]
  )
  |> ActorSimulation.add_actor(:logger)
  |> ActorSimulation.run(duration: 300)

trace = ActorSimulation.get_trace(simulation)
IO.puts("✅ Captured #{length(trace)} message events")
IO.puts("")
IO.puts("Trace events:")

Enum.each(Enum.take(trace, 6), fn event ->
  IO.puts("   t=#{event.timestamp}ms: #{event.from} → #{event.to} [#{event.type}] #{inspect(event.message)}")
end)

IO.puts("")

# Generate Mermaid diagram
mermaid = ActorSimulation.trace_to_mermaid(simulation)
IO.puts("Generated Mermaid sequence diagram:")
IO.puts(mermaid)

ActorSimulation.stop(simulation)

IO.puts("""

📚 Demo 5: Complex Request-Response Pipeline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
API → Auth → Database → Response chain...
""")

auth_handler = fn msg, state ->
  case msg do
    {:check_auth, user} ->
      if user == :valid_user do
        {:send, [{:database, {:query, user}}], state}
      else
        {:ok, state}
      end

    _ ->
      {:ok, state}
  end
end

db_handler = fn msg, state ->
  case msg do
    {:query, user} ->
      {:send, [{:api, {:data, "User data for #{user}"}}], state}

    _ ->
      {:ok, state}
  end
end

simulation =
  ActorSimulation.new(trace: true)
  |> ActorSimulation.add_actor(:api,
    send_pattern: {:periodic, 100, {:check_auth, :valid_user}},
    targets: [:auth]
  )
  |> ActorSimulation.add_actor(:auth, on_receive: auth_handler)
  |> ActorSimulation.add_actor(:database, on_receive: db_handler)
  |> ActorSimulation.run(duration: 500)

stats = ActorSimulation.get_stats(simulation)
IO.puts("✅ API requests: #{stats.actors[:api].sent_count}")
IO.puts("✅ Auth processed: #{stats.actors[:auth].received_count}")
IO.puts("✅ Database queries: #{stats.actors[:database].received_count}")
IO.puts("✅ API responses received: #{stats.actors[:api].received_count}")

trace = ActorSimulation.get_trace(simulation)
IO.puts("")
IO.puts("Message flow (first 3 requests):")

trace
|> Enum.take(9)
|> Enum.each(fn event ->
  IO.puts("   #{event.from} → #{event.to}: #{inspect(event.message)}")
end)

ActorSimulation.stop(simulation)

IO.puts("""

╔══════════════════════════════════════════════════════════════╗
║  ✅ Advanced Features Demo Complete!                          ║
║                                                               ║
║  Key Features Demonstrated:                                   ║
║  • Process-in-the-Loop: Mix real & simulated processes       ║
║  • Pattern Matching: Declarative message handling            ║
║  • Sync/Async: {:call, msg} and {:cast, msg}                 ║
║  • Message Tracing: Capture all communication                ║
║  • Sequence Diagrams: Auto-generate Mermaid                  ║
║                                                               ║
║  See README.md for complete documentation                    ║
╚══════════════════════════════════════════════════════════════╝
""")
