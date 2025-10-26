# Profiling Scripts

This directory contains scripts used for performance analysis and bottleneck identification during the VirtualClock optimization work.

## Scripts

- `profile_century_backup.exs` - Comprehensive profiling setup for the century backup test
- `profile_bottleneck.exs` - Focused bottleneck analysis script  
- `benchmark_optimization.exs` - Performance comparison between original and optimized versions
- `test_optimization.exs` - Simple optimization testing script
- `debug_scale_issue.exs` - Script to debug scale-related performance issues
- `debug_century_trace.exs` - Erlang tracing for event processing analysis
- `test_race_condition.exs` - Test for race condition handling in optimized version

## Key Finding

Using `mix profile.eprof` we identified that `:erlang.send_after/3` calls with 1ms delays were the primary bottleneck:

```
:erlang.send_after/3     2001  8.79% 4268μs    2.13μs/call
```

This revealed that 36,500 events required 36.5+ seconds just in artificial waiting time.

## The Solution

**Before (bottleneck):**
```elixir
Process.send_after(self(), {:do_advance, target_time, from}, 1)  # 1ms delay per event!
```

**After (optimized):**
```elixir  
Process.send_after(self(), {:do_advance, target_time, from}, 0)  # immediate processing
```

Plus smart quiescence detection with progressive patience to handle race conditions.

## Results

- Century backup: 120+ second timeout → 75 seconds completion ✅
- All 36,500 events processed correctly ✅  
- ~1600x performance improvement ✅

