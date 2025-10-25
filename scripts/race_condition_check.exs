#!/usr/bin/env elixir

# Race Condition Checker for GenServerVirtualTime
# Run with: elixir scripts/race_condition_check.exs

defmodule RaceConditionChecker do
  @moduledoc """
  A simple race condition checker that runs tests multiple times
  with different seeds and concurrency settings to find flaky tests.
  """

  def run_check do
    IO.puts("🔍 Race Condition Checker Starting...")
    IO.puts("=" <> String.duplicate("=", 50))
    
    # Test configurations to try
    configs = [
      %{name: "Sequential", max_cases: 1, async: false},
      %{name: "Low Concurrency", max_cases: 2, async: true},
      %{name: "Medium Concurrency", max_cases: 4, async: true},
      %{name: "High Concurrency", max_cases: 8, async: true}
    ]
    
    # Seeds to test with
    seeds = [12345, 67890, 11111, 22222, 33333, 44444, 55555, 66666, 77777, 88888]
    
    results = []
    
    for config <- configs do
      IO.puts("\n🧪 Testing #{config.name} (#{config.max_cases} cases, async: #{config.async})")
      
      config_results = for seed <- seeds do
        IO.write("  Seed #{seed}: ")
        
        {output, exit_code} = run_test_with_config(config, seed)
        
        if exit_code == 0 do
          IO.puts("✅ PASS")
          :pass
        else
          IO.puts("❌ FAIL")
          IO.puts("    Error: #{String.slice(output, -200, 200)}")
          {:fail, output}
        end
      end
      
      failures = Enum.filter(config_results, &match?({:fail, _}, &1))
      
      if Enum.empty?(failures) do
        IO.puts("  ✅ All seeds passed for #{config.name}")
      else
        IO.puts("  ❌ #{length(failures)} failures found in #{config.name}")
        results = results ++ [{config.name, failures}]
      end
    end
    
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("📊 SUMMARY")
    IO.puts("=" <> String.duplicate("=", 50))
    
    if Enum.empty?(results) do
      IO.puts("🎉 No race conditions detected!")
      IO.puts("All tests passed consistently across different configurations.")
    else
      IO.puts("⚠️  Potential race conditions found:")
      for {config_name, failures} <- results do
        IO.puts("  #{config_name}: #{length(failures)} failures")
      end
      IO.puts("\n💡 Consider making assertions more robust (use >= instead of ==)")
      IO.puts("   or adding proper synchronization to your tests.")
    end
  end
  
  defp run_test_with_config(config, seed) do
    cmd = [
      "mix", "test",
      "--seed", to_string(seed),
      "--max-cases", to_string(config.max_cases),
      "--exclude", "diagram_generation,slow"
    ]
    
    System.cmd("elixir", ["-S"] ++ cmd, stderr_to_stdout: true)
  end
end

# Run the checker
RaceConditionChecker.run_check()
