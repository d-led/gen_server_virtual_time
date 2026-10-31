defmodule VirtualClockLifecycleTest do
  @moduledoc """
  A `VirtualClock` owns a second process: the scheduler that holds its queue of
  pending events. These tests hold the lifecycle contract — when the clock goes,
  the scheduler goes with it.

  A leaked scheduler is invisible in a short test run and fatal in a long one: a
  suite that creates clocks in a loop runs out of processes. So the leak is
  asserted on directly.
  """

  use ExUnit.Case, async: false

  test "a running clock has a scheduler, and stopping the clock stops it" do
    before = scheduler_count()

    {:ok, clock} = VirtualClock.start_link()
    assert scheduler_count() == before + 1

    GenServer.stop(clock)
    assert scheduler_count() == before
  end

  test "a hundred clock lifecycles leave no schedulers behind" do
    before = scheduler_count()

    for _ <- 1..100 do
      {:ok, clock} = VirtualClock.start_link()
      VirtualClock.advance(clock, 10)
      GenServer.stop(clock)
    end

    assert scheduler_count() == before
  end

  test "a killed clock takes its scheduler with it" do
    before = scheduler_count()
    previous = Process.flag(:trap_exit, true)
    on_exit(fn -> Process.flag(:trap_exit, previous) end)

    for _ <- 1..20 do
      {:ok, clock} = VirtualClock.start_link()
      VirtualClock.advance(clock, 10)
      Process.exit(clock, :kill)
      assert_receive {:EXIT, ^clock, :killed}, 500
    end

    assert scheduler_count() == before
  end

  # Schedulers are the processes whose initial call is the scheduler module.
  defp scheduler_count do
    Enum.count(:erlang.processes(), fn pid ->
      case :erlang.process_info(pid, :dictionary) do
        {:dictionary, dictionary} ->
          Keyword.get(dictionary, :"$initial_call") == {VirtualClock.VirtualScheduler, :init, 1}

        _not_alive ->
          false
      end
    end)
  end
end
