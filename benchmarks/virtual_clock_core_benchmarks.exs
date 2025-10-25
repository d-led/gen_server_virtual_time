# Virtual Clock Core Performance Benchmarks
# Run with: mix run benchmarks/virtual_clock_core_benchmarks.exs
#
# These benchmarks focus on core virtual clock operations that should run
# quickly and repeatedly to identify performance bottlenecks.

defmodule VirtualClockCoreBenchmarks do
  @moduledoc """
  Benchmarks for core virtual clock operations to identify performance bottlenecks.
  """

  def run_benchmarks do
    IO.puts("🚀 Starting Virtual Clock Core Performance Benchmarks...")
    IO.puts("=" |> String.duplicate(60))

    Benchee.run(
      %{
        "VirtualClock.advance (1 second)" => fn -> advance_one_second() end,
        "VirtualClock.advance (1 minute)" => fn -> advance_one_minute() end,
        "VirtualClock.schedule_event" => fn -> schedule_single_event() end,
        "VirtualClock.schedule_multiple_events" => fn -> schedule_multiple_events() end,
        "Periodic ticking GenServer (5 ticks)" => fn -> periodic_ticking_benchmark() end,
        "ActorSimulation.simple (10 events)" => fn -> simple_actor_simulation() end
      },
      time: 5,
      memory_time: 2,
      warmup: 1,
      formatters: [
        Benchee.Formatters.Console
      ]
    )

    IO.puts("\n🏆 Core Benchmark Results:")
    IO.puts("   - VirtualClock.advance: Core time advancement performance")
    IO.puts("   - VirtualClock.schedule_event: Event scheduling performance")
    IO.puts("   - VirtualTimeGenServer: GenServer with virtual time performance")
    IO.puts("   - ActorSimulation: Simple actor simulation performance")
    IO.puts("\n📊 Check benchmarks/results/ for detailed HTML reports")
  end

  # Benchmark: VirtualClock.advance for 1 second
  defp advance_one_second do
    {:ok, clock} = VirtualClock.start_link()
    VirtualClock.advance(clock, 1000)
    GenServer.stop(clock)
    :ok
  end

  # Benchmark: VirtualClock.advance for 1 minute
  defp advance_one_minute do
    {:ok, clock} = VirtualClock.start_link()
    VirtualClock.advance(clock, 60_000)
    GenServer.stop(clock)
    :ok
  end


  # Benchmark: Schedule a single event
  defp schedule_single_event do
    {:ok, clock} = VirtualClock.start_link()
    VirtualClock.send_after(clock, self(), :test_message, 1000)
    VirtualClock.advance(clock, 1000)
    GenServer.stop(clock)
    :ok
  end

  # Benchmark: Schedule multiple events
  defp schedule_multiple_events do
    {:ok, clock} = VirtualClock.start_link()

    # Schedule 100 events at different times
    for i <- 1..100 do
      VirtualClock.send_after(clock, self(), {:test_message, i}, i * 10)
    end

    VirtualClock.advance(clock, 1000)
    GenServer.stop(clock)
    :ok
  end


  # Benchmark: Periodic ticking GenServer with advance time
  defp periodic_ticking_benchmark do
    {:ok, clock} = VirtualClock.start_link()

    # Start a periodic ticking GenServer
    {:ok, server} = VirtualTimeGenServer.start_link(PeriodicTicker, %{}, virtual_clock: clock)

    # Advance time by 5 seconds (should trigger 5 ticks)
    VirtualClock.advance(clock, 5000)

    # Get the tick count
    count = VirtualTimeGenServer.call(server, :get_tick_count)

    # Assert we got the expected number of ticks
    assert count >= 5, "Expected at least 5 ticks, got #{count}"

    GenServer.stop(server)
    GenServer.stop(clock)
    count
  end

  # Benchmark: Simple actor simulation
  defp simple_actor_simulation do
    simulation =
      ActorSimulation.new()
      |> ActorSimulation.add_actor(:sender,
        send_pattern: {:periodic, 100, :message},
        targets: [:receiver]
      )
      |> ActorSimulation.add_actor(:receiver)
      |> ActorSimulation.run(duration: 1000)  # 1 second simulation

    ActorSimulation.stop(simulation)
    :ok
  end

  defp assert(condition, message \\ "Assertion failed") do
    unless condition do
      raise ArgumentError, message
    end
  end
end

# Test server modules for benchmarking
defmodule BenchmarkTestServer do
  use VirtualTimeGenServer

  def init(_args) do
    {:ok, %{count: 0}}
  end

  def handle_call(:increment, _from, state) do
    {:reply, :ok, %{state | count: state.count + 1}}
  end

  def handle_call(:get_count, _from, state) do
    {:reply, state.count, state}
  end
end

defmodule PeriodicTicker do
  use VirtualTimeGenServer

  def init(_args) do
    # Schedule the first tick
    VirtualTimeGenServer.send_after(self(), :tick, 1000)
    {:ok, %{tick_count: 0}}
  end

  def handle_info(:tick, state) do
    # Increment tick count and schedule next tick
    new_state = %{state | tick_count: state.tick_count + 1}
    VirtualTimeGenServer.send_after(self(), :tick, 1000)
    {:noreply, new_state}
  end

  def handle_call(:get_tick_count, _from, state) do
    {:reply, state.tick_count, state}
  end
end

# Create results directory
File.mkdir_p("benchmarks/results")

# Run the benchmarks
VirtualClockCoreBenchmarks.run_benchmarks()
