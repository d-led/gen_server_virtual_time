#!/usr/bin/env elixir

# ------------------------------------------------------------------------------
# CENTURY BACKUP SIMULATION - A Virtual Time Demo
# ------------------------------------------------------------------------------
#
# PROBLEM: How do you test a system that runs for 100 years?
#
# Imagine a backup system:
#   - Scheduler: Triggers backup every midnight
#   - Backup State Machine: Takes 1 hour to complete each backup
#
# If you wanted to verify this works correctly over a century, waiting 100 real
# years would be... impractical.
#
# SOLUTION: Virtual Time
#
# By replacing real clocks with virtual clocks, we can simulate 100 years of
# operation in seconds. This script demonstrates TWO approaches:
#
#   1. ActorSimulation DSL - Declarative, concise
#   2. Raw GenServer/StateMachine - Explicit, detailed
#
# Both achieve the same result: simulating 36,525 daily backups in milliseconds.
#
# IMPORTANT: The GenServer and StateMachine implementations (Approach 2) use
# the same code that would run in production - just without virtual time injection.
# The time-based API calls work identically with real and virtual clocks.
#
# ------------------------------------------------------------------------------

Mix.install([
  {:gen_server_virtual_time, "~> 0.5.0"}
])

defmodule TimeHelper do
  def measure_time(fun) do
    start = System.monotonic_time(:millisecond)
    result = fun.()
    elapsed = System.monotonic_time(:millisecond) - start
    {result, elapsed}
  end
end

# ------------------------------------------------------------------------------
# APPROACH 1: ActorSimulation DSL (Declarative)
# ------------------------------------------------------------------------------
# The ActorSimulation DSL lets you describe actor behavior concisely.
# Define patterns (periodic, rate, burst) and leave orchestration to the DSL.

defmodule CenturyBackup.ActorSimulationDSLExample do
  def run do
    IO.puts("\n📝 APPROACH 1: ActorSimulation DSL")
    IO.puts("   Declarative approach - configure the simulation")

    days_in_century = 36_525
    ms_per_day = 24 * 3600 * 1000
    simulation_duration = days_in_century * ms_per_day + (3 * 3600 * 1000)

    # Define actors with their behavior patterns
    simulation =
      ActorSimulation.new()
      |> ActorSimulation.add_actor(:scheduler,
        send_pattern: {:periodic, ms_per_day, :trigger_backup},
        targets: [:backup_machine]
      )
      |> ActorSimulation.add_actor(:backup_machine,
        initial_state: %{state: :idle, backup_count: 0},
        on_receive: fn
          # When idle, start backup by transitioning to backing_up state
          _, state when state.state == :idle ->
            {:ok, %{state | state: :backing_up}}
          # When already backing up, ignore new triggers
          _, state ->
            {:ok, state}
        end,
        send_pattern: {:periodic, 3600 * 1000, :complete_backup}
      )

    {backup_count, elapsed} = TimeHelper.measure_time(fn ->
      sim = ActorSimulation.run(simulation, duration: simulation_duration)
      stats = ActorSimulation.get_stats(sim)
      count = Map.get(stats.actors[:scheduler], :sent_count, 0)
      ActorSimulation.stop(sim)
      count
    end)

    IO.puts("\n   ✓ Simulated #{days_in_century} days in #{elapsed}ms")
    IO.puts("   ✓ Scheduled #{backup_count} backups")

    elapsed
  end
end

# ------------------------------------------------------------------------------
# APPROACH 2: Raw GenServer + GenStateMachine (Explicit)
# ------------------------------------------------------------------------------
# Explicit implementation gives you full control over every detail.
# You manage the state machine transitions and message passing yourself.

