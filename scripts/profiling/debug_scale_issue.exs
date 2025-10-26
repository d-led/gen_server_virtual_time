#!/usr/bin/env elixir

# Debug script to find the scale breaking point

Mix.start()
Mix.Task.run("app.start")

defmodule ScaleDebugger do
  def test_different_scales do
    IO.puts("🔍 Testing different scales to find breaking point")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Test increasing scales
    scales = [10, 100, 500, 1000, 2000, 5000, 10000]
    
    Enum.each(scales, fn events ->
      IO.puts("\n📊 Testing #{events} events:")
      
      {time, stats} = :timer.tc(fn ->
        test_periodic_events(events)
      end)
      
      sent_count = stats.actors[:backup_system].sent_count
      success_rate = div(sent_count * 100, events)
      
      IO.puts("   Expected: #{events}, Got: #{sent_count}")
      IO.puts("   Success rate: #{success_rate}%")
      IO.puts("   Time: #{div(time, 1000)}ms")
      
      if sent_count < events do
        IO.puts("   🚨 BREAKING POINT FOUND at #{events} events!")
        if sent_count > 0 do
          IO.puts("   🔍 Partial processing suggests premature loop exit")
        end
      else
        IO.puts("   ✅ All events processed correctly")
      end
    end)
  end
  
  defp test_periodic_events(num_events) do
    one_day_ms = 86_400_000
    duration = num_events * one_day_ms
    
    simulation = ActorSimulation.new()
    |> ActorSimulation.add_actor(:backup_system,
      send_pattern: {:periodic, one_day_ms, :backup},
      targets: [:storage]
    )
    |> ActorSimulation.add_actor(:storage)
    |> ActorSimulation.run(duration: duration)
    
    stats = ActorSimulation.get_stats(simulation)
    ActorSimulation.stop(simulation)
    
    stats
  end
end

ScaleDebugger.test_different_scales()
