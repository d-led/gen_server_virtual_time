#!/usr/bin/env elixir

# Comprehensive demonstration of Global vs Local Virtual Clock modes
#
# This example shows:
# 1. Global clock mode - coordinated simulation
# 2. Local clock mode - isolated simulations
# 3. Mixed mode - combining virtual and real time
#
# Run with: mix run examples/clock_modes_demo.exs

defmodule PaymentProcessor do
  @moduledoc """
  A simple payment processor that processes payments periodically.
  """
  use VirtualTimeGenServer

  def start_link(interval, opts \\ []) do
    VirtualTimeGenServer.start_link(__MODULE__, interval, opts)
  end

  def get_stats(server) do
    VirtualTimeGenServer.call(server, :get_stats)
  end

  @impl true
  def init(interval) do
    schedule_process(interval)
    {:ok, %{interval: interval, processed: 0, total_amount: 0}}
  end

  @impl true
  def handle_info(:process_payment, state) do
    # Simulate processing a random payment
    amount = :rand.uniform(1000)
    new_state = %{
      state
      | processed: state.processed + 1,
        total_amount: state.total_amount + amount
    }

    schedule_process(state.interval)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    {:reply, {state.processed, state.total_amount}, state}
  end

  defp schedule_process(interval) do
    VirtualTimeGenServer.send_after(self(), :process_payment, interval)
  end
end

defmodule AnalyticsAggregator do
  @moduledoc """
  Aggregates analytics data periodically.
  """
  use VirtualTimeGenServer

  def start_link(interval, opts \\ []) do
    VirtualTimeGenServer.start_link(__MODULE__, interval, opts)
  end

  def get_reports(server) do
    VirtualTimeGenServer.call(server, :get_reports)
  end

  @impl true
  def init(interval) do
    schedule_aggregate(interval)
    {:ok, %{interval: interval, reports: 0}}
  end

  @impl true
  def handle_info(:aggregate, state) do
    new_state = %{state | reports: state.reports + 1}
    schedule_aggregate(state.interval)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_reports, _from, state) do
    {:reply, state.reports, state}
  end

  defp schedule_aggregate(interval) do
    VirtualTimeGenServer.send_after(self(), :aggregate, interval)
  end
end

defmodule HeartbeatMonitor do
  @moduledoc """
  Sends periodic heartbeats to monitor system health.
  """
  use VirtualTimeGenServer

  def start_link(interval, opts \\ []) do
    VirtualTimeGenServer.start_link(__MODULE__, interval, opts)
  end

  def get_heartbeats(server) do
    VirtualTimeGenServer.call(server, :get_heartbeats)
  end

  @impl true
  def init(interval) do
    schedule_heartbeat(interval)
    {:ok, %{interval: interval, heartbeats: 0}}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    new_state = %{state | heartbeats: state.heartbeats + 1}
    schedule_heartbeat(state.interval)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_heartbeats, _from, state) do
    {:reply, state.heartbeats, state}
  end

  defp schedule_heartbeat(interval) do
    VirtualTimeGenServer.send_after(self(), :heartbeat, interval)
  end
end

# ============================================================================
# DEMONSTRATION SCENARIOS
# ============================================================================

IO.puts("""

╔════════════════════════════════════════════════════════════════════╗
║                 Virtual Clock Modes Demonstration                  ║
╚════════════════════════════════════════════════════════════════════╝

This demo shows three modes of virtual clock operation:
  1. GLOBAL CLOCK - Coordinated simulation
  2. LOCAL CLOCK  - Isolated simulations
  3. MIXED MODE   - Virtual + Real time

""")

# ============================================================================
# SCENARIO 1: GLOBAL CLOCK - Coordinated Simulation
# ============================================================================

IO.puts("""
┌────────────────────────────────────────────────────────────────────┐
│ SCENARIO 1: GLOBAL CLOCK (Coordinated Simulation)                 │
└────────────────────────────────────────────────────────────────────┘

Use Case: Testing a complete system where all components must work
together in lockstep. This is ideal for distributed systems where
timing relationships matter.

""")

{:ok, global_clock} = VirtualClock.start_link()
VirtualTimeGenServer.set_virtual_clock(global_clock)

# Start multiple components that will all share the same timeline
{:ok, payment_processor} = PaymentProcessor.start_link(100)
{:ok, analytics} = AnalyticsAggregator.start_link(500)
{:ok, monitor} = HeartbeatMonitor.start_link(1000)

