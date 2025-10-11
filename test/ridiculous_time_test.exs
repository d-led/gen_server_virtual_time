defmodule RidiculousTimeTest do
  use ExUnit.Case, async: false

  describe "Absurdly long simulations" do
    test "quarterly reports for 3 years completes in milliseconds" do
      # Actor sends quarterly reports (every 3 months)
      three_months_ms = 90 * 24 * 60 * 60 * 1000  # ~7,776,000 ms
      three_years_ms = 3 * 365 * 24 * 60 * 60 * 1000  # ~94,608,000 ms

      IO.puts("\n🤯 Simulating 3 YEARS of quarterly reports...")
      IO.puts("   Quarter interval: #{three_months_ms}ms (#{div(three_months_ms, 1000)} seconds)")
      IO.puts("   Total simulation: #{three_years_ms}ms (#{div(three_years_ms, 1000)} seconds)")
      IO.puts("   That's #{div(three_years_ms, 1000 * 60 * 60)} hours of virtual time!\n")

      start_time = System.monotonic_time(:millisecond)

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:quarterly_reporter,
          send_pattern: {:periodic, three_months_ms, :quarterly_report},
          targets: [:manager]
        )
        |> ActorSimulation.add_actor(:manager,
          on_receive: fn :quarterly_report, state ->
            {:ok, %{state | reports: state.reports + 1}}
          end,
          initial_state: %{reports: 0}
        )
        |> ActorSimulation.run(duration: three_years_ms)

      elapsed = System.monotonic_time(:millisecond) - start_time
      stats = ActorSimulation.get_stats(simulation)

      # 3 years = 12 quarters
      expected_reports = 12

      assert stats.actors[:quarterly_reporter].sent_count == expected_reports,
        "Should send #{expected_reports} quarterly reports in 3 years"

      assert stats.actors[:manager].received_count == expected_reports,
        "Manager should receive all #{expected_reports} reports"

      # The ridiculous part: 3 YEARS simulated in seconds!
      assert elapsed < 10_000, "3 years should simulate in under 10 seconds!"

      speedup = div(three_years_ms, max(elapsed, 1))

      IO.puts("✅ SUCCESS!")
      IO.puts("   Quarterly reports sent: #{stats.actors[:quarterly_reporter].sent_count}")
      IO.puts("   Virtual time: #{div(three_years_ms, 1000 * 60 * 60)} hours (3 years)")
      IO.puts("   Real time: #{elapsed}ms")
      IO.puts("   Speedup: #{speedup}x faster than real time 🚀")
      IO.puts("   Without virtual time, this test would take 3 YEARS to run!\n")

      ActorSimulation.stop(simulation)
    end

    test "monthly heartbeat for a decade runs instantly" do
      one_month_ms = 30 * 24 * 60 * 60 * 1000  # ~2,592,000 ms
      one_decade_ms = 10 * 365 * 24 * 60 * 60 * 1000  # ~315,360,000 ms

      IO.puts("\n🎂 Simulating a DECADE of monthly heartbeats...")

      start_time = System.monotonic_time(:millisecond)

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:heartbeat_monitor,
          send_pattern: {:periodic, one_month_ms, :heartbeat},
          targets: [:server]
        )
        |> ActorSimulation.add_actor(:server)
        |> ActorSimulation.run(duration: one_decade_ms)

      elapsed = System.monotonic_time(:millisecond) - start_time
      stats = ActorSimulation.get_stats(simulation)

      # 10 years * 12 months = 120 heartbeats (may get 121 due to timing)
      expected_heartbeats = 120

      assert stats.actors[:heartbeat_monitor].sent_count >= expected_heartbeats
      assert stats.actors[:heartbeat_monitor].sent_count <= expected_heartbeats + 1

      # Should complete in seconds, not a decade!
      assert elapsed < 20_000, "A decade should simulate in under 20 seconds!"

      IO.puts("✅ Decade complete!")
      IO.puts("   Heartbeats: #{stats.actors[:heartbeat_monitor].sent_count}")
      IO.puts("   Real time: #{elapsed}ms")
      IO.puts("   That's #{div(one_decade_ms, max(elapsed, 1))}x speedup")
      IO.puts("   Without virtual time: Would take 10 YEARS! 🤯\n")

      ActorSimulation.stop(simulation)
    end

    test "daily backup for a century (because why not)" do
      one_day_ms = 24 * 60 * 60 * 1000  # 86,400,000 ms
      one_century_ms = 100 * 365 * 24 * 60 * 60 * 1000  # ~3,153,600,000 ms

      IO.puts("\n👴 Simulating a CENTURY of daily backups...")
      IO.puts("   (This is ridiculous, but proves a point!)\n")

      start_time = System.monotonic_time(:millisecond)

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:backup_system,
          send_pattern: {:periodic, one_day_ms, :backup},
          targets: [:storage]
        )
        |> ActorSimulation.add_actor(:storage)
        |> ActorSimulation.run(duration: one_century_ms)

      elapsed = System.monotonic_time(:millisecond) - start_time
      stats = ActorSimulation.get_stats(simulation)

      # 100 years * 365 days = 36,500 backups
      expected_backups = 36_500

      assert stats.actors[:backup_system].sent_count == expected_backups

      # A century in under a minute!
      assert elapsed < 60_000, "A century should simulate in under 60 seconds!"

      IO.puts("🏆 CENTURY COMPLETE!")
      IO.puts("   Backups performed: #{stats.actors[:backup_system].sent_count}")
      IO.puts("   Real time: #{div(elapsed, 1000)} seconds")
      IO.puts("   Virtual time: 100 YEARS")
      IO.puts("   Speedup: #{div(one_century_ms, max(elapsed, 1))}x")
      IO.puts("   Without virtual time: Your great-great-grandchildren")
      IO.puts("   would still be waiting for this test! 👻\n")

      ActorSimulation.stop(simulation)
    end
  end
end
