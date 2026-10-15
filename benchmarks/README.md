# Virtual Clock Performance Benchmarks

This directory contains performance benchmarks for the GenServerVirtualTime library, focusing on core virtual clock operations and actor simulation performance.

## Running Benchmarks

### Core Virtual Clock Benchmarks

Run the core virtual clock performance benchmarks:

```bash
mix run benchmarks/virtual_clock_core_benchmarks.exs
```

This benchmark suite measures:

- **VirtualClock.advance**: Core time advancement performance (1 second, 1 minute)
- **VirtualClock.send_after**: Event scheduling performance (1 event, 100 events)
- **Periodic ticking GenServer**: GenServer with virtual time that ticks every second
- **ActorSimulation.simple**: Simple actor simulation with 10 events

There is also `virtual_time_speedup.exs`, which measures how much real time a
periodic simulation actually takes. Its numbers are quoted in the root README:

```bash
mix run benchmarks/virtual_time_speedup.exs
```

### Expected Performance

Measured on an Apple Silicon laptop (Apple M-series, Elixir 1.20, OTP 29):

| Operation | Throughput | Average | Notes |
|-----------|------------|---------|-------|
| VirtualClock.advance (1 second) | ~109 K ips | ~9 µs | Pure time advancement |
| VirtualClock.advance (1 minute) | ~110 K ips | ~9 µs | Independent of how far time jumps |
| Periodic ticking GenServer (5 ticks) | ~17 K ips | ~59 µs | Message delivery and callback execution |
| ActorSimulation.simple (10 events) | ~8.1 K ips | ~124 µs | Full simulation, stats included |
| VirtualClock.send_after (1 event) | ~6.4 K ips | ~156 µs | One schedule round trip |
| VirtualClock.send_after (100 events) | ~0.53 K ips | ~1.9 ms | ~19 µs per event |

Numbers move with the machine; the ordering does not. Run the script to measure
your own.

### Interpreting the results

1. **Advancing time is cheap and constant**: one second and one minute cost the
   same (~9 µs), because the clock's cost is the number of *events*, not the
   simulated duration.
2. **Scheduling dominates**: one `send_after/4` costs ~156 µs, roughly 17x an
   `advance/2`, and the cost is per event (~19 µs each at 100 events).
3. **Actor callbacks are the next cost**: a periodic GenServer over 5 ticks is
   ~59 µs.
4. **A full simulation adds bookkeeping**: `ActorSimulation` with 10 events is
   ~124 µs including statistics and tracing of what was sent.

So: prefer fewer, coarser timers when a simulation is large, and remember that
what you pay for is events, not simulated seconds.

## Benchmark Results

The benchmarks generate:
- **Console output** showing performance metrics
- **HTML report** at `_build/benchmarks/results.html` with detailed charts and analysis

Console output includes:
- **ips**: Iterations per second
- **average**: Average execution time
- **deviation**: Standard deviation
- **median**: Median execution time
- **99th %**: 99th percentile execution time
- **Memory usage**: Memory consumption per operation

The HTML report provides interactive charts and detailed analysis that can be opened in any web browser.

## Adding New Benchmarks

To add new benchmarks, edit `benchmarks/virtual_clock_core_benchmarks.exs`:

1. Add a new benchmark function
2. Add it to the `Benchee.run/2` map
3. Update the documentation

Example:

```elixir
defp my_new_benchmark do
  # Your benchmark code here
  :ok
end

# In the Benchee.run map:
"My New Benchmark" => fn -> my_new_benchmark() end,
```

## Dependencies

The benchmarks require:
- `benchee` ~> 1.5 (added to mix.exs as dev dependency)
- All GenServerVirtualTime modules

## Notes

- Benchmarks run with a 5-second time limit, 1-second warmup, and memory measurement
- Results are printed to console and saved as HTML under `_build/benchmarks/` (ignored by git)
- Every benchmark stops the clocks and servers it starts, so the suite can be run repeatedly
