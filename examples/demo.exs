#!/usr/bin/env elixir

# Demo: GenServerVirtualTime - Testing time-dependent code without waiting
#
# Run this with: mix run examples/demo.exs

defmodule DemoServer do
  @moduledoc """
  A simple ticker server that demonstrates VirtualTimeGenServer.
  """
  use VirtualTimeGenServer

  def start_link(interval) do
    VirtualTimeGenServer.start_link(__MODULE__, interval, name: __MODULE__)
  end

  def get_count do
    VirtualTimeGenServer.call(__MODULE__, :get_count)
  end

  @impl true
  def init(interval) do
    IO.puts("🚀 Server starting with #{interval}ms interval")
    schedule_tick(interval)
    {:ok, %{interval: interval, count: 0}}
  end

  @impl true
  def handle_call(:get_count, _from, state) do
    {:reply, state.count, state}
  end

  @impl true
  def handle_info(:tick, state) do
    new_count = state.count + 1
    if rem(new_count, 100) == 0 do
      IO.puts("  ✓ Tick ##{new_count}")
    end
    schedule_tick(state.interval)
    {:noreply, %{state | count: new_count}}
  end

  defp schedule_tick(interval) do
    VirtualTimeGenServer.send_after(self(), :tick, interval)
  end
end

IO.puts("""
╔═══════════════════════════════════════════════════════════╗
║       GenServerVirtualTime Demo                           ║
║       Don't Wait Forever For Your Tests!                  ║
╚═══════════════════════════════════════════════════════════╝
""")

IO.puts("📚 Demo 1: Real Time (Slow)")
IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

# Use real time
VirtualTimeGenServer.use_real_time()
{:ok, _} = DemoServer.start_link(100)

start = System.monotonic_time(:millisecond)
Process.sleep(1000)
count = DemoServer.get_count()
elapsed = System.monotonic_time(:millisecond) - start

IO.puts("⏱️  Elapsed: #{elapsed}ms (actually waited)")
IO.puts("📊 Ticks: #{count}")
GenServer.stop(DemoServer)

IO.puts("""

📚 Demo 2: Virtual Time (Instant!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

# Use virtual time
{:ok, clock} = VirtualClock.start_link()
VirtualTimeGenServer.set_virtual_clock(clock)
{:ok, _} = DemoServer.start_link(100)

start = System.monotonic_time(:millisecond)
VirtualClock.advance(clock, 10_000)  # Simulate 10 seconds
count = DemoServer.get_count()
elapsed = System.monotonic_time(:millisecond) - start

IO.puts("⏱️  Elapsed: #{elapsed}ms (instant!)")
IO.puts("📊 Ticks: #{count}")
IO.puts("🎯 Simulated: 10,000ms")
GenServer.stop(DemoServer)

IO.puts("""

📚 Demo 3: Actor Simulation - Message Pipeline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

forward = fn msg, state ->
  {:send, [{state.next_stage, msg}], state}
end

simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:source,
    send_pattern: {:periodic, 100, :data},
    targets: [:stage1]
  )
  |> ActorSimulation.add_actor(:stage1,
    on_receive: forward,
    initial_state: %{next_stage: :stage2}
  )
  |> ActorSimulation.add_actor(:stage2,
    on_receive: forward,
    initial_state: %{next_stage: :stage3}
  )
  |> ActorSimulation.add_actor(:stage3)

start = System.monotonic_time(:millisecond)
simulation = ActorSimulation.run(simulation, duration: 5000)
elapsed = System.monotonic_time(:millisecond) - start

stats = ActorSimulation.get_stats(simulation)

IO.puts("Pipeline: source → stage1 → stage2 → stage3")
IO.puts("⏱️  Elapsed: #{elapsed}ms")
IO.puts("📊 Statistics:")

Enum.each([:source, :stage1, :stage2, :stage3], fn actor ->
  actor_stats = stats.actors[actor]
  IO.puts(
    "   #{actor}: sent=#{actor_stats.sent_count}, received=#{actor_stats.received_count}"
  )
end)

ActorSimulation.stop(simulation)

IO.puts("""

📚 Demo 4: Pub-Sub Pattern
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""")

simulation =
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:publisher,
    send_pattern: {:periodic, 200, :event},
    targets: [:sub1, :sub2, :sub3]
  )
  |> ActorSimulation.add_actor(:sub1)
  |> ActorSimulation.add_actor(:sub2)
  |> ActorSimulation.add_actor(:sub3)
  |> ActorSimulation.run(duration: 2000)

stats = ActorSimulation.get_stats(simulation)

IO.puts("Publisher → [sub1, sub2, sub3]")
IO.puts("📊 Statistics:")
IO.puts("   Publisher sent: #{stats.actors[:publisher].sent_count} messages")

Enum.each([:sub1, :sub2, :sub3], fn sub ->
  IO.puts("   #{sub} received: #{stats.actors[sub].received_count} messages")
end)

ActorSimulation.stop(simulation)

IO.puts("""

╔═══════════════════════════════════════════════════════════╗
║  ✅ Demo Complete!                                         ║
║                                                            ║
║  See README.md for more examples and API documentation    ║
╚═══════════════════════════════════════════════════════════╝
""")
