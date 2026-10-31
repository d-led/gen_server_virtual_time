defmodule ActorSimulation.DefinitionTest do
  use ExUnit.Case, async: true

  alias ActorSimulation.Definition

  describe "Definition.new/2" do
    test "creates definition with name and options" do
      def = Definition.new(:worker, send_pattern: {:periodic, 100, :tick})

      assert def.name == :worker
      assert def.send_pattern == {:periodic, 100, :tick}
    end

    test "defaults targets to empty list" do
      def = Definition.new(:solo, [])

      assert def.targets == []
    end

    test "accepts custom targets" do
      def = Definition.new(:sender, targets: [:receiver1, :receiver2])

      assert def.targets == [:receiver1, :receiver2]
    end

    test "defaults initial_state to empty map" do
      def = Definition.new(:stateful, [])

      assert def.initial_state == %{}
    end

    test "accepts custom initial_state" do
      def = Definition.new(:counter, initial_state: %{count: 0})

      assert def.initial_state == %{count: 0}
    end

    test "accepts on_receive callback" do
      callback = fn _msg, state -> state end
      def = Definition.new(:reactor, on_receive: callback)

      assert def.on_receive == callback
    end

    test "accepts on_match patterns" do
      patterns = [{:ping, :pong}, {:hello, :world}]
      def = Definition.new(:matcher, on_match: patterns)

      assert def.on_match == patterns
    end

    test "defaults on_match to empty list" do
      def = Definition.new(:simple, [])

      assert def.on_match == []
    end

    test "creates complete definition with all options" do
      callback = fn _msg, state -> state end

      def =
        Definition.new(:complex,
          send_pattern: {:rate, 10, :msg},
          targets: [:target1],
          on_receive: callback,
          on_match: [{:req, :resp}],
          initial_state: %{data: []}
        )

      assert def.name == :complex
      assert def.send_pattern == {:rate, 10, :msg}
      assert def.targets == [:target1]
      assert def.on_receive == callback
      assert def.on_match == [{:req, :resp}]
      assert def.initial_state == %{data: []}
    end
  end

  describe "Definition.match_message/2" do
    test "matches exact message patterns" do
      def =
        Definition.new(:matcher,
          on_match: [
            {:ping, :pong},
            {:hello, :world}
          ]
        )

      assert Definition.match_message(def, :ping) == {:matched, :pong}
      assert Definition.match_message(def, :hello) == {:matched, :world}
    end

    test "returns nil when no match found" do
      def = Definition.new(:matcher, on_match: [{:ping, :pong}])

      assert Definition.match_message(def, :unknown) == nil
    end

    test "matches using predicate functions" do
      def =
        Definition.new(:conditional,
          on_match: [
            {fn msg -> is_integer(msg) and msg > 10 end, :big_number},
            {fn msg -> is_integer(msg) end, :number}
          ]
        )

      assert Definition.match_message(def, 15) == {:matched, :big_number}
      assert Definition.match_message(def, 5) == {:matched, :number}
      assert Definition.match_message(def, "string") == nil
    end

    test "returns first matching pattern" do
      def =
        Definition.new(:first_match,
          on_match: [
            {fn _msg -> true end, :first},
            {fn _msg -> true end, :second}
          ]
        )

      assert Definition.match_message(def, :anything) == {:matched, :first}
    end

    test "handles complex message patterns" do
      def =
        Definition.new(:complex,
          on_match: [
            {{:request, :data}, {:response, :ok}},
            {{:request, :error}, {:response, :fail}}
          ]
        )

      assert Definition.match_message(def, {:request, :data}) == {:matched, {:response, :ok}}
      assert Definition.match_message(def, {:request, :error}) == {:matched, {:response, :fail}}
    end

    test "handles empty on_match list" do
      def = Definition.new(:empty, on_match: [])

      assert Definition.match_message(def, :anything) == nil
    end

    test "predicate function has access to full message" do
      def =
        Definition.new(:inspector,
          on_match: [
            {fn {:command, value} -> value > 100 end, :high},
            {fn {:command, _} -> true end, :low}
          ]
        )

      assert Definition.match_message(def, {:command, 200}) == {:matched, :high}
      assert Definition.match_message(def, {:command, 50}) == {:matched, :low}
    end
  end

  describe "Definition.interval_for_pattern/1" do
    test "extracts interval from periodic pattern" do
      assert Definition.interval_for_pattern({:periodic, 100, :tick}) == 100
      assert Definition.interval_for_pattern({:periodic, 1000, :msg}) == 1000
    end

    test "calculates interval from rate pattern" do
      assert Definition.interval_for_pattern({:rate, 10, :msg}) == 100
      assert Definition.interval_for_pattern({:rate, 5, :msg}) == 200
      assert Definition.interval_for_pattern({:rate, 1, :msg}) == 1000
    end

    test "extracts interval from burst pattern" do
      assert Definition.interval_for_pattern({:burst, 5, 500, :msg}) == 500
      assert Definition.interval_for_pattern({:burst, 10, 1000, :batch}) == 1000
    end

    test "extracts delay from self_message pattern" do
      assert Definition.interval_for_pattern({:self_message, 200, :timeout}) == 200
      assert Definition.interval_for_pattern({:self_message, 5000, :check}) == 5000
    end

    test "returns nil for nil pattern" do
      assert Definition.interval_for_pattern(nil) == nil
    end
  end

  describe "Definition.messages_for_pattern/1" do
    test "returns single message for periodic pattern" do
      assert Definition.messages_for_pattern({:periodic, 100, :tick}) == [:tick]
    end

    test "returns single message for rate pattern" do
      assert Definition.messages_for_pattern({:rate, 10, :msg}) == [:msg]
    end

    test "returns duplicated messages for burst pattern" do
      assert Definition.messages_for_pattern({:burst, 3, 500, :event}) == [:event, :event, :event]
      assert Definition.messages_for_pattern({:burst, 5, 100, :x}) == [:x, :x, :x, :x, :x]
    end

    test "returns single message for self_message pattern" do
      assert Definition.messages_for_pattern({:self_message, 200, :timeout}) == [:timeout]
    end

    test "returns empty list for nil pattern" do
      assert Definition.messages_for_pattern(nil) == []
    end

    test "handles burst with zero count" do
      assert Definition.messages_for_pattern({:burst, 0, 100, :msg}) == []
    end

    test "handles burst with large count" do
      messages = Definition.messages_for_pattern({:burst, 1000, 100, :spam})
      assert length(messages) == 1000
      assert Enum.all?(messages, &(&1 == :spam))
    end

    test "preserves complex message types" do
      assert Definition.messages_for_pattern({:periodic, 100, {:complex, :msg}}) == [
               {:complex, :msg}
             ]

      assert Definition.messages_for_pattern({:burst, 2, 100, %{key: :value}}) == [
               %{key: :value},
               %{key: :value}
             ]
    end
  end

  describe "Definition pattern integration" do
    test "periodic pattern provides consistent interval and messages" do
      pattern = {:periodic, 100, :tick}

      assert Definition.interval_for_pattern(pattern) == 100
      assert Definition.messages_for_pattern(pattern) == [:tick]
    end

    test "rate pattern converts frequency to interval" do
      # 10 per second
      pattern = {:rate, 10, :event}

      interval = Definition.interval_for_pattern(pattern)
      messages = Definition.messages_for_pattern(pattern)

      # 1000ms / 10 = 100ms
      assert interval == 100
      assert messages == [:event]
    end

    test "burst pattern sends multiple messages at once" do
      pattern = {:burst, 5, 1000, :batch}

      interval = Definition.interval_for_pattern(pattern)
      messages = Definition.messages_for_pattern(pattern)

      assert interval == 1000
      assert length(messages) == 5
    end

    test "self_message pattern for internal timeouts" do
      pattern = {:self_message, 5000, :heartbeat}

      assert Definition.interval_for_pattern(pattern) == 5000
      assert Definition.messages_for_pattern(pattern) == [:heartbeat]
    end
  end

  describe "Definition documentation examples" do
    doctest Definition, only: [interval_for_pattern: 1, messages_for_pattern: 1]
  end
end
