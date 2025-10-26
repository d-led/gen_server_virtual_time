#!/usr/bin/env elixir

# Test that the optimized version handles race conditions correctly

Code.compile_file("lib/virtual_time_gen_server.ex")
Code.compile_file("virtual_clock_optimized.ex")

defmodule RaceConditionTest do
  @moduledoc """
  Tests that the optimized VirtualClock handles race conditions correctly.
  
  Race condition scenario:
  1. Event A scheduled for time T
  2. When Event A is processed, it schedules Event B for time T (same time!)
  3. Event B must also be processed before advancing to T+1
  
  This is the critical case that broke when we tried pure synchronous processing.
  """

  def test_race_condition_handling do
    IO.puts("🧪 Testing Race Condition Handling")
    IO.puts("=" <> String.duplicate("=", 40))
    
    {:ok, clock} = VirtualClockOptimized.start_link()
    
    # Start a test process that will schedule additional events
    test_pid = spawn(fn -> 
      race_condition_test_process()
    end)
    
    # Schedule initial event at time 1000
    VirtualClockOptimized.send_after(clock, test_pid, :initial_event, 1000)
    
    IO.puts("Scheduling initial event at time 1000...")
    IO.puts("This will trigger additional events for the same time...")
    
    # Advance and see if all cascading events are processed
    {time, _} = :timer.tc(fn ->
      VirtualClockOptimized.advance(clock, 1000)
    end)
    
    # Give the test process time to report results
    Process.sleep(10)
    
    GenServer.stop(clock)
    
    IO.puts("Advance completed in #{div(time, 1000)}ms")
    IO.puts("Check the messages above to verify all cascading events were processed")
  end
  
  def race_condition_test_process do
    receive do
      :initial_event ->
        IO.puts("✅ Received initial_event - scheduling cascading events...")
        
        # This is the race condition case: schedule more events for the SAME time
        {:ok, clock} = find_virtual_clock()
        if clock do
          VirtualClockOptimized.send_after(clock, self(), :cascading_event_1, 0)
          VirtualClockOptimized.send_after(clock, self(), :cascading_event_2, 0)
          IO.puts("   Scheduled cascading_event_1 and cascading_event_2 for current time")
        end
        
        race_condition_test_process()
        
      :cascading_event_1 ->
        IO.puts("✅ Received cascading_event_1 - scheduling another cascade...")
        
        {:ok, clock} = find_virtual_clock()
        if clock do
          VirtualClockOptimized.send_after(clock, self(), :final_cascade, 0) 
          IO.puts("   Scheduled final_cascade for current time")
        end
        
        race_condition_test_process()
        
      :cascading_event_2 ->
        IO.puts("✅ Received cascading_event_2")
        race_condition_test_process()
        
      :final_cascade ->
        IO.puts("✅ Received final_cascade - race condition handled correctly!")
        race_condition_test_process()
        
    after 1000 ->
      IO.puts("⚠️  Test process timeout - some events may have been missed")
    end
  end
  
  defp find_virtual_clock do
    # This is a hack for testing - in real usage the clock reference is passed properly
    case Process.whereis(VirtualClockOptimized) do
      nil -> {:error, :not_found}
      pid -> {:ok, pid}
    end
  end
end

# Run the test
RaceConditionTest.test_race_condition_handling()
