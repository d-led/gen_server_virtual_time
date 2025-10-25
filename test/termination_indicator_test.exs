defmodule TerminationIndicatorTest do
  use ExUnit.Case, async: true

  @moduletag :diagram_generation
  @moduletag timeout: :infinity

  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
  # credo:disable-for-this-file Credo.Check.Refactor.Nesting

  # Use fixed seed for deterministic diagram generation
  setup_all do
    :rand.seed(:exsss, {300, 301, 302})
    :ok
  end

  # Helper for simple fork behavior (reduces complexity)
  defp simple_fork_behavior(fork_name) do
    fn msg, state ->
      case msg do
        {:request_fork, phil} ->
          if state.held_by == nil do
            {:send, [{phil, {:fork_granted, fork_name}}], %{state | held_by: phil}}
          else
            {:send, [{phil, {:fork_denied, fork_name}}], state}
          end

        {:release_fork, phil} ->
          if state.held_by == phil do
            {:ok, %{state | held_by: nil}}
          else
            {:ok, state}
          end

        _ ->
          {:ok, state}
      end
    end
  end

  # Helper to create finite dining philosophers that reach quiescence
  defp create_finite_philosophers(num_philosophers, opts) do
    max_meals = Keyword.get(opts, :max_meals, 2)
    think_time = Keyword.get(opts, :think_time, 100)
    eat_time = Keyword.get(opts, :eat_time, 50)

    simulation = ActorSimulation.new(trace: true)

    # Create forks (same as regular dining philosophers)
    simulation =
      Enum.reduce(0..(num_philosophers - 1), simulation, fn i, sim ->
        fork_name = :"fork_#{i}"

        ActorSimulation.add_actor(sim, fork_name,
          on_receive: simple_fork_behavior(fork_name),
          initial_state: %{held_by: nil}
        )
      end)

    # Create finite philosophers (no periodic pattern!)
    Enum.reduce(0..(num_philosophers - 1), simulation, fn i, sim ->
      philosopher_name = :"philosopher_#{i}"
      first_fork = :"fork_#{i}"
      second_fork = :"fork_#{rem(i + 1, num_philosophers)}"

      # Asymmetric fork ordering to prevent deadlock
      {first_fork, second_fork} =
        if rem(i, 2) == 0 do
          {first_fork, second_fork}
        else
          {second_fork, first_fork}
        end

      # Finite philosopher behavior
      philosopher_behavior = fn msg, state ->
        meals_eaten = Map.get(state, :meals_eaten, 0)

        case msg do
          :start_eating ->
            # Only get hungry if haven't reached max meals
            if meals_eaten < max_meals do
              {:send_after, think_time,
               [{philosopher_name, {:get_hungry, first_fork, second_fork}}], state}
            else
              # Finished eating quota - no more messages (enables quiescence!)
              {:ok, state}
            end

          {:get_hungry, ^first_fork, ^second_fork} ->
            # Try to get first fork
            {:send, [{first_fork, {:request_fork, philosopher_name}}], state}

          {:fork_granted, fork} ->
            cond do
              fork == first_fork && !Map.get(state, :first_fork_held, false) ->
                # Got first fork, try for second
                {:send, [{second_fork, {:request_fork, philosopher_name}}],
                 Map.put(state, :first_fork_held, true)}

              fork == second_fork && Map.get(state, :first_fork_held, false) ->
                # Got both forks! Eat and then release
                new_meals = meals_eaten + 1

                {:send_after, eat_time,
                 [
                   {philosopher_name, {:mumble, "I'm full! (meal #{new_meals}/#{max_meals})"}},
                   {first_fork, {:release_fork, philosopher_name}},
                   {second_fork, {:release_fork, philosopher_name}},
                   {philosopher_name, :start_eating}
                 ],
                 %{
                   state
                   | first_fork_held: false,
                     second_fork_held: false,
                     meals_eaten: new_meals
                 }}

              true ->
                {:ok, state}
            end

          {:fork_denied, _fork} ->
            # Release any held forks and try again later
            releases =
              if Map.get(state, :first_fork_held, false) do
                [{first_fork, {:release_fork, philosopher_name}}]
              else
                []
              end

            {:send_after, think_time,
             releases ++ [{philosopher_name, {:get_hungry, first_fork, second_fork}}],
             Map.put(state, :first_fork_held, false)}

          {:mumble, _message} ->
            {:ok, state}

          _ ->
            {:ok, state}
        end
      end

      ActorSimulation.add_actor(sim, philosopher_name,
        # Start the first meal cycle with a single message (not periodic!)
        send_pattern: {:self_message, think_time, :start_eating},
        targets: [philosopher_name],
        on_receive: philosopher_behavior,
        initial_state: %{
          name: philosopher_name,
          first_fork: first_fork,
          second_fork: second_fork,
          meals_eaten: 0,
          first_fork_held: false,
          second_fork_held: false
        }
      )
    end)
  end

  # Helper to generate Mermaid HTML
  defp generate_mermaid_html(mermaid, title, opts \\ []) do
    model_source = Keyword.get(opts, :model_source, "")
    description = Keyword.get(opts, :description, "")

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{title}</title>
      <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
    </head>
    <body>
      <h1>#{title}</h1>
      <p>#{description}</p>

      <h2>🎯 Key Features Demonstrated</h2>
      <ul>
        <li><strong>Virtual Time:</strong> Simulation runs much faster than real time</li>
        <li><strong>Quiescence Detection:</strong> System stops naturally when no more events are scheduled</li>
        <li><strong>Actor Coordination:</strong> Complex multi-actor interaction patterns</li>
      </ul>

      <h2>📊 Sequence Diagram</h2>
      <div class="mermaid">
        #{mermaid}
      </div>

      <h2>💻 Source Code</h2>
      <pre><code>#{model_source}</code></pre>

      <script>
        mermaid.initialize({startOnLoad: true});
      </script>
    </body>
    </html>
    """
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

    test "3 dining philosophers - quiescence demonstration" do
      # Create FINITE philosophers that stop after eating twice (demonstrate quiescence)
      simulation =
        create_finite_philosophers(3, max_meals: 2, think_time: 100, eat_time: 50)
        |> ActorSimulation.run(
          # Long max_duration but expecting quiescence much earlier
          max_duration: 30_000,
          # KEY: Use :quiescence to detect when system naturally stops
          terminate_when: :quiescence
        )

      # Should terminate due to quiescence, not timeout
      assert simulation.termination_reason == :quiescence
      assert simulation.terminated_early == true
      assert simulation.actual_duration < 30_000

      # Generate diagram showing quiescence termination
      mermaid =
        ActorSimulation.trace_to_mermaid(simulation,
          enhanced: true,
          show_termination: true
        )

      # Should show quiescence termination
      assert String.contains?(mermaid, "⚡ Terminated")

      model_source = """
      # FINITE philosophers (each eats only 2 meals, then stops)
      simulation = create_finite_philosophers(3, max_meals: 2, think_time: 100, eat_time: 50)
        |> ActorSimulation.run(
          max_duration: 30_000,
          terminate_when: :quiescence  # Wait for natural end!
        )

      # Result: termination_reason == :quiescence
      #   (system naturally stops when no more events are scheduled)
      """

      html =
        generate_mermaid_html(mermaid, "🍴 3 Dining Philosophers - Quiescence Detection",
          model_source: model_source,
          description:
            "Demonstrates quiescence detection: simulation stops naturally when no more events are scheduled"
        )

      File.write!("generated/examples/dining_philosophers_quiescence.html", html)

      IO.puts(
        "\n✅ Generated quiescence demonstration: generated/examples/dining_philosophers_quiescence.html"
      )

      IO.puts("   🎯 KEY POINT: Simulation terminated due to QUIESCENCE")
      IO.puts("   Virtual time: #{simulation.actual_duration}ms (stopped naturally)")
      IO.puts("   Max time: 30,000ms (but didn't need it!)")
      IO.puts("   Termination: #{simulation.termination_reason}")
      IO.puts("   This shows virtual time can detect when systems reach natural stable states!")

      ActorSimulation.stop(simulation)
    end
  end
end