IO.puts("🚀 Started 3 components with GLOBAL clock:")
IO.puts("   • PaymentProcessor: processes every 100ms")
IO.puts("   • Analytics:        aggregates every 500ms")
IO.puts("   • Monitor:          heartbeat every 1000ms")
IO.puts("")

# Advance time - ALL components move forward together
start_time = System.monotonic_time(:millisecond)
VirtualClock.advance(global_clock, 5000)
elapsed = System.monotonic_time(:millisecond) - start_time

{payments, total_amount} = PaymentProcessor.get_stats(payment_processor)
reports = AnalyticsAggregator.get_reports(analytics)
heartbeats = HeartbeatMonitor.get_heartbeats(monitor)

IO.puts("⏱️  Advanced 5 seconds of VIRTUAL time")
IO.puts("📊 Results:")
IO.puts("   • PaymentProcessor: #{payments} payments, $#{total_amount} total")
IO.puts("   • Analytics:        #{reports} reports generated")
IO.puts("   • Monitor:          #{heartbeats} heartbeats sent")
IO.puts("")
IO.puts("✨ Real time elapsed: #{elapsed}ms (#{div(5000, elapsed)}x speedup!)")
IO.puts("")
IO.puts("💡 Key Point: All components advanced together in ONE coordinated timeline.")

# Clean up
GenServer.stop(payment_processor)
GenServer.stop(analytics)
GenServer.stop(monitor)

Process.sleep(100)

# ============================================================================
# SCENARIO 2: LOCAL CLOCK - Isolated Simulations
# ============================================================================

IO.puts("""

┌────────────────────────────────────────────────────────────────────┐
│ SCENARIO 2: LOCAL CLOCK (Isolated Simulations)                    │
└────────────────────────────────────────────────────────────────────┘

Use Case: Running multiple independent simulations in parallel, or
testing components in complete isolation. Each system has its own
independent timeline.

""")

# Create separate clocks for different systems
{:ok, payment_clock} = VirtualClock.start_link()
{:ok, analytics_clock} = VirtualClock.start_link()

# Start components with LOCAL clocks (not using global setting)
VirtualTimeGenServer.use_real_time()  # Clear any global clock

{:ok, payment_system} =
  VirtualTimeGenServer.start_link(PaymentProcessor, 50, virtual_clock: payment_clock)

{:ok, analytics_system} =
  VirtualTimeGenServer.start_link(AnalyticsAggregator, 200, virtual_clock: analytics_clock)

IO.puts("🚀 Started 2 INDEPENDENT systems:")
IO.puts("   • Payment System:   own clock, 50ms interval")
IO.puts("   • Analytics System: own clock, 200ms interval")
IO.puts("")

# Test payment system at high speed
IO.puts("💳 Testing Payment System (advancing 1 second)...")
start_time = System.monotonic_time(:millisecond)
VirtualClock.advance(payment_clock, 1000)
elapsed = System.monotonic_time(:millisecond) - start_time

{payments, _amount} = PaymentProcessor.get_stats(payment_system)
reports = AnalyticsAggregator.get_reports(analytics_system)

IO.puts("   Payments processed: #{payments}")
IO.puts("   Analytics reports:  #{reports} (unchanged!)")
IO.puts("   Real time: #{elapsed}ms")
IO.puts("")

# Test analytics system independently
IO.puts("📊 Testing Analytics System (advancing 2 seconds)...")
start_time = System.monotonic_time(:millisecond)
VirtualClock.advance(analytics_clock, 2000)
elapsed = System.monotonic_time(:millisecond) - start_time

{payments, _amount} = PaymentProcessor.get_stats(payment_system)
reports = AnalyticsAggregator.get_reports(analytics_system)

IO.puts("   Payments processed: #{payments} (unchanged!)")
IO.puts("   Analytics reports:  #{reports}")
IO.puts("   Real time: #{elapsed}ms")
IO.puts("")

IO.puts("💡 Key Point: Each system operates on its OWN independent timeline.")
IO.puts("   Perfect for parallel testing or component isolation!")

# Clean up
GenServer.stop(payment_system)
GenServer.stop(analytics_system)

Process.sleep(100)

# ============================================================================
# SCENARIO 3: MIXED MODE - Virtual + Real Time
# ============================================================================

