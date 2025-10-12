defmodule TerminationIndicatorTest do
  use ExUnit.Case, async: false

  @moduletag :diagram_generation

  # Use fixed seed for deterministic diagram generation
  setup_all do
    :rand.seed(:exsss, {300, 301, 302})
    :ok
  end

  describe "Termination indicators in diagrams" do
    test "Mermaid diagram shows termination note when condition met" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(
          max_duration: 10_000,
          terminate_when: fn sim ->
            stats = ActorSimulation.collect_current_stats(sim)
            stats.actors[:producer].sent_count >= 5
          end
        )

      # Generate diagram
      mermaid =
        ActorSimulation.trace_to_mermaid(simulation,
          enhanced: true,
          show_termination: true
        )

      # Should have termination indicator
      assert simulation.terminated_early == true
      assert simulation.actual_duration < 10_000
      assert String.contains?(mermaid, "⚡ Terminated")
      assert String.contains?(mermaid, "goal achieved")
      assert String.contains?(mermaid, "#{simulation.actual_duration}ms")

      ActorSimulation.stop(simulation)
    end

    test "no termination note when running full duration" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 500)

      mermaid = ActorSimulation.trace_to_mermaid(simulation)

      # Should NOT have termination indicator
      assert Map.get(simulation, :terminated_early, false) == false
      refute String.contains?(mermaid, "⚡ Terminated")

      ActorSimulation.stop(simulation)
    end

    test "can disable termination indicator" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(
          max_duration: 10_000,
          terminate_when: fn sim ->
            stats = ActorSimulation.collect_current_stats(sim)
            stats.actors[:producer].sent_count >= 3
          end
        )

      # Generate without termination note
      mermaid = ActorSimulation.trace_to_mermaid(simulation, show_termination: false)

      refute String.contains?(mermaid, "⚡ Terminated")

      ActorSimulation.stop(simulation)
    end

    test "dining philosophers shows when all fed" do
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 3,
          think_time: 500,
          eat_time: 100,
          trace: true
        )
        |> ActorSimulation.run(
          max_duration: 10_000,
          terminate_when: fn sim ->
            stats = ActorSimulation.collect_current_stats(sim)

            # Debug: print sent counts
            sent_counts =
              Enum.map(0..2, fn i ->
                name = :"philosopher_#{i}"
                count = stats.actors[name][:sent_count] || 0
                {name, count}
              end)

            # Check if all 3 philosophers have mumbled "I'm full!" 
            # Message flow for one complete eating cycle:
            # 1. {:start_hungry...} first time: [mumble hungry, request first fork] = 2
            # 2. {:fork_granted, first_fork}: [request second fork] = 1
            # 3. {:fork_granted, second_fork}: [mumble full, release first, release second] = 3
            # Total = 6 messages for first complete eating cycle
            all_fed =
              Enum.all?(0..2, fn i ->
                name = :"philosopher_#{i}"

                case stats.actors[name] do
                  nil ->
                    false

                  actor_stats ->
                    # sent_count >= 6 means they've completed first meal with "I'm full!" said
                    actor_stats.sent_count >= 6
                end
              end)

            if all_fed do
              IO.puts("\n🎉 All fed! Sent counts: #{inspect(sent_counts)}")
            end

            all_fed
          end
        )

      mermaid =
        ActorSimulation.trace_to_mermaid(simulation,
          enhanced: true,
          timestamps: true,
          show_termination: true
        )

      # Should show termination
      assert simulation.terminated_early == true
      assert String.contains?(mermaid, "⚡ Terminated")
      assert String.contains?(mermaid, "#{simulation.actual_duration}ms")

      # Save to file for visual verification
      File.mkdir_p!("generated/examples")

      html = """
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Dining Philosophers - Condition Terminated</title>
        <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
        <style>
          body { font-family: system-ui; max-width: 1400px; margin: 40px auto; padding: 20px; }
          .mermaid { background: white; padding: 40px; border-radius: 8px; }
          .info { background: #d1fae5; padding: 20px; border-left: 4px solid #10b981; margin-bottom: 20px; border-radius: 4px; }
        </style>
      </head>
      <body>
        <h1>🍴 3 Philosophers - Condition-Based Termination</h1>
        <div class="info">
          <strong>✅ Custom Termination Condition Met!</strong><br>
          Simulation stopped at <strong>#{simulation.actual_duration}ms</strong> when all philosophers had eaten at least once.<br>
          Look for the <strong>⚡ Terminated</strong> note at the bottom of the diagram!
        </div>
        <div class="mermaid">
      #{mermaid}
        </div>
        <script>
          mermaid.initialize({ startOnLoad: true, theme: 'default',
            sequence: { mirrorActors: true, messageMargin: 35 }
          });
        </script>
      </body>
      </html>
      """

      File.write!("generated/examples/dining_philosophers_condition_terminated.html", html)

      IO.puts(
        "\n✅ Generated condition-terminated diagram: generated/examples/dining_philosophers_condition_terminated.html"
      )

      IO.puts("   Look for the ⚡ Terminated note showing when the goal was achieved!")

      ActorSimulation.stop(simulation)
    end
  end
end
