defmodule VirtualVsRealTimeSpeedTest do
  use ExUnit.Case, async: true

  # A simple message sender for testing
  defmodule MessageSender do
    use VirtualTimeGenServer

    def start_link(delay, test_pid, opts \\ []) do
      VirtualTimeGenServer.start_link(__MODULE__, {delay, test_pid}, opts)
    end

    @impl true
    def init({delay, test_pid}) do
      # Send a message after the specified delay
      VirtualTimeGenServer.send_after(self(), :message, delay)
      {:ok, %{delay: delay, test_pid: test_pid}}
    end

    @impl true
    def handle_info(:message, state) do
      # Send the message to the test process
      send(state.test_pid, :received_message)
      {:noreply, state}
    end
  end

  describe "VirtualTimeGenServer as drop-in replacement" do
    test "production mode: works exactly like GenServer with real time" do
      # VirtualTimeGenServer is a drop-in replacement for GenServer
      # In production, it behaves exactly like GenServer with real time
      {:ok, sender} = MessageSender.start_link(100, self())

      # Measure how long assert_receive takes with real time
      real_time_elapsed =
        measure_time(fn ->
          # This will actually wait for 100ms in real time (just like GenServer)
          assert_receive :received_message, 200
        end)

      # With real time, this should take approximately 100ms (like GenServer)
      # At least 80ms (allowing some tolerance)
      assert real_time_elapsed >= 80
      # But not too much more than 100ms
      assert real_time_elapsed <= 150

      # Clean up
      GenServer.stop(sender)
    end

    test "testing mode: virtual time injection makes tests lightning fast" do
      # For testing, we can inject virtual time to make tests instant
      {:ok, clock} = VirtualClock.start_link()

      # Pass the clock directly to this specific server (test-local)
      {:ok, sender} = MessageSender.start_link(100, self(), virtual_clock: clock)

      # Advance the virtual clock to trigger the message instantly
      VirtualClock.advance(clock, 100)

      # Measure how long assert_receive takes with virtual time
      virtual_time_elapsed =
        measure_time(fn ->
          # This should be instant with virtual time
          assert_receive :received_message, 200
        end)

      # With virtual time, this should complete in milliseconds, not 100ms
      # Much faster than 100ms
      assert virtual_time_elapsed < 50

      # Clean up
      GenServer.stop(sender)
    end

    test "demonstrates drop-in replacement: same code, different performance" do
      # Same module, same code - but different performance based on time injection

      # Test 1: Production mode (real time, like GenServer)
      {:ok, production_sender} = MessageSender.start_link(100, self())

      production_elapsed =
        measure_time(fn ->
          # This will actually wait for 100ms in real time (like GenServer)
          assert_receive :received_message, 200
        end)

      GenServer.stop(production_sender)

      # Test 2: Testing mode (virtual time injection)
      {:ok, virtual_clock} = VirtualClock.start_link()

      # Pass the clock directly to this specific server (test-local)
      {:ok, testing_sender} = MessageSender.start_link(100, self(), virtual_clock: virtual_clock)

      # Advance the virtual clock to trigger the message instantly
      VirtualClock.advance(virtual_clock, 100)

      testing_elapsed =
        measure_time(fn ->
          assert_receive :received_message, 200
        end)

      GenServer.stop(testing_sender)

      # Production mode should take real time
      # Testing mode should be instant
      # Real time: >= 80ms
      assert production_elapsed >= 80
      # Virtual time: < 50ms
      assert testing_elapsed < 50

      # Calculate speedup (handle case where testing_elapsed might be 0)
      speedup =
        if testing_elapsed > 0, do: production_elapsed / testing_elapsed, else: production_elapsed

      # At least 2x faster
      assert speedup > 2

      IO.puts("\n🚀 Drop-in Replacement Performance:")
      IO.puts("  Production mode (real time): #{production_elapsed}ms")
      IO.puts("  Testing mode (virtual time): #{testing_elapsed}ms")
      IO.puts("  Speedup: #{speedup}x faster!")
    end
  end

  # Helper function to measure elapsed time
  defp measure_time(callback) do
    start_time = System.monotonic_time(:millisecond)
    callback.()
    System.monotonic_time(:millisecond) - start_time
  end
end
