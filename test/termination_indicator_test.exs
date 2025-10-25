defmodule TerminationIndicatorTest do
  use ExUnit.Case, async: true

  @moduletag :diagram_generation
  @moduletag timeout: :infinity

  # Use fixed seed for deterministic diagram generation
  setup_all do
    :rand.seed(:exsss, {300, 301, 302})
    :ok
  end

  describe "Termination indicators in diagrams" do
    @describetag :serial
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
          num_philosophers: 2,
          think_time: 150,
          eat_time: 75,
          trace: true
        )
        |> ActorSimulation.run(duration: 1000)

      # Verify all 2 philosophers ate (said "I'm full!")
      trace = simulation.trace

      philosophers_who_ate =
        Enum.filter(0..1, fn i ->
          name = :"philosopher_#{i}"

          Enum.any?(trace, fn event ->
            event.from == name and event.to == name and
              event.message == {:mumble, "I'm full!"}
          end)
        end)

      assert length(philosophers_who_ate) == 2,
             "Expected all 2 philosophers to eat, but only #{inspect(philosophers_who_ate)} ate"

      mermaid =
        ActorSimulation.trace_to_mermaid(simulation,
          enhanced: true,
          timestamps: true,
          show_termination: false
        )

      # Save to file for visual verification
      File.mkdir_p!("generated/examples")

      # Add generator metadata
      metadata = ActorSimulation.GeneratorMetadata.from_stacktrace()
      generator_comment = ActorSimulation.GeneratorMetadata.to_html_comment(metadata)

      html = """
      <!DOCTYPE html>
      <html>
      #{generator_comment}<head>
        <meta charset="utf-8">
        <title>Dining Philosophers - Condition Terminated</title>
        <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
        <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css" rel="stylesheet" />
        <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-core.min.js"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-elixir.min.js"></script>
        <style>
          body { font-family: system-ui; max-width: 1400px; margin: 40px auto; padding: 20px; }
          .mermaid { background: white; padding: 40px; border-radius: 8px; }
          .info { background: #d1fae5; padding: 20px; border-left: 4px solid #10b981; margin-bottom: 20px; border-radius: 4px; }
        </style>
      </head>
      <body>
        <h1>🍴 2 Philosophers - Both Fed Successfully</h1>
        <div class="info">
          <strong>✅ Success!</strong><br>
          Both philosophers successfully ate at least once during the simulation.<br>
          Look for each philosopher's <strong>"I'm full!"</strong> message in the diagram below!
        </div>
        <div style="background: #fff3e0; padding: 20px; border-left: 4px solid #ff9800; margin-bottom: 20px; border-radius: 4px;">
          <h3 style="margin-top: 0; color: #e65100;">Simulation Source Code</h3>
          <pre><code class="language-elixir">simulation =
      DiningPhilosophers.create_simulation(
      num_philosophers: 2,
      think_time: 150,
      eat_time: 75,
      trace: true
      )
      |> ActorSimulation.run(duration: 1000)</code></pre>
        </div>
        <div class="mermaid">
      #{mermaid}
        </div>
        <div style="margin-top: 30px; padding: 20px; background: #f8f9fa; border-radius: 8px; border: 1px solid #e9ecef;">
          <h3 style="margin: 0 0 15px 0; color: #2c3e50; font-size: 1.1em;">🔗 Source & Links</h3>
          <a href="https://github.com/d-led/gen_server_virtual_time" target="_blank" style="display: inline-block; margin: 5px 10px 5px 0; padding: 8px 16px; background: #24292e; color: white; text-decoration: none; border-radius: 4px; font-size: 14px; transition: background 0.2s;">📚 GitHub Repository</a>
          <a href="https://github.com/d-led/gen_server_virtual_time/blob/main/test/termination_indicator_test.exs" target="_blank" style="display: inline-block; margin: 5px 10px 5px 0; padding: 8px 16px; background: #24292e; color: white; text-decoration: none; border-radius: 4px; font-size: 14px; transition: background 0.2s;">🧪 Test Source</a>
          <a href="https://hexdocs.pm/gen_server_virtual_time" target="_blank" style="display: inline-block; margin: 5px 10px 5px 0; padding: 8px 16px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; font-size: 14px; transition: background 0.2s;">📖 Documentation</a>
          <a href="https://hex.pm/packages/gen_server_virtual_time" target="_blank" style="display: inline-block; margin: 5px 10px 5px 0; padding: 8px 16px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; font-size: 14px; transition: background 0.2s;">📦 Hex Package</a>
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

    test "5 dining philosophers - all fed successfully" do
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 5,
          think_time: 50,
          eat_time: 25,
          trace: true
        )
        |> ActorSimulation.run(
          max_duration: 120_000,
          terminate_when: fn sim ->
            # Check if all philosophers have eaten by looking for "I'm full!" messages
            trace = sim.trace

            philosophers_who_ate =
              Enum.filter(0..4, fn i ->
                name = :"philosopher_#{i}"

                Enum.any?(trace, fn event ->
                  event.from == name and event.to == name and
                    event.message == {:mumble, "I'm full!"}
                end)
              end)

            length(philosophers_who_ate) == 5
          end
        )

      # Verify all 5 philosophers ate (said "I'm full!")
      trace = simulation.trace

      philosophers_who_ate =
        Enum.filter(0..4, fn i ->
          name = :"philosopher_#{i}"

          Enum.any?(trace, fn event ->
            event.from == name and event.to == name and
              event.message == {:mumble, "I'm full!"}
          end)
        end)

      assert length(philosophers_who_ate) == 5,
             "Expected all 5 philosophers to eat, but only #{inspect(philosophers_who_ate)} ate"

      # Generate flowchart report instead of sequence diagram (too large for Mermaid)
      File.mkdir_p!("generated/examples/reports")

      model_source = """
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 5,
          think_time: 50,
          eat_time: 25,
          trace: true
        )
        |> ActorSimulation.run(
          max_duration: 120_000,
          terminate_when: fn sim ->
            # Check if all philosophers have eaten
            trace = sim.trace
            philosophers_who_ate =
              Enum.filter(0..4, fn i ->
                name = :"philosopher_\#{i}"
                Enum.any?(trace, fn event ->
                  event.from == name and event.to == name and
                    event.message == {:mumble, "I'm full!"}
                end)
              end)
            length(philosophers_who_ate) == 5
          end
        )
      """

      html =
        ActorSimulation.generate_flowchart_report(simulation,
          title: "🍴 5 Dining Philosophers - All Fed Successfully",
          layout: "TB",
          show_stats_on_nodes: true,
          model_source: model_source
        )

      File.write!("generated/examples/reports/dining_philosophers_5_all_fed.html", html)

      IO.puts(
        "\n✅ Generated 5-philosopher flowchart report: generated/examples/reports/dining_philosophers_5_all_fed.html"
      )

      IO.puts("   All 5 philosophers successfully ate - check the flowchart report!")

      ActorSimulation.stop(simulation)
    end

    test "5 dining philosophers with 10ms thinking delays - dramatic speedup" do
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 5,
          # 10ms thinking time for faster convergence
          think_time: 10,
          # 10ms eating time
          eat_time: 10,
          trace: true
        )
        |> ActorSimulation.run(
          # Longer cap to ensure all philosophers eat despite fast timing
          max_duration: 120_000,
          terminate_when: fn sim ->
            # Check if all philosophers have eaten by looking for "I'm full!" messages
            trace = sim.trace

            philosophers_who_ate =
              Enum.filter(0..4, fn i ->
                name = :"philosopher_#{i}"

                Enum.any?(trace, fn event ->
                  event.from == name and event.to == name and
                    event.message == {:mumble, "I'm full!"}
                end)
              end)

            length(philosophers_who_ate) == 5
          end,
          # Check frequently to terminate as soon as goal is reached
          check_interval: 100
        )

      # Verify all 5 philosophers ate (said "I'm full!")
      trace = simulation.trace

      philosophers_who_ate =
        Enum.filter(0..4, fn i ->
          name = :"philosopher_#{i}"

          Enum.any?(trace, fn event ->
            event.from == name and event.to == name and
              event.message == {:mumble, "I'm full!"}
          end)
        end)

      assert length(philosophers_who_ate) == 5,
             "Expected all 5 philosophers to eat, but only #{inspect(philosophers_who_ate)} ate"

      # Generate flowchart report
      File.mkdir_p!("generated/examples/reports")

      model_source = """
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 5,
          think_time: 10,
          eat_time: 10,
          trace: true
        )
        |> ActorSimulation.run(
          max_duration: 120_000,
          terminate_when: fn sim ->
            trace = sim.trace
            philosophers_who_ate =
              Enum.filter(0..4, fn i ->
                name = :"philosopher_\#{i}"
                Enum.any?(trace, fn event ->
                  event.from == name and event.to == name and
                    event.message == {:mumble, "I'm full!"}
                end)
              end)
            length(philosophers_who_ate) == 5
          end,
          check_interval: 100
        )
      """

      html =
        ActorSimulation.generate_flowchart_report(simulation,
          title: "🍴 5 Dining Philosophers - 10ms Thinking (Speedup)",
          layout: "TB",
          show_stats_on_nodes: true,
          model_source: model_source
        )

      File.write!("generated/examples/reports/dining_philosophers_10ms_thinking.html", html)

      # Calculate speedup
      real_time = simulation.real_time_elapsed
      virtual_time = simulation.actual_duration
      speedup = Float.round(virtual_time / real_time, 1)

      IO.puts("\n🚀 SPEEDUP with 10ms thinking delays!")
      IO.puts("   Virtual time: #{virtual_time}ms (#{Float.round(virtual_time / 1000, 1)}s)")
      IO.puts("   Real time: #{real_time}ms")
      IO.puts("   Speedup: #{speedup}x")
      IO.puts("   All 5 philosophers successfully ate - check the flowchart report!")
      IO.puts("   Report: generated/examples/reports/dining_philosophers_10ms_thinking.html")

      ActorSimulation.stop(simulation)
    end
  end
end