IO.puts("""

┌────────────────────────────────────────────────────────────────────┐
│ SCENARIO 3: MIXED MODE (Virtual + Real Time)                      │
└────────────────────────────────────────────────────────────────────┘

Use Case: Integration testing where business logic uses virtual time
but external systems (databases, APIs) operate on real time.

""")

{:ok, mixed_clock} = VirtualClock.start_link()

# Virtual time for business logic
{:ok, virtual_payment} =
  VirtualTimeGenServer.start_link(PaymentProcessor, 100, virtual_clock: mixed_clock)

# Real time for external system integration
{:ok, real_monitor} = VirtualTimeGenServer.start_link(HeartbeatMonitor, 50, real_time: true)

IO.puts("🚀 Started MIXED mode:")
IO.puts("   • PaymentProcessor: VIRTUAL time (100ms interval)")
IO.puts("   • Monitor:          REAL time (50ms interval)")
IO.puts("")

# Advance virtual time instantly
IO.puts("⏱️  Advancing virtual time by 500ms (instant)...")
VirtualClock.advance(mixed_clock, 500)

{payments, _} = PaymentProcessor.get_stats(virtual_payment)
heartbeats = HeartbeatMonitor.get_heartbeats(real_monitor)

IO.puts("📊 Immediate results:")
IO.puts("   • Virtual payments: #{payments} (instant!)")
IO.puts("   • Real heartbeats:  #{heartbeats} (needs real time)")
IO.puts("")

# Wait for real time
IO.puts("⏰ Waiting 150ms of REAL time...")
Process.sleep(150)

{payments, _} = PaymentProcessor.get_stats(virtual_payment)
heartbeats = HeartbeatMonitor.get_heartbeats(real_monitor)

IO.puts("📊 After real time:")
IO.puts("   • Virtual payments: #{payments} (unchanged)")
IO.puts("   • Real heartbeats:  #{heartbeats} (increased!)")
IO.puts("")

IO.puts("💡 Key Point: Mix virtual time for fast testing with real time")
IO.puts("   for external integrations. Best of both worlds!")

# Clean up
GenServer.stop(virtual_payment)
GenServer.stop(real_monitor)

# ============================================================================
# SUMMARY
# ============================================================================

IO.puts("""

╔════════════════════════════════════════════════════════════════════╗
║                            SUMMARY                                 ║
╚════════════════════════════════════════════════════════════════════╝

Choose the right mode for your use case:

┌────────────────────────────────────────────────────────────────────┐
│ GLOBAL CLOCK                                                       │
├────────────────────────────────────────────────────────────────────┤
│ {:ok, clock} = VirtualClock.start_link()                           │
│ VirtualTimeGenServer.set_virtual_clock(clock)                      │
│ {:ok, server} = MyServer.start_link()                              │
│                                                                    │
│ ✅ Use when:                                                       │
│   • Testing complete actor systems                                │
│   • Components must interact with timing relationships            │
│   • You want all actors to advance together                       │
│                                                                    │
│ 🎯 Examples: Chat apps, trading systems, game servers             │
└────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│ LOCAL CLOCK                                                        │
├────────────────────────────────────────────────────────────────────┤
│ {:ok, clock} = VirtualClock.start_link()                           │
│ {:ok, server} = VirtualTimeGenServer.start_link(                   │
│   MyServer, :ok, virtual_clock: clock                              │
│ )                                                                  │
│                                                                    │
│ ✅ Use when:                                                       │
│   • Running multiple independent simulations                      │
│   • Testing components in isolation                               │
│   • Parallel test scenarios                                       │
│   • Each system needs its own timeline                            │
│                                                                    │
│ 🎯 Examples: Microservices tests, parallel simulations            │
└────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│ MIXED MODE                                                         │
├────────────────────────────────────────────────────────────────────┤
│ {:ok, clock} = VirtualClock.start_link()                           │
│ {:ok, virtual} = VirtualTimeGenServer.start_link(                  │
│   MyServer, :ok, virtual_clock: clock                              │
│ )                                                                  │
│ {:ok, real} = VirtualTimeGenServer.start_link(                     │
│   MyServer, :ok, real_time: true                                   │
│ )                                                                  │
│                                                                    │
│ ✅ Use when:                                                       │
│   • Integration testing with external systems                     │
│   • Mixing fast virtual logic with real I/O                       │
│   • Performance benchmarking                                      │
│                                                                    │
│ 🎯 Examples: Database integrations, API tests                     │
└────────────────────────────────────────────────────────────────────┘

For more details, see docs/development/README.md
""")

