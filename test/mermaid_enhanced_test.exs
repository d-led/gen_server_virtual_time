defmodule MermaidEnhancedTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Tests for enhanced Mermaid diagram features based on
  https://docs.mermaidchart.com/mermaid-oss/syntax/sequenceDiagram.html
  """

  describe "Mermaid enhanced features" do
    test "uses solid arrows for synchronous calls" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:client,
          send_pattern: {:periodic, 100, {:call, :get}},
          targets: [:server]
        )
        |> ActorSimulation.add_actor(:server,
          on_match: [
            {:get, fn state -> {:reply, :ok, state} end}
          ]
        )
        |> ActorSimulation.run(duration: 200)

      mermaid = ActorSimulation.trace_to_mermaid(simulation)

      # Should use solid arrows for calls
      assert String.contains?(mermaid, "client->>server")
      assert String.contains?(mermaid, "activate server")
      assert String.contains?(mermaid, "deactivate server")

      ActorSimulation.stop(simulation)
    end

    test "uses dotted arrows for asynchronous casts" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, {:cast, :notify}},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 200)

      mermaid = ActorSimulation.trace_to_mermaid(simulation)

      # Should use dotted arrows for casts
      assert String.contains?(mermaid, "sender-->>receiver")

      ActorSimulation.stop(simulation)
    end

    test "includes timestamp notes when enabled" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 300)

      # Generate with timestamps
      mermaid = ActorSimulation.trace_to_mermaid(simulation, timestamps: true)

      # Should include timestamp notes
      assert String.contains?(mermaid, "Note over sender,receiver: t=")
      assert String.contains?(mermaid, "100ms") or String.contains?(mermaid, "200ms")

      ActorSimulation.stop(simulation)
    end

    test "simple mode without enhancements" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:a,
          send_pattern: {:periodic, 100, {:call, :msg}},
          targets: [:b]
        )
        |> ActorSimulation.add_actor(:b,
          on_match: [
            {:msg, fn state -> {:reply, :ok, state} end}
          ]
        )
        |> ActorSimulation.run(duration: 100)

      # Generate simple version
      mermaid = ActorSimulation.trace_to_mermaid(simulation, enhanced: false)

      # Should NOT include activation
      refute String.contains?(mermaid, "activate")
      refute String.contains?(mermaid, "deactivate")

      # But should still have basic diagram
      assert String.contains?(mermaid, "sequenceDiagram")
      assert String.contains?(mermaid, "a->>b")

      ActorSimulation.stop(simulation)
    end

    test "combines all enhanced features" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:api,
          send_pattern: {:periodic, 100, {:call, :request}},
          targets: [:service]
        )
        |> ActorSimulation.add_actor(:service,
          on_match: [
            {:request,
             fn state ->
               {:send, [{:api, :response}, {:logger, {:cast, :log}}], state}
             end}
          ]
        )
        |> ActorSimulation.add_actor(:logger)
        |> ActorSimulation.run(duration: 200)

      # Enhanced with timestamps
      mermaid =
        ActorSimulation.trace_to_mermaid(simulation,
          enhanced: true,
          timestamps: true
        )

      # Should have all features
      # Solid arrows
      assert String.contains?(mermaid, "->>")
      # Dotted arrows
      assert String.contains?(mermaid, "-->>")
      # Activation
      assert String.contains?(mermaid, "activate")
      # Timestamp notes
      assert String.contains?(mermaid, "Note over")

      ActorSimulation.stop(simulation)
    end
  end

  describe "Arrow types match Mermaid spec" do
    test "call uses solid arrow with activation" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:caller,
          send_pattern: {:periodic, 100, {:call, :sync}},
          targets: [:callee]
        )
        |> ActorSimulation.add_actor(:callee,
          on_match: [{:sync, fn s -> {:reply, :ok, s} end}]
        )
        |> ActorSimulation.run(duration: 100)

      mermaid = ActorSimulation.trace_to_mermaid(simulation)
      lines = String.split(mermaid, "\n")

      # Should have activation, then arrow, then deactivation
      assert Enum.any?(lines, &String.contains?(&1, "activate callee"))
      assert Enum.any?(lines, &String.contains?(&1, "caller->>callee"))
      assert Enum.any?(lines, &String.contains?(&1, "deactivate callee"))

      ActorSimulation.stop(simulation)
    end

    test "cast uses dotted arrow without activation" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:caster,
          send_pattern: {:periodic, 100, {:cast, :async}},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 100)

      mermaid = ActorSimulation.trace_to_mermaid(simulation)
      lines = String.split(mermaid, "\n")

      # Should have dotted arrow
      assert Enum.any?(lines, &String.contains?(&1, "caster-->>receiver"))

      # Should NOT have activation for casts
      refute Enum.any?(lines, &String.contains?(&1, "activate"))

      ActorSimulation.stop(simulation)
    end
  end
end
