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
- **VirtualClock.schedule_event**: Event scheduling performance (single and multiple events)
- **Periodic ticking GenServer**: GenServer with virtual time that ticks every second
- **ActorSimulation.simple**: Simple actor simulation with 10 events

### Expected Performance

Based on the latest benchmark results:

| Operation | Performance | Notes |
|-----------|-------------|-------|
| VirtualClock.advance (1 second) | ~248,270 ips | Very fast - pure time advancement |
| VirtualClock.advance (1 minute) | ~221,228 ips | Similar performance for longer durations |
| VirtualClock.schedule_event | ~929 ips | Includes event scheduling overhead |
| Periodic ticking GenServer (5 ticks) | ~180 ips | GenServer callback execution |
| ActorSimulation.simple (10 events) | ~93 ips | Full actor simulation |
| VirtualClock.schedule_multiple_events | ~9 ips | 100 events scheduled and processed |

### Performance Analysis

The benchmarks reveal the performance characteristics:

1. **Pure time advancement is very fast** (~250k operations/second)
2. **Event scheduling adds overhead** (~1ms per event)
3. **GenServer callbacks are the bottleneck** (~5ms for 5 ticks)
4. **ActorSimulation has additional overhead** (~11ms for 10 events)
5. **Multiple events scale poorly** (~108ms for 100 events)

### Bottleneck Identification

The main bottleneck is in the virtual clock's advance mechanism when processing multiple events. The `Process.send_after(self(), {:do_advance, target_time, from}, 0)` call creates a real-time delay for each event, which accumulates for large numbers of events.

### Optimization Opportunities

1. **Batch event processing**: Process multiple events at the same time point in a single pass
2. **Reduce Process.send_after overhead**: Use direct message passing where possible
3. **Event scheduling optimization**: Use more efficient data structures for scheduled events

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

- Benchmarks run with 5-second time limit and 1-second warmup
- Memory usage is measured for each operation
- Results are printed to console and saved as HTML report
- HTML reports are saved to `_build/benchmarks/` (ignored by git)
- All benchmarks include proper cleanup (stopping GenServers)
