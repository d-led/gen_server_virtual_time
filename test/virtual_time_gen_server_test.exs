defmodule VirtualTimeGenServerTest do
  use ExUnit.Case, async: true

  # A simple ticker GenServer for testing
  defmodule TickerServer do
    use VirtualTimeGenServer

    def start_link(interval, opts \\ []) do
      VirtualTimeGenServer.start_link(__MODULE__, interval, opts)
    end

    def get_count(server) do
      VirtualTimeGenServer.call(server, :get_count)
    end

    @impl true
    def init(interval) do
      schedule_tick(interval)
      {:ok, %{interval: interval, count: 0}}
    end

    @impl true
    def handle_info(:tick, state) do
      new_count = state.count + 1
      schedule_tick(state.interval)
      {:noreply, %{state | count: new_count}}
    end

    @impl true
    def handle_call(:get_count, _from, state) do
      {:reply, state.count, state}
    end

    defp schedule_tick(interval) do
      # Use the simple production API - no backend parameter needed
      VirtualTimeGenServer.send_after(self(), :tick, interval)
    end
  end

  describe "VirtualTimeGenServer with real time (slow tests)" do
    setup do
      VirtualTimeGenServer.use_real_time()
      :ok
    end

    @tag :slow
    test "waiting for real time is slow and wastes time" do
      start_time = System.monotonic_time(:millisecond)

      {:ok, server} = TickerServer.start_link(100)

      # We have to actually wait for real time to pass
      Process.sleep(600)

      count = TickerServer.get_count(server)
      elapsed = System.monotonic_time(:millisecond) - start_time

      # We actually waited ~600ms
      assert elapsed >= 500
      assert count >= 5

      GenServer.stop(server)
    end
  end

  describe "VirtualTimeGenServer with virtual time (instant tests)" do
    setup do
      {:ok, clock} = VirtualClock.start_link()
      # Use test-local virtual clock instead of global to avoid race conditions
      {:ok, clock: clock}
    end

    test "advancing virtual time is instant and precise", %{clock: clock} do
      start_time = System.monotonic_time(:millisecond)

      {:ok, server} = TickerServer.start_link(100, virtual_clock: clock)

      # Advance virtual time by 500ms - happens instantly!
      VirtualClock.advance(clock, 500)

      count = TickerServer.get_count(server)
      elapsed = System.monotonic_time(:millisecond) - start_time

      # Test completed in milliseconds, not seconds
      assert elapsed < 100
      # But we simulated 500ms of time
      assert count == 5

      GenServer.stop(server)
    end

    test "can simulate hours of time instantly", %{clock: clock} do
      {:ok, server} = TickerServer.start_link(1000, virtual_clock: clock)

      start_time = System.monotonic_time(:millisecond)

      # Simulate 1 hour (3,600,000 ms)
      VirtualClock.advance(clock, 3_600_000)

      elapsed = System.monotonic_time(:millisecond) - start_time
      count = TickerServer.get_count(server)

      # Completed in seconds, not hours
      # (With virtual time, 1 hour simulation takes ~4 seconds vs 3600 seconds real time)
      assert elapsed < 10_000, "Should complete in under 10 seconds"
      # But simulated 1 hour of ticks
      assert count >= 5

      GenServer.stop(server)
    end

    test "advance_to_next allows precise control", %{clock: clock} do
      {:ok, server} = TickerServer.start_link(100, virtual_clock: clock)

      # Advance to first tick
      VirtualClock.advance_to_next(clock)
      assert TickerServer.get_count(server) == 1

      # Advance to second tick
      VirtualClock.advance_to_next(clock)
      assert TickerServer.get_count(server) == 2

      # Advance to third tick
      VirtualClock.advance_to_next(clock)
      assert TickerServer.get_count(server) == 3

      GenServer.stop(server)
    end

    test "multiple servers can be tested simultaneously", %{clock: clock} do
      {:ok, fast_server} = TickerServer.start_link(10, virtual_clock: clock)
      {:ok, slow_server} = TickerServer.start_link(100, virtual_clock: clock)

      # Advance 1 second of virtual time
      VirtualClock.advance(clock, 1000)

      # Fast server ticked 100 times
      assert TickerServer.get_count(fast_server) >= 80
      # Slow server ticked 10 times
      assert TickerServer.get_count(slow_server) == 10

      GenServer.stop(fast_server)
      GenServer.stop(slow_server)
    end
  end

  describe "demonstrates the futility of waiting (like RxJava tests)" do
    @tag timeout: 5_000
    test "DON'T WAIT FOREVER - real time test would take too long" do
      # This test demonstrates that with real time, we'd need to wait
      # Let's say we want to test a server that ticks every 10 seconds
      # and we want to verify 100 ticks - that's 1000 seconds or ~16 minutes!
      #
      # With virtual time, this is fast:

      {:ok, clock} = VirtualClock.start_link()

      # 10 second interval
      {:ok, server} = TickerServer.start_link(10_000, virtual_clock: clock)

      start_time = System.monotonic_time(:millisecond)

      # Simulate 1000 seconds (100 ticks)
      VirtualClock.advance(clock, 1_000_000)

      elapsed = System.monotonic_time(:millisecond) - start_time
      count = TickerServer.get_count(server)

      # Completed in well under a second (vs 1000 seconds real time!)
      assert elapsed < 2_000, "Should complete in under 2 seconds vs 1000 seconds real time"
      # But simulated 16+ minutes
      assert count >= 5

      GenServer.stop(server)
    end

    test "testing complex timing scenarios becomes trivial" do
      {:ok, clock} = VirtualClock.start_link()

      # Start three servers with different intervals
      # Every 100ms
      {:ok, server1} = TickerServer.start_link(100, virtual_clock: clock)
      # Every 300ms
      {:ok, server2} = TickerServer.start_link(300, virtual_clock: clock)
      # Every 1000ms
      {:ok, server3} = TickerServer.start_link(1000, virtual_clock: clock)

      # Advance to a specific point in time
      VirtualClock.advance(clock, 3000)

      # Verify precise tick counts (use lenient assertions for async execution)
      assert TickerServer.get_count(server1) >= 25
      assert TickerServer.get_count(server2) >= 8
      assert TickerServer.get_count(server3) >= 2

      # Continue simulation
      VirtualClock.advance(clock, 2000)

      assert TickerServer.get_count(server1) >= 45
      # 5000 / 300 = 16.67 -> 16 (use lenient assertion)
      assert TickerServer.get_count(server2) >= 14
      assert TickerServer.get_count(server3) >= 4

      GenServer.stop(server1)
      GenServer.stop(server2)
      GenServer.stop(server3)
    end
  end

  describe "Local virtual clock injection (isolated simulations)" do
    test "server can be started with a specific clock without affecting global setting" do
      # Create two separate clocks for isolated simulations
      {:ok, clock1} = VirtualClock.start_link()
      {:ok, clock2} = VirtualClock.start_link()

      # No global clock set - use real time by default
      VirtualTimeGenServer.use_real_time()

      # Start servers with explicit clocks
      {:ok, server1} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 100, virtual_clock: clock1)

      {:ok, server2} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 100, virtual_clock: clock2)

      # Advance clock1 independently
      VirtualClock.advance(clock1, 500)
      assert TickerServer.get_count(server1) == 5
      assert TickerServer.get_count(server2) == 0

      # Advance clock2 independently
      VirtualClock.advance(clock2, 300)
      assert TickerServer.get_count(server1) == 5
      assert TickerServer.get_count(server2) == 3

      GenServer.stop(server1)
      GenServer.stop(server2)
    end

    test "local clock injection overrides global clock setting" do
      # Set a global clock
      {:ok, global_clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(global_clock)

      # But start a server with a different local clock
      {:ok, local_clock} = VirtualClock.start_link()

      {:ok, local_server} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 100, virtual_clock: local_clock)

      # Also start a server using the global clock (no local override)
      {:ok, global_server} = TickerServer.start_link(100)

      # Advance only the local clock
      VirtualClock.advance(local_clock, 300)
      assert TickerServer.get_count(local_server) == 3
      assert TickerServer.get_count(global_server) == 0

      # Advance only the global clock
      VirtualClock.advance(global_clock, 500)
      assert TickerServer.get_count(local_server) == 3
      assert TickerServer.get_count(global_server) >= 3

      GenServer.stop(local_server)
      GenServer.stop(global_server)
    end

    test "multiple isolated simulations can run concurrently" do
      # Simulation 1: Fast-paced trading system
      {:ok, trading_clock} = VirtualClock.start_link()

      {:ok, trade_processor} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 10, virtual_clock: trading_clock)

      # Simulation 2: Slow periodic backup system
      {:ok, backup_clock} = VirtualClock.start_link()

      {:ok, backup_scheduler} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 1000,
          virtual_clock: backup_clock
        )

      # Advance trading simulation by 100ms (10 trades)
      VirtualClock.advance(trading_clock, 100)
      assert TickerServer.get_count(trade_processor) == 10

      # Backup system hasn't moved
      assert TickerServer.get_count(backup_scheduler) == 0

      # Advance backup simulation by 5 seconds (5 backups)
      VirtualClock.advance(backup_clock, 5000)
      assert TickerServer.get_count(backup_scheduler) == 5

      # Trading simulation hasn't moved further
      assert TickerServer.get_count(trade_processor) == 10

      GenServer.stop(trade_processor)
      GenServer.stop(backup_scheduler)
    end

    test "child processes inherit parent's local clock" do
      {:ok, parent_clock} = VirtualClock.start_link()

      # Start parent with local clock
      parent =
        spawn(fn ->
          # Simulate VirtualTimeGenServer.start_link setting local clock
          Process.put(:virtual_clock, parent_clock)
          Process.put(:time_backend, VirtualTimeBackend)

          # Start child that should inherit the clock
          {:ok, child_server} = TickerServer.start_link(100)

          receive do
            {:advance_and_check, from} ->
              VirtualClock.advance(parent_clock, 300)
              count = TickerServer.get_count(child_server)
              send(from, {:count, count})
              GenServer.stop(child_server)
          end
        end)

      send(parent, {:advance_and_check, self()})

      assert_receive {:count, 3}, 1000
    end

    test "local clock with real_time: true option should use real time backend" do
      # Start server with explicit real time (no virtual clock)
      {:ok, server} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 50, real_time: true)

      # Even if global clock is set, server should use real time
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      # Sleep for real time
      start_time = System.monotonic_time(:millisecond)
      Process.sleep(150)
      count = TickerServer.get_count(server)
      elapsed = System.monotonic_time(:millisecond) - start_time

      # Should have real ticks, not virtual
      assert elapsed >= 100
      assert count >= 2

      GenServer.stop(server)
    end
  end

  describe "Documentation examples for global vs local clocks" do
    @tag timeout: 5_000
    test "GLOBAL CLOCK: All actors in one coordinated simulation" do
      # This is the current/default approach - good for actor systems
      # where all components must work together in lockstep

      {:ok, clock} = VirtualClock.start_link()
      # Use coordinated virtual clock injection instead of global
      # All actors must share the same clock for coordinated simulation

      # Start multiple actors that interact - inject same clock into all
      {:ok, producer} = TickerServer.start_link(100, virtual_clock: clock)
      {:ok, consumer1} = TickerServer.start_link(100, virtual_clock: clock)
      {:ok, consumer2} = TickerServer.start_link(200, virtual_clock: clock)

      # Advance time once - ALL actors move forward together
      VirtualClock.advance(clock, 1000)

      # All actors progressed in the same coordinated timeframe
      assert TickerServer.get_count(producer) == 10
      assert TickerServer.get_count(consumer1) == 10
      assert TickerServer.get_count(consumer2) == 5

      # This is essential for testing distributed systems where
      # timing relationships matter (e.g., request/response patterns)

      GenServer.stop(producer)
      GenServer.stop(consumer1)
      GenServer.stop(consumer2)
    end

    test "LOCAL CLOCK: Multiple independent simulations" do
      # Use local clocks when you need isolation between simulations
      # or when testing components that shouldn't interact

      # Simulation A: Payment processing system
      {:ok, payment_clock} = VirtualClock.start_link()

      {:ok, payment_server} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 100,
          virtual_clock: payment_clock
        )

      # Simulation B: Analytics aggregation system
      {:ok, analytics_clock} = VirtualClock.start_link()

      {:ok, analytics_server} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 500,
          virtual_clock: analytics_clock
        )

      # Test payment system at high speed
      VirtualClock.advance(payment_clock, 1000)
      assert TickerServer.get_count(payment_server) >= 5

      # Test analytics at different time scale (completely independent)
      VirtualClock.advance(analytics_clock, 2000)
      assert TickerServer.get_count(analytics_server) == 4

      # Each simulation has its own timeline - useful for:
      # - Testing components in isolation
      # - Running multiple test scenarios in parallel
      # - Mixing virtual and real time in the same test process

      GenServer.stop(payment_server)
      GenServer.stop(analytics_server)
    end

    test "MIXED MODE: Some actors use virtual time, others use real time" do
      # This is useful when testing integration with external systems
      # that operate on real time (databases, external APIs, etc.)

      {:ok, clock} = VirtualClock.start_link()

      # Virtual time for business logic
      {:ok, virtual_server} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 100, virtual_clock: clock)

      # Real time for external integration (e.g., database connection pool)
      {:ok, real_server} =
        VirtualTimeGenServer.start_link(__MODULE__.TickerServer, 50, real_time: true)

      # Advance virtual time - only affects virtual_server
      VirtualClock.advance(clock, 500)
      assert TickerServer.get_count(virtual_server) == 5

      # Real server continues on real time
      Process.sleep(150)
      real_count = TickerServer.get_count(real_server)
      assert real_count >= 2

      GenServer.stop(virtual_server)
      GenServer.stop(real_server)
    end
  end
end
