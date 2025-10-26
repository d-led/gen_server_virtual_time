#!/usr/bin/env elixir

# Focused bottleneck analysis for century backup performance
# This will pinpoint exactly where the slowdown occurs

Code.compile_file("lib/virtual_clock.ex")
Code.compile_file("lib/actor_simulation.ex")
Code.compile_file("lib/virtual_time_gen_server.ex")

defmodule BottleneckAnalysis do
  @moduledoc """
  Laser-focused analysis to find the exact bottleneck in virtual time processing.

  Focus: The century backup should be FAST since it's virtual - no real I/O!
  """

  def run_analysis do
    IO.puts("🎯 BOTTLENECK ANALYSIS: Century Backup Performance")
    IO.puts("=" <> String.duplicate("=", 60))
    IO.puts("Expected: Should be faster than Erlang inbox (~microseconds per event)")
    IO.puts("Current:  ~2.3ms per event (UNACCEPTABLE!)")
    IO.puts("")

    # Test different scales to isolate the bottleneck
    test_small_scale()
    test_medium_scale()
    test_large_scale()

    # Profile the exact century backup scenario
    profile_century_backup()

    # Analyze the advance loop specifically
    profile_advance_loop()
  end

  def test_small_scale do
    IO.puts("🔬 SMALL SCALE TEST: 10 events")
    IO.puts("-" <> String.duplicate("-", 40))

    events = 10
    one_day_ms = 86_400_000
    duration = events * one_day_ms

    {time, _} = :timer.tc(fn ->
      run_backup_simulation(events, duration)
    end)

    events_per_second = div(events * 1_000_000, max(time, 1))
    time_per_event_us = div(time, events)

    IO.puts("Events: #{events}, Time: #{div(time, 1000)}ms")
    IO.puts("Time per event: #{time_per_event_us}μs")
    IO.puts("Events/second: #{events_per_second}")

    if time_per_event_us > 1000 do
      IO.puts("🚨 BOTTLENECK DETECTED: #{time_per_event_us}μs per event is TOO SLOW")
    else
      IO.puts("✅ Performance acceptable for small scale")
    end
    IO.puts("")
  end

  def test_medium_scale do
    IO.puts("🔬 MEDIUM SCALE TEST: 100 events")
    IO.puts("-" <> String.duplicate("-", 40))

    events = 100
    one_day_ms = 86_400_000
    duration = events * one_day_ms

    {time, _} = :timer.tc(fn ->
      run_backup_simulation(events, duration)
    end)

    events_per_second = div(events * 1_000_000, max(time, 1))
    time_per_event_us = div(time, events)

    IO.puts("Events: #{events}, Time: #{div(time, 1000)}ms")
    IO.puts("Time per event: #{time_per_event_us}μs")
    IO.puts("Events/second: #{events_per_second}")

    if time_per_event_us > 500 do
      IO.puts("🚨 BOTTLENECK CONFIRMED: #{time_per_event_us}μs per event")
    end
    IO.puts("")
  end

  def test_large_scale do
    IO.puts("🔬 LARGE SCALE TEST: 1000 events")
    IO.puts("-" <> String.duplicate("-", 40))

    events = 1000
    one_day_ms = 86_400_000
    duration = events * one_day_ms

    {time, _} = :timer.tc(fn ->
      run_backup_simulation(events, duration)
    end)

    events_per_second = div(events * 1_000_000, max(time, 1))
    time_per_event_us = div(time, events)

    IO.puts("Events: #{events}, Time: #{div(time, 1000)}ms")
    IO.puts("Time per event: #{time_per_event_us}μs")
    IO.puts("Events/second: #{events_per_second}")

    estimated_century_time = div(36_500 * time_per_event_us, 1_000_000)
    IO.puts("🎯 Estimated century backup time: #{estimated_century_time} seconds")
    IO.puts("")
  end

  def profile_century_backup do
    IO.puts("🎯 CENTURY BACKUP PROFILE")
    IO.puts("-" <> String.duplicate("-", 40))

    # Profile exactly the century backup scenario
    events = 36_500  # 100 years * 365 days
    one_day_ms = 86_400_000
    duration = events * one_day_ms

    IO.puts("Profiling #{events} events (century backup)...")

    {time, _} = :timer.tc(fn ->
      # Start profiling
      :fprof.start()

      result = :fprof.apply(fn ->
        run_backup_simulation(events, duration)
      end, [])

      :fprof.profile()
      :fprof.analyse([totals: true, dest: "/tmp/century_backup_profile.txt"])
      :fprof.stop()

      result
    end)

    time_per_event_us = div(time, events)
    IO.puts("Century backup completed in: #{div(time, 1_000_000)} seconds")
    IO.puts("Time per event: #{time_per_event_us}μs")
    IO.puts("📁 Detailed profile: /tmp/century_backup_profile.txt")

    # Try to extract the hottest functions
    analyze_profile_file("/tmp/century_backup_profile.txt")
  end

  def profile_advance_loop do
    IO.puts("🔍 ADVANCE LOOP ANALYSIS")
    IO.puts("-" <> String.duplicate("-", 40))

    # Profile just the VirtualClock.advance operations
    {:ok, clock} = VirtualClock.start_link()

    # Schedule many events at different times
    events = 1000

    for i <- 1..events do
      VirtualClock.send_after(clock, self(), {:backup, i}, i * 86_400_000)
    end

    IO.puts("Profiling advance operation with #{events} scheduled events...")

    {time, _} = :timer.tc(fn ->
      :fprof.start()

      :fprof.apply(fn ->
        VirtualClock.advance(clock, events * 86_400_000)
      end, [])

      :fprof.profile()
      :fprof.analyse([totals: true, dest: "/tmp/advance_loop_profile.txt"])
      :fprof.stop()
    end)

    GenServer.stop(clock)

    IO.puts("Advance loop completed in: #{div(time, 1000)}ms")
    IO.puts("Time per event in advance: #{div(time, events)}μs")
    IO.puts("📁 Advance loop profile: /tmp/advance_loop_profile.txt")

    analyze_profile_file("/tmp/advance_loop_profile.txt")
  end

  # Helper functions

  defp run_backup_simulation(num_events, duration) do
    one_day_ms = 86_400_000

    simulation = ActorSimulation.new()
    |> ActorSimulation.add_actor(:backup_system,
      send_pattern: {:periodic, one_day_ms, :backup},
      targets: [:storage]
    )
    |> ActorSimulation.add_actor(:storage)
    |> ActorSimulation.run(duration: duration)

    stats = ActorSimulation.get_stats(simulation)
    ActorSimulation.stop(simulation)

    actual_events = stats.actors[:backup_system].sent_count

    if actual_events != num_events do
      IO.puts("⚠️  Expected #{num_events} events, got #{actual_events}")
    end

    stats
  end

  defp analyze_profile_file(filename) do
    try do
      content = File.read!(filename)
      lines = String.split(content, "\n")

      # Find lines mentioning key functions
      relevant_lines = lines
      |> Enum.filter(fn line ->
        String.contains?(line, "VirtualClock") or
        String.contains?(line, "advance") or
        String.contains?(line, "send_after") or
        String.contains?(line, "Process.send_after") or
        String.contains?(line, "gb_trees") or
        String.contains?(line, "%") and not String.contains?(line, "0.00")
      end)
      |> Enum.reject(&(String.trim(&1) == ""))
      |> Enum.take(15)

      IO.puts("🔥 HOTSPOT FUNCTIONS:")
      Enum.each(relevant_lines, fn line ->
        IO.puts("   #{String.trim(line)}")
      end)

    rescue
      _ ->
        IO.puts("⚠️  Could not analyze profile file: #{filename}")
    end

    IO.puts("")
  end
end

# Run the analysis
BottleneckAnalysis.run_analysis()
