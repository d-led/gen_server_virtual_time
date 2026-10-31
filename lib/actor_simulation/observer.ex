defmodule ActorSimulation.Observer do
  @moduledoc """
  Collects message statistics for actors that are real servers rather than
  simulated ones.

  A simulated actor counts its own messages in its state. A real server in the
  loop (see `ActorSimulation.add_process/3`) has no such state to extend, so
  `ActorSimulation` instruments it with this observer and reads the counters back
  with `VirtualTimeGenServer.snapshot/1`.

  Counters live in the observed process, which is where the messages happen:
  `on_receive/2` runs in the server, `on_send/2` in the process that sends.
  """

  @behaviour VirtualTimeGenServer.Instrumentation

  @counters_key :actor_simulation_message_counters

  @initial_counters %{sent_count: 0, received_count: 0}

  @impl true
  def on_receive({_kind, _message}, _meta), do: count(:received_count)

  @impl true
  def on_send({_kind, _message}, _meta), do: count(:sent_count)

  @impl true
  def snapshot(_context) do
    counters = Process.get(@counters_key, @initial_counters)

    %{
      sent_count: counters.sent_count,
      received_count: counters.received_count,
      sent_messages: [],
      received_messages: []
    }
  end

  defp count(counter) do
    counters = Process.get(@counters_key, @initial_counters)
    Process.put(@counters_key, Map.update!(counters, counter, &(&1 + 1)))
    :ok
  end
end
