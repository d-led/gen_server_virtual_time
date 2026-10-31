defmodule DeliveryAcknowledgementTest do
  @moduledoc """
  The clock only moves on once every delivery it handed out has been handled.
  That is what makes exact message counts safe to assert: a slow or busy machine
  changes how long a test *takes*, never what it *observes*.

  These tests make actors deliberately slow in real time and check that the
  simulation still produces exactly the timeline the DSL describes.
  """

  use ExUnit.Case, async: true

  defmodule SlowTicker do
    @moduledoc """
    Ticks once per virtual second and takes real time over each tick, standing in
    for an actor on a loaded machine.
    """
    use VirtualTimeGenServer

    def start_link(opts) do
      VirtualTimeGenServer.start_link(__MODULE__, :ok, opts)
    end

    def ticks(server) do
      VirtualTimeGenServer.call(server, :ticks)
    end

    @impl true
    def init(:ok) do
      VirtualTimeGenServer.send_after(self(), :tick, 100)
      {:ok, 0}
    end

    @impl true
    def handle_info(:tick, ticks) do
      # Real time burned per message: the clock must wait for this, not race it.
      Process.sleep(200)
      VirtualTimeGenServer.send_after(self(), :tick, 100)
      {:noreply, ticks + 1}
    end

    @impl true
    def handle_call(:ticks, _from, ticks) do
      {:reply, ticks, ticks}
    end
  end

  test "an actor that is slow in real time keeps its exact virtual timeline" do
    {:ok, clock} = VirtualClock.start_link()
    {:ok, ticker} = SlowTicker.start_link(virtual_clock: clock)

    # 3 ticks, each costing 200ms of real time to handle: far longer than a
    # per-message budget would tolerate if the clock were racing the actor.
    assert VirtualClock.advance(clock, 300) == {:ok, 300}

    assert SlowTicker.ticks(ticker) == 3
    assert VirtualClock.now(clock) == 300
  end

  test "the same holds inside a full actor simulation" do
    simulation =
      ActorSimulation.new()
      |> ActorSimulation.add_actor(:producer,
        send_pattern: {:periodic, 100, :ping},
        targets: [:consumer]
      )
      |> ActorSimulation.add_actor(:consumer, on_receive: fn _msg, state -> {:ok, state} end)
      |> ActorSimulation.run(duration: 1000)

    stats = ActorSimulation.get_stats(simulation)

    assert stats.actors[:producer].sent_count == 10
    assert stats.actors[:consumer].received_count == 10

    ActorSimulation.stop(simulation)
  end

  describe "the acknowledgement budget" do
    test "is a safety net: an impatient budget gives up rather than hanging" do
      # A budget this small can only be reached by an actor that is not answering
      # in time, which is what the watchdog exists for.
      {:ok, clock} = VirtualClock.start_link(ack_timeout_ms: 1)
      {:ok, _ticker} = SlowTicker.start_link(virtual_clock: clock)

      log =
        ExUnit.CaptureLog.capture_log(fn ->
          assert VirtualClock.advance(clock, 300) == {:ok, 300}
        end)

      assert log =~ "were not acknowledged in time"
    end
  end
end
