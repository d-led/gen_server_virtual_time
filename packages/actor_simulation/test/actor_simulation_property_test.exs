defmodule ActorSimulationPropertyTest do
  @moduledoc """
  Property-based specification of the simulation behaviour.

  The point of a virtual-time simulation is that the *observed* traffic matches
  the declared pattern. These properties check that message counts, delivery and
  trace timestamps all agree with the pattern an actor was configured with -
  rather than re-stating the counting formula in the test.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  # Runs a two-actor simulation: `:sender` uses `pattern` to message `:receiver`.
  defp run_pair(pattern, duration, sim_opts \\ []) do
    ActorSimulation.new(sim_opts)
    |> ActorSimulation.add_actor(:sender, send_pattern: pattern, targets: [:receiver])
    |> ActorSimulation.add_actor(:receiver)
    |> ActorSimulation.run(duration: duration)
  end

  property "a periodic actor sends one message per interval, all received" do
    check all(interval <- integer(10..500), periods <- integer(1..10)) do
      duration = interval * periods

      stats = run_pair({:periodic, interval, :tick}, duration) |> ActorSimulation.get_stats()

      assert stats.actors[:sender].sent_count == periods
      assert stats.actors[:receiver].received_count == periods
      assert stats.total_messages == 2 * periods
    end
  end

  property "a burst actor sends its whole batch every interval" do
    check all(interval <- integer(10..300), batch <- integer(1..5), periods <- integer(1..6)) do
      duration = interval * periods

      stats =
        run_pair({:burst, batch, interval, :event}, duration) |> ActorSimulation.get_stats()

      assert stats.actors[:sender].sent_count == batch * periods
      assert stats.actors[:receiver].received_count == batch * periods
    end
  end

  property "traced messages carry the virtual time at which they were sent" do
    check all(interval <- integer(10..500), periods <- integer(1..8)) do
      duration = interval * periods

      trace =
        run_pair({:periodic, interval, :tick}, duration, trace: true)
        |> ActorSimulation.get_trace()

      assert Enum.map(trace, & &1.timestamp) == Enum.map(1..periods, &(&1 * interval))

      assert Enum.all?(trace, fn event ->
               event.from == :sender and event.to == :receiver and event.type == :send
             end)
    end
  end

  property "an actor sends one message per interval to each of its targets" do
    check all(
            interval <- integer(10..300),
            periods <- integer(1..5),
            target_count <- integer(1..4)
          ) do
      duration = interval * periods
      targets = Enum.map(1..target_count, &:"receiver_#{&1}")
      receivers = targets

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, interval, :tick},
          targets: targets
        )
        |> then(fn simulation ->
          Enum.reduce(receivers, simulation, fn name, acc ->
            ActorSimulation.add_actor(acc, name)
          end)
        end)
        |> ActorSimulation.run(duration: duration)

      stats = ActorSimulation.get_stats(simulation)

      assert stats.actors[:sender].sent_count == periods * target_count

      assert Enum.all?(targets, fn target ->
               stats.actors[target].received_count == periods
             end)
    end
  end
end
