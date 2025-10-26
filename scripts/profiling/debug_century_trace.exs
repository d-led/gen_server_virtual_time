#!/usr/bin/env elixir

# Debug script with Erlang tracing to see what's happening

Mix.start()
Mix.Task.run("app.start")

defmodule CenturyDebugger do
  def debug_with_tracing do
    IO.puts("🔍 TRACING CENTURY BACKUP EVENT PROCESSING")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Start tracing
    :dbg.tracer()
    :dbg.p(:all, :c)  # Trace all processes, calls
    
    # Trace VirtualClock functions
    :dbg.tpl(VirtualClock, :send_after, [])
    :dbg.tpl(VirtualClock, :advance, [])
    :dbg.tpl(VirtualClock, :handle_info, [])
    
    # Trace ActorSimulation.Actor functions
    :dbg.tpl(ActorSimulation.Actor, :handle_info, [])
    
    IO.puts("Starting century backup simulation with tracing...")
    
    # Run a smaller version for debugging (100 events instead of 36,500)
    one_day_ms = 86_400_000
    events = 100
    duration = events * one_day_ms
    
    simulation = ActorSimulation.new()
    |> ActorSimulation.add_actor(:backup_system,
      send_pattern: {:periodic, one_day_ms, :backup},
      targets: [:storage]
    )
    |> ActorSimulation.add_actor(:storage)
    |> ActorSimulation.run(duration: duration)
    
    stats = ActorSimulation.get_stats(simulation)
    ActorSimulation.stop(simulation)
    
    # Stop tracing
    :dbg.stop_clear()
    
    IO.puts("\n📊 RESULTS:")
    IO.puts("Expected events: #{events}")
    IO.puts("Actual events: #{stats.actors[:backup_system].sent_count}")
    IO.puts("Success rate: #{div(stats.actors[:backup_system].sent_count * 100, events)}%")
    
    if stats.actors[:backup_system].sent_count < events do
      IO.puts("\n🚨 ISSUE CONFIRMED: Events are being lost during advance!")
      IO.puts("Check the trace output above to see the message flow.")
    end
  end
  
  def debug_simple_case do
    IO.puts("\n🔍 SIMPLE 5-EVENT DEBUG")
    IO.puts("-" <> String.duplicate("-", 30))
    
    # Test with just 5 events to see the pattern
    one_day_ms = 86_400_000
    events = 5
    duration = events * one_day_ms
    
    IO.puts("Simulating #{events} daily backups...")
    
    {time, simulation} = :timer.tc(fn ->
      ActorSimulation.new()
      |> ActorSimulation.add_actor(:backup_system,
        send_pattern: {:periodic, one_day_ms, :backup},
        targets: [:storage]
      )
      |> ActorSimulation.add_actor(:storage)
      |> ActorSimulation.run(duration: duration)
    end)
    
    stats = ActorSimulation.get_stats(simulation)
    ActorSimulation.stop(simulation)
    
    IO.puts("Expected: #{events}, Got: #{stats.actors[:backup_system].sent_count}")
    IO.puts("Time: #{div(time, 1000)}ms")
    
    if stats.actors[:backup_system].sent_count == events do
      IO.puts("✅ Small case works - issue is scale-dependent")
    else
      IO.puts("🚨 Issue exists even at small scale")
    end
  end
end

# Run both tests
CenturyDebugger.debug_simple_case()
CenturyDebugger.debug_with_tracing()
