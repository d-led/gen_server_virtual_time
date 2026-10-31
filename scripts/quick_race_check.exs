#!/usr/bin/env elixir

# Quick Race Condition Checker
# Run with: elixir scripts/quick_race_check.exs

defmodule QuickRaceChecker do
  @moduledoc """
  Quick race condition checker that focuses on the most problematic tests.
  """

  def run do
    IO.puts("🚀 Quick Race Condition Check")
    IO.puts("Testing problematic files with multiple seeds...")

    # Files that are most likely to have race conditions
    problematic_files = [
      "packages/actor_simulation/test/process_in_loop_test.exs",
      "packages/actor_simulation/test/documentation_test.exs",
      "packages/actor_simulation/test/show_me_code_examples_test.exs",
      "packages/actor_simulation/test/actor_simulation_test.exs"
    ]

    # Test with different concurrency levels
    concurrency_levels = [1, 2, 4, 8]
    seeds = [1, 42, 123, 456, 789, 999, 1337, 2024]

    results = []

    for file <- problematic_files do
      IO.puts("\n📁 Testing #{file}")

      file_results = for max_cases <- concurrency_levels do
        IO.write("  Max cases #{max_cases}: ")

        seed_results = for seed <- seeds do
          {output, exit_code} = run_test_file(file, max_cases, seed)
          {seed, exit_code == 0}
        end

        passes = Enum.count(seed_results, fn {_, passed} -> passed end)
        total = length(seed_results)

        if passes == total do
          IO.puts("✅ #{passes}/#{total} passed")
          :ok
        else
          IO.puts("❌ #{passes}/#{total} passed")
          {:fail, file, max_cases, passes, total}
        end
      end

      failures = Enum.filter(file_results, &match?({:fail, _, _, _, _}, &1))
      if not Enum.empty?(failures) do
        results = results ++ failures
      end
    end

    IO.puts("\n" <> String.duplicate("=", 50))

    if Enum.empty?(results) do
      IO.puts("🎉 No race conditions detected!")
    else
      IO.puts("⚠️  Potential race conditions found:")
      for {:fail, file, max_cases, passes, total} <- results do
        IO.puts("  #{file} (max_cases=#{max_cases}): #{passes}/#{total} passed")
      end
    end
  end

  defp run_test_file(file, max_cases, seed) do
    # Each package is a Mix project of its own, so the test runs from the package
    # the file lives in, with the path relative to it.
    ["packages", package | rest] = String.split(file, "/")
    relative = Path.join(rest, "")

    cmd = [
      "mix",
      "test",
      relative,
      "--seed",
      to_string(seed),
      "--max-cases",
      to_string(max_cases),
      "--exclude",
      "diagram_generation,slow"
    ]

    System.cmd("elixir", ["-S"] ++ cmd, cd: package, stderr_to_stdout: true)
  end
end

QuickRaceChecker.run()
