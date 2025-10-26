#!/usr/bin/env elixir

# Century Backup Test Profiling Script
# This script profiles the performance bottlenecks in the century backup simulation

Mix.install([
  {:gen_server_virtual_time, path: "."}
])

defmodule CenturyBackupProfiler do
  @moduledoc """
  Comprehensive profiling of the century backup test case.

  This simulates 100 years of daily backups (36,500 events) while measuring:
  - Function-level profiling with :fprof
  - Process-level profiling with :eprof
  - Memory usage tracking
  - Timing breakdowns
  """

  def run_all_profiles do
    IO.puts("🔍 Century Backup Test - Performance Profiling")
    IO.puts("=" <> String.duplicate("=", 50))

    # Run different profiling approaches
    results = %{}

    results = Map.put(results, :basic_timing, run_basic_timing())
    results = Map.put(results, :memory_profile, run_memory_profile())
    results = Map.put(results, :fprof_analysis, run_fprof_analysis())
    results = Map.put(results, :eprof_analysis, run_eprof_analysis())

    print_summary(results)
    results
  end

  def run_basic_timing do
    IO.puts("\n📊 Basic Timing Analysis")
    IO.puts("-" <> String.duplicate("-", 30))

    {setup_time, simulation} = :timer.tc(fn -> setup_simulation() end)
    IO.puts("Setup time: #{setup_time / 1000}ms")

    {run_time, completed_sim} = :timer.tc(fn ->
      ActorSimulation.run(simulation, duration: get_century_duration())
    end)

    stats = ActorSimulation.get_stats(completed_sim)

    IO.puts("Run time: #{run_time / 1000}ms (#{div(run_time, 1_000_000)} seconds)")
    IO.puts("Events processed: #{stats.actors[:backup_system].sent_count}")
    IO.puts("Events/second: #{div(stats.actors[:backup_system].sent_count * 1_000_000, max(run_time, 1))}")

    ActorSimulation.stop(completed_sim)

    %{
      setup_time_us: setup_time,
      run_time_us: run_time,
      events_processed: stats.actors[:backup_system].sent_count,
      events_per_second: div(stats.actors[:backup_system].sent_count * 1_000_000, max(run_time, 1))
    }
  end

  def run_memory_profile do
    IO.puts("\n🧠 Memory Usage Analysis")
    IO.puts("-" <> String.duplicate("-", 30))

    # Get initial memory
    initial_memory = :erlang.memory()
    initial_total = initial_memory[:total]

    simulation = setup_simulation()

    setup_memory = :erlang.memory()
    setup_total = setup_memory[:total]
    setup_overhead = setup_total - initial_total

    IO.puts("Setup memory overhead: #{div(setup_overhead, 1024)} KB")

    # Run simulation and track peak memory
    completed_sim = ActorSimulation.run(simulation, duration: get_century_duration())

    final_memory = :erlang.memory()
    final_total = final_memory[:total]
    peak_overhead = final_total - initial_total

    IO.puts("Peak memory overhead: #{div(peak_overhead, 1024)} KB")
    IO.puts("Final memory overhead: #{div(final_total - initial_total, 1024)} KB")

    ActorSimulation.stop(completed_sim)

    # Force garbage collection and check final state
    :erlang.garbage_collect()
    cleanup_memory = :erlang.memory()

    %{
      initial_memory_kb: div(initial_total, 1024),
      setup_overhead_kb: div(setup_overhead, 1024),
      peak_overhead_kb: div(peak_overhead, 1024),
      final_overhead_kb: div(final_total - initial_total, 1024),
      cleanup_memory_kb: div(cleanup_memory[:total], 1024)
    }
  end

  def run_fprof_analysis do
    IO.puts("\n🔬 Function-level Profiling (:fprof)")
    IO.puts("-" <> String.duplicate("-", 30))

    simulation = setup_simulation()

    # Profile the simulation run
    profile_file = "/tmp/century_backup_fprof.analysis"

    :fprof.apply(fn ->
      ActorSimulation.run(simulation, duration: get_century_duration())
      |> ActorSimulation.stop()
    end, [])

    :fprof.profile()
    :fprof.analyse([totals: true, dest: profile_file])
    :fprof.stop()

    IO.puts("📁 Detailed fprof analysis saved to: #{profile_file}")

    # Try to extract key insights from the profile
    analyze_fprof_results(profile_file)
  end

  def run_eprof_analysis do
    IO.puts("\n⚡ Process-level Profiling (:eprof)")
    IO.puts("-" <> String.duplicate("-", 30))

    simulation = setup_simulation()

    # Get key processes to profile
    clock_pid = simulation.clock

    :eprof.start()
    :eprof.start_profiling([clock_pid, self()])

    {time, completed_sim} = :timer.tc(fn ->
      ActorSimulation.run(simulation, duration: get_century_duration())
    end)

    :eprof.stop_profiling()

    profile_file = "/tmp/century_backup_eprof.analysis"
    :eprof.analyse(dest: profile_file)
    :eprof.stop()

    IO.puts("📁 Process profiling saved to: #{profile_file}")
    IO.puts("Total execution time: #{div(time, 1000)}ms")

    ActorSimulation.stop(completed_sim)

    %{
      profile_file: profile_file,
      execution_time_us: time
    }
  end

  # Helper functions

  defp setup_simulation do
    one_day_ms = 24 * 60 * 60 * 1000

    ActorSimulation.new()
    |> ActorSimulation.add_actor(:backup_system,
      send_pattern: {:periodic, one_day_ms, :backup},
      targets: [:storage]
    )
    |> ActorSimulation.add_actor(:storage)
  end

  defp get_century_duration do
    # 100 years in milliseconds
    100 * 365 * 24 * 60 * 60 * 1000
  end

  defp analyze_fprof_results(profile_file) do
    try do
      content = File.read!(profile_file)

      # Extract some key metrics from fprof output
      lines = String.split(content, "\n")

      # Look for high-time functions
      high_time_functions =
        lines
        |> Enum.filter(&String.contains?(&1, "%"))
        |> Enum.take(10)

      IO.puts("🔥 Top time-consuming functions:")
      Enum.each(high_time_functions, fn line ->
        if String.trim(line) != "" do
          IO.puts("   #{String.trim(line)}")
        end
      end)

      %{profile_file: profile_file, top_functions: high_time_functions}
    rescue
      _ ->
        IO.puts("⚠️  Could not analyze fprof results")
        %{profile_file: profile_file, error: :analysis_failed}
    end
  end

  defp print_summary(results) do
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("📋 PROFILING SUMMARY")
    IO.puts(String.duplicate("=", 60))

    if basic = results[:basic_timing] do
      IO.puts("⏱️  PERFORMANCE:")
      IO.puts("   Events processed: #{basic[:events_processed]}")
      IO.puts("   Total time: #{div(basic[:run_time_us], 1000)}ms")
      IO.puts("   Events/second: #{basic[:events_per_second]}")
    end

    if memory = results[:memory_profile] do
      IO.puts("\n🧠 MEMORY USAGE:")
      IO.puts("   Setup overhead: #{memory[:setup_overhead_kb]} KB")
      IO.puts("   Peak overhead: #{memory[:peak_overhead_kb]} KB")
    end

    IO.puts("\n📁 DETAILED PROFILES:")
    if fprof = results[:fprof_analysis] do
      IO.puts("   Function profile: #{fprof[:profile_file]}")
    end
    if eprof = results[:eprof_analysis] do
      IO.puts("   Process profile: #{eprof[:profile_file]}")
    end

    IO.puts("\n💡 NEXT STEPS:")
    IO.puts("   1. Examine the generated profile files")
    IO.puts("   2. Focus on functions with highest time percentages")
    IO.puts("   3. Look for opportunities to optimize tree operations")
    IO.puts("   4. Consider alternative data structures for event scheduling")
  end
end

# Run the profiling
CenturyBackupProfiler.run_all_profiles()
