defmodule ActorSimulation.DefinitionPropertyTest do
  @moduledoc """
  Laws for a send pattern: what the DSL promises about *when* an actor sends.

  The code generators read the same patterns to lay out timing in C++, Go, Rust,
  Java and Pony, so a pattern that means one thing to the simulator and another
  to a generator would silently produce a project with the wrong timeline. These
  properties pin the meaning of each pattern, and pin that both readers agree.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ActorSimulation.Definition
  alias ActorSimulation.GeneratorUtils

  describe "a pattern describes when its messages are sent" do
    property "a periodic actor sends every interval it was given" do
      check all(interval <- positive_ms(), message <- message()) do
        assert Definition.interval_for_pattern({:periodic, interval, message}) == interval
        assert Definition.messages_for_pattern({:periodic, interval, message}) == [message]
      end
    end

    property "a burst sends its messages every interval it was given" do
      check all(interval <- positive_ms(), count <- integer(1..10), message <- message()) do
        assert Definition.interval_for_pattern({:burst, count, interval, message}) == interval

        assert Definition.messages_for_pattern({:burst, count, interval, message}) ==
                 List.duplicate(message, count)
      end
    end

    property "a one-shot message fires after its delay" do
      check all(delay <- positive_ms(), message <- message()) do
        assert Definition.interval_for_pattern({:self_message, delay, message}) == delay
        assert Definition.messages_for_pattern({:self_message, delay, message}) == [message]
      end
    end

    property "a rate of n per second waits a second divided by n" do
      check all(per_second <- integer(1..1000), message <- message()) do
        interval = Definition.interval_for_pattern({:rate, per_second, message})
        assert Definition.messages_for_pattern({:rate, per_second, message}) == [message]

        # n intervals have to fit in a second and n + 1 have to overflow it. That
        # is what "per second" means, whatever rounding the interval needs.
        assert per_second * interval <= 1000
        assert per_second * (interval + 1) > 1000
      end
    end

    property "asking for a higher rate never asks for a longer wait" do
      check all(slower <- integer(1..1000), extra <- integer(0..1000), message <- message()) do
        faster = slower + extra

        assert Definition.interval_for_pattern({:rate, faster, message}) <=
                 Definition.interval_for_pattern({:rate, slower, message})
      end
    end

    property "an actor with no pattern has no interval and sends nothing" do
      assert Definition.interval_for_pattern(nil) == nil
      assert Definition.messages_for_pattern(nil) == []
    end
  end

  describe "the simulator and the code generators read a pattern the same way" do
    property "they agree on the interval" do
      check all(pattern <- pattern()) do
        assert Definition.interval_for_pattern(pattern) ==
                 GeneratorUtils.pattern_interval(pattern)
      end
    end

    property "they agree on which messages a pattern carries" do
      check all(pattern <- pattern()) do
        # A burst repeats one message; the generators care about the message set.
        assert Definition.messages_for_pattern(pattern) |> Enum.uniq() |> Enum.sort() ==
                 GeneratorUtils.extract_messages(pattern) |> Enum.sort()
      end
    end
  end

  defp positive_ms, do: integer(1..100_000)

  defp message, do: member_of([:msg, :tick, :data, "event", {:payload, 1}])

  defp pattern do
    one_of([
      constant(nil),
      tuple({constant(:periodic), positive_ms(), message()}),
      tuple({constant(:rate), integer(1..1000), message()}),
      tuple({constant(:burst), integer(1..10), positive_ms(), message()}),
      tuple({constant(:self_message), positive_ms(), message()})
    ])
  end
end