defmodule CenturyBackup.BackupStateMachine do
  use VirtualTimeGenStateMachine, callback_mode: :handle_event_function

  def start_link(opts \\ []) do
    VirtualTimeGenStateMachine.start_link(__MODULE__, :idle, opts)
  end

  def init(state), do: {:ok, state, %{backup_count: 0, started_count: 0}}

  # Start backup when idle (1-hour timer)
  def handle_event(:cast, :trigger_backup, :idle, data) do
    VirtualTimeGenStateMachine.send_after(self(), :backup_complete, 3600 * 1000)
    {:next_state, :backing_up, %{data | started_count: data.started_count + 1}}
  end

  # Ignore triggers while already backing up
  def handle_event(:cast, :trigger_backup, :backing_up, _data) do
    {:keep_state_and_data, []}
  end

  # Complete backup: increment counter, return to idle
  def handle_event(:info, :backup_complete, :backing_up, data) do
    {:next_state, :idle, %{data | backup_count: data.backup_count + 1}}
  end

  # Query backup count (for verification)
  def handle_event({:call, from}, :get_backup_count, _state, data) do
    {:keep_state, data, [{:reply, from, data.backup_count}]}
  end

  def handle_event({:call, from}, :get_started_count, _state, data) do
    {:keep_state, data, [{:reply, from, data.started_count}]}
  end
end

defmodule CenturyBackup.SchedulerGenServer do
  use VirtualTimeGenServer

  def start_link(backup_pid, opts \\ []) do
    VirtualTimeGenServer.start_link(__MODULE__, backup_pid, opts)
  end

  # Initialize: schedule first midnight tick
  def init(backup_pid) do
    VirtualTimeGenServer.send_after(self(), :midnight_tick, 24 * 3600 * 1000)
    {:ok, %{backup_pid: backup_pid}}
  end

  # Trigger backup at midnight, schedule next
  def handle_info(:midnight_tick, state) do
    VirtualTimeGenServer.cast(state.backup_pid, :trigger_backup)
    VirtualTimeGenServer.send_after(self(), :midnight_tick, 24 * 3600 * 1000)
    {:noreply, state}
  end
end

defmodule CenturyBackup.Raw do
  def run do
    IO.puts("\n⚙️  APPROACH 2: Raw GenServer + GenStateMachine")
    IO.puts("   Explicit control over state transitions and messaging")

    days_in_century = 36_525
    ms_per_day = 24 * 3600 * 1000

    {:ok, clock} = VirtualClock.start_link()

    result = TimeHelper.measure_time(fn ->
      {:ok, backup_pid} = CenturyBackup.BackupStateMachine.start_link(virtual_clock: clock)
      {:ok, _scheduler_pid} = CenturyBackup.SchedulerGenServer.start_link(backup_pid, virtual_clock: clock)

      # For 36,525 backups, advance to the completion time of the last backup:
      # Last trigger at 36525*24h, completes at 36525*24h + 1h
      total_duration = (days_in_century * ms_per_day) + (3600 * 1000)
      VirtualClock.advance(clock, total_duration)

      completed = VirtualTimeGenStateMachine.call(backup_pid, :get_backup_count)
      started = VirtualTimeGenStateMachine.call(backup_pid, :get_started_count)
      for pid <- [backup_pid, clock], do: GenServer.stop(pid)
      {started, completed}
    end)

    {{started_count, backup_count}, elapsed} = result

    IO.puts("\n   ✓ Simulated #{days_in_century} days in #{elapsed}ms")
    IO.puts("   ✓ Started: #{started_count}, Completed: #{backup_count} (expected: #{days_in_century})")

    elapsed
  end
end

# ------------------------------------------------------------------------------
# MAIN: Compare Both Approaches
# ------------------------------------------------------------------------------

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("  CENTURY BACKUP SIMULATION")
IO.puts("  Simulating 100 years in seconds with virtual time")
IO.puts(String.duplicate("=", 60))

dsl_elapsed = CenturyBackup.ActorSimulationDSLExample.run()
raw_elapsed = CenturyBackup.Raw.run()

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("  COMPARISON")
IO.puts(String.duplicate("=", 60))
IO.puts("  DSL           :  #{dsl_elapsed}ms")
IO.puts("  Real processes:  #{raw_elapsed}ms")
IO.puts("  Both should simulate 100 years of backups in less than 1 minute! 🚀")
IO.puts(String.duplicate("=", 60) <> "\n")
