# Measures how fast virtual time replays a periodic simulation.
#
# Usage: mix run benchmarks/virtual_time_speedup.exs
#
# The README's "Why virtual time" and "Performance" tables come from this script.
# It ticks once per virtual second, so the event count equals the simulated
# seconds; scale the throughput by events, not by simulated time.

defmodule VirtualTimeSpeedup do
  @cases [
    {"1 second", 1_000},
    {"10 seconds", 10_000},
    {"1 minute", 60_000},
    {"10 minutes", 600_000},
    {"1 hour", 3_600_000}
  ]

  def run do
    results = Enum.map(@cases, fn {label, duration_ms} -> measure(label, duration_ms) end)

    IO.puts("\n| Simulated time | Real time | Events | Speed-up |")
    IO.puts("| -------------- | --------- | ------ | -------- |")

    for {label, duration_ms, real_ms, events} <- results do
      IO.puts("| #{label} | #{real_ms}ms | #{events} | #{round(duration_ms / real_ms)}x |")
    end

    IO.puts("\nAverage virtual events per real second: #{round(throughput(results))}")
  end

  defp measure(label, duration_ms) do
    # Warm up the code paths, then measure
    for _ <- 1..2, do: tick(duration_ms)

    {micros, stats} = :timer.tc(fn -> tick(duration_ms) end)
    {label, duration_ms, max(div(micros, 1000), 1), stats.actors[:ticker].sent_count}
  end

  defp tick(duration_ms) do
    simulation =
      ActorSimulation.new()
      |> ActorSimulation.add_actor(:ticker, send_pattern: {:periodic, 1000, :tick}, targets: [:sink])
      |> ActorSimulation.add_actor(:sink)
      |> ActorSimulation.run(duration: duration_ms)

    stats = ActorSimulation.get_stats(simulation)
    ActorSimulation.stop(simulation)
    stats
  end

  defp throughput(results) do
    rates = Enum.map(results, fn {_label, _duration, real_ms, events} -> events / (real_ms / 1000) end)
    Enum.sum(rates) / length(rates)
  end
end

VirtualTimeSpeedup.run()
