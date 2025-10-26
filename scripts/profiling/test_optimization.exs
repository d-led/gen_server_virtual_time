#!/usr/bin/env elixir

# Simple test to verify the optimization works

Code.compile_file("lib/virtual_clock.ex")
Code.compile_file("virtual_clock_optimized.ex")

defmodule SimpleOptimizationTest do
  def test_performance do
    IO.puts("🚀 Testing VirtualClock Optimization")
    IO.puts("=" <> String.duplicate("=", 50))
    
    events = 1000
    IO.puts("Testing #{events} events...")
    
    # Test original
    IO.puts("\n📊 Original VirtualClock:")
    {original_time, _} = :timer.tc(fn ->
      test_original_clock(events)
    end)
    
    original_ms = div(original_time, 1000)
    original_us_per_event = div(original_time, events)
    IO.puts("Time: #{original_ms}ms (#{original_us_per_event}μs per event)")
    
    # Test optimized  
    IO.puts("\n📊 Optimized VirtualClock:")
    {optimized_time, _} = :timer.tc(fn ->
      test_optimized_clock(events)
    end)
    
    optimized_ms = div(optimized_time, 1000)
    optimized_us_per_event = div(optimized_time, events)
    IO.puts("Time: #{optimized_ms}ms (#{optimized_us_per_event}μs per event)")
    
    # Calculate improvement
    speedup = div(original_time, max(optimized_time, 1))
    IO.puts("\n🎯 Results:")
    IO.puts("Speedup: #{speedup}x faster")
    
    if speedup > 10 do
      IO.puts("✅ SUCCESS: Significant performance improvement!")
    else
      IO.puts("⚠️  Modest improvement: #{speedup}x")
    end
    
    # Estimate century backup
    century_events = 36_500
    estimated_original_seconds = div(original_time * century_events, events * 1_000_000)
    estimated_optimized_seconds = div(optimized_time * century_events, events * 1_000_000)
    
    IO.puts("\n🎂 Century Backup Estimates:")
    IO.puts("Original: ~#{estimated_original_seconds} seconds")
    IO.puts("Optimized: ~#{estimated_optimized_seconds} seconds")
  end
  
  defp test_original_clock(num_events) do
    {:ok, clock} = VirtualClock.start_link()
    
    # Schedule events
    one_day_ms = 86_400_000
    for i <- 1..num_events do
      VirtualClock.send_after(clock, :fake_dest, {:backup, i}, i * one_day_ms)
    end
    
    # This is where the bottleneck occurs
    VirtualClock.advance(clock, num_events * one_day_ms)
    
    GenServer.stop(clock)
    :ok
  end
  
  defp test_optimized_clock(num_events) do
    {:ok, clock} = VirtualClockOptimized.start_link()
    
    # Schedule identical events
    one_day_ms = 86_400_000
    for i <- 1..num_events do
      VirtualClockOptimized.send_after(clock, :fake_dest, {:backup, i}, i * one_day_ms)
    end
    
    # This should be much faster
    VirtualClockOptimized.advance(clock, num_events * one_day_ms)
    
    GenServer.stop(clock)
    :ok
  end
end

# Run the test
SimpleOptimizationTest.test_performance()
