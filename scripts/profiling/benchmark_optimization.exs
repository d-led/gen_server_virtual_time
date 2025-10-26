#!/usr/bin/env elixir

# Performance comparison: Original vs Optimized VirtualClock
# This will prove the bottleneck elimination

Code.compile_file("lib/virtual_clock.ex")
Code.compile_file("virtual_clock_optimized.ex")

defmodule OptimizationBenchmark do
  @moduledoc """
  Benchmarks to prove the optimization eliminates the Process.send_after bottleneck.
  
  Expected results:
  - Original: ~2.3ms per event (due to real-time delays)
  - Optimized: <1µs per event (pure synchronous processing)
  """

  def run_comparison do
    IO.puts("🚀 OPTIMIZATION BENCHMARK: Original vs Optimized VirtualClock")
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("Problem: Original uses Process.send_after causing real 1ms delays")
    IO.puts("Solution: Optimized uses synchronous processing")
    IO.puts("")

    # Test different scales
    Enum.each([10, 100, 1000], fn events ->
      IO.puts("📊 Testing #{events} events:")
      IO.puts("-" <> String.duplicate("-", 30))
      
      # Benchmark original
      {original_time, _} = :timer.tc(fn ->
        benchmark_original_virtual_clock(events)
      end)
      
      # Benchmark optimized  
      {optimized_time, _} = :timer.tc(fn ->
        benchmark_optimized_virtual_clock(events)
      end)
      
      original_us_per_event = div(original_time, events)
      optimized_us_per_event = div(optimized_time, events)
      speedup = div(original_time, max(optimized_time, 1))
      
      IO.puts("Original:  #{div(original_time, 1000)}ms total (#{original_us_per_event}µs/event)")
      IO.puts("Optimized: #{div(optimized_time, 1000)}ms total (#{optimized_us_per_event}µs/event)")
      IO.puts("Speedup:   #{speedup}x faster")
      
      if speedup > 100 do
        IO.puts("✅ MASSIVE IMPROVEMENT: #{speedup}x speedup!")
      elsif speedup > 10 do
        IO.puts("✅ Good improvement: #{speedup}x speedup")
      else
        IO.puts("⚠️  Expected better improvement")
      end
      
      IO.puts("")
    end)
    
    # Estimate century backup improvement
    estimate_century_improvement()
  end

  def benchmark_original_virtual_clock(num_events) do
    {:ok, clock} = VirtualClock.start_link()
    
    # Schedule events every day for num_events days
    one_day_ms = 86_400_000
    
    for i <- 1..num_events do
      VirtualClock.send_after(clock, :fake_dest, {:backup, i}, i * one_day_ms)
    end
    
    # Advance to process all events - this is where the bottleneck occurs
    VirtualClock.advance(clock, num_events * one_day_ms)
    
    GenServer.stop(clock)
    :ok
  end

  def benchmark_optimized_virtual_clock(num_events) do
    {:ok, clock} = VirtualClockOptimized.start_link()
    
    # Schedule identical events
    one_day_ms = 86_400_000
    
    for i <- 1..num_events do
      VirtualClockOptimized.send_after(clock, :fake_dest, {:backup, i}, i * one_day_ms)
    end  
    
    # Advance to process all events - this should be MUCH faster
    VirtualClockOptimized.advance(clock, num_events * one_day_ms)
    
    GenServer.stop(clock)
    :ok
  end

  def estimate_century_improvement do
    IO.puts("🎯 CENTURY BACKUP PROJECTION:")
    IO.puts("-" <> String.duplicate("-", 40))
    
    # Estimate based on 1000 events benchmark
    {original_1000, _} = :timer.tc(fn -> benchmark_original_virtual_clock(1000) end)
    {optimized_1000, _} = :timer.tc(fn -> benchmark_optimized_virtual_clock(1000) end)
    
    # Scale to 36,500 events (century backup)
    century_events = 36_500
    
    estimated_original_seconds = div(original_1000 * century_events, 1000 * 1_000_000)
    estimated_optimized_seconds = div(optimized_1000 * century_events, 1000 * 1_000_000)
    
    IO.puts("Century backup (36,500 events) estimates:")
    IO.puts("Original:  ~#{estimated_original_seconds} seconds")
    IO.puts("Optimized: ~#{estimated_optimized_seconds} seconds")
    
    if estimated_original_seconds > 60 && estimated_optimized_seconds < 5 do
      IO.puts("🎉 SUCCESS: Century backup goes from minutes to seconds!")
    else
      IO.puts("📊 Results: #{div(estimated_original_seconds, max(estimated_optimized_seconds, 1))}x improvement")
    end
    
    IO.puts("")
    IO.puts("🔬 Root Cause Analysis:")
    IO.puts("- Original: Each event triggers Process.send_after(_, _, 1)")
    IO.puts("- 36,500 events × 1ms delay = 36.5 seconds of artificial waiting")
    IO.puts("- Optimized: Pure synchronous processing = microseconds")
    IO.puts("- Virtual time should NEVER use real time delays!")
  end
end

# Run the comparison
OptimizationBenchmark.run_comparison()
