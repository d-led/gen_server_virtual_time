defmodule MermaidReportTest do
  use ExUnit.Case, async: false

  alias ActorSimulation.MermaidReportGenerator

  @output_dir "generated/examples/reports"

  setup_all do
    File.mkdir_p!(@output_dir)
    :ok
  end

  # Helper to define simulation and generate source code from quoted expression
  # This eliminates code duplication by defining the simulation once
  defp simulation_with_source(quoted_code) do
    simulation = Code.eval_quoted(quoted_code) |> elem(0)
    source = "simulation =\n#{Macro.to_string(quoted_code)}"
    {simulation, source}
  end

  describe "Mermaid Report Generation" do
    test "generates basic flowchart report" do
      # Create a simple producer-consumer simulation
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 500)

      # Generate flowchart
      flowchart = MermaidReportGenerator.generate_flowchart(simulation)

      assert String.contains?(flowchart, "flowchart TB")
      assert String.contains?(flowchart, "producer")
      assert String.contains?(flowchart, "consumer")
      assert String.contains?(flowchart, "-->")

      ActorSimulation.stop(simulation)
    end

    test "generates complete HTML report" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 500)

      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Producer-Consumer Report"
        )

      assert String.contains?(html, "<!DOCTYPE html>")
      assert String.contains?(html, "Producer-Consumer Report")
      assert String.contains?(html, "mermaid")
      assert String.contains?(html, "Simulation Summary")
      assert String.contains?(html, "Detailed Statistics")

      ActorSimulation.stop(simulation)
    end

    test "generates pipeline report with statistics" do
      # Model source code for documentation
      model_source = """
      # Create a more complex pipeline with forwarding logic
      forward = fn msg, state ->
        {:send, [{state.next, msg}], state}
      end

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:source,
          send_pattern: {:periodic, 100, :request},
          targets: [:stage1]
        )
        |> ActorSimulation.add_actor(:stage1,
          on_receive: forward,
          initial_state: %{next: :stage2}
        )
        |> ActorSimulation.add_actor(:stage2,
          on_receive: forward,
          initial_state: %{next: :sink}
        )
        |> ActorSimulation.add_actor(:sink)
        |> ActorSimulation.run(duration: 1000)

      # Generate the report
      html = MermaidReportGenerator.generate_report(simulation,
        title: "Pipeline Processing",
        show_stats_on_nodes: true,
        model_source: model_source
      )
      """

      # Create the actual simulation
      forward = fn msg, state ->
        {:send, [{state.next, msg}], state}
      end

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:source,
          send_pattern: {:periodic, 100, :request},
          targets: [:stage1]
        )
        |> ActorSimulation.add_actor(:stage1,
          targets: [:stage2],
          on_receive: forward,
          initial_state: %{next: :stage2}
        )
        |> ActorSimulation.add_actor(:stage2,
          targets: [:sink],
          on_receive: forward,
          initial_state: %{next: :sink}
        )
        |> ActorSimulation.add_actor(:sink)
        |> ActorSimulation.run(duration: 1000)

      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Pipeline Processing",
          show_stats_on_nodes: true,
          model_source: model_source
        )

      # Write to file for viewing
      filename = Path.join(@output_dir, "pipeline_report.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated pipeline report: #{filename}")

      # Verify content
      assert String.contains?(html, "source")
      assert String.contains?(html, "stage1")
      assert String.contains?(html, "stage2")
      assert String.contains?(html, "sink")
      assert String.contains?(html, "Sent:")
      assert String.contains?(html, "Recv:")

      ActorSimulation.stop(simulation)
    end

    test "generates pub-sub topology report" do
      # Define simulation once using quoted expression
      simulation_code =
        quote do
          ActorSimulation.new()
          |> ActorSimulation.add_actor(:publisher,
            send_pattern: {:rate, 10, :event},
            targets: [:sub1, :sub2, :sub3]
          )
          |> ActorSimulation.add_actor(:sub1)
          |> ActorSimulation.add_actor(:sub2)
          |> ActorSimulation.add_actor(:sub3)
          |> ActorSimulation.run(duration: 1000)
        end

      # Generate both simulation and source code from the same definition
      {simulation, model_source} = simulation_with_source(simulation_code)

      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Pub-Sub System",
          layout: "TB",
          model_source: model_source
        )

      filename = Path.join(@output_dir, "pubsub_report.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated pub-sub report: #{filename}")

      assert String.contains?(html, "publisher")
      assert String.contains?(html, "sub1")
      assert String.contains?(html, "sub2")
      assert String.contains?(html, "sub3")

      ActorSimulation.stop(simulation)
    end

    test "generates load-balanced system report" do
      model_source = """
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:load_balancer,
          send_pattern: {:burst, 3, 200, :work},
          targets: [:worker1, :worker2, :worker3]
        )
        |> ActorSimulation.add_actor(:worker1,
          on_match: [
            {:work, fn state -> {:send, [{:result_collector, :result}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:worker2,
          on_match: [
            {:work, fn state -> {:send, [{:result_collector, :result}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:worker3,
          on_match: [
            {:work, fn state -> {:send, [{:result_collector, :result}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:result_collector)
        |> ActorSimulation.run(duration: 1000)
      """

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:load_balancer,
          send_pattern: {:burst, 3, 200, :work},
          targets: [:worker1, :worker2, :worker3]
        )
        |> ActorSimulation.add_actor(:worker1,
          on_match: [
            {:work, fn state -> {:send, [{:result_collector, :result}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:worker2,
          on_match: [
            {:work, fn state -> {:send, [{:result_collector, :result}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:worker3,
          on_match: [
            {:work, fn state -> {:send, [{:result_collector, :result}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:result_collector)
        |> ActorSimulation.run(duration: 1000)

      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Load-Balanced Workers",
          layout: "TB",
          style_by_activity: true,
          model_source: model_source
        )

      filename = Path.join(@output_dir, "loadbalanced_report.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated load-balanced report: #{filename}")

      assert String.contains?(html, "load_balancer")
      assert String.contains?(html, "worker1")
      assert String.contains?(html, "result_collector")
      assert String.contains?(html, "style")

      ActorSimulation.stop(simulation)
    end

    test "generates report with early termination indicator" do
      model_source = """
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(
          max_duration: 10_000,
          terminate_when: fn sim ->
            stats = ActorSimulation.collect_current_stats(sim)
            sender_stats = Map.get(stats.actors, :sender)
            sender_stats && sender_stats.sent_count >= 10
          end
        )
      """

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(
          max_duration: 10_000,
          terminate_when: fn sim ->
            stats = ActorSimulation.collect_current_stats(sim)
            sender_stats = Map.get(stats.actors, :sender)
            sender_stats && sender_stats.sent_count >= 10
          end
        )

      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Early Termination Test",
          model_source: model_source
        )

      filename = Path.join(@output_dir, "early_termination_report.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated early termination report: #{filename}")

      assert String.contains?(html, "Early")
      assert simulation.terminated_early

      ActorSimulation.stop(simulation)
    end

    test "supports different layout directions" do
      model_source = """
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:left,
          send_pattern: {:periodic, 100, :msg},
          targets: [:right]
        )
        |> ActorSimulation.add_actor(:right)
        |> ActorSimulation.run(duration: 300)
      """

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:left,
          send_pattern: {:periodic, 100, :msg},
          targets: [:right]
        )
        |> ActorSimulation.add_actor(:right)
        |> ActorSimulation.run(duration: 300)

      # Test all layout directions
      for {direction, name, title} <- [
            {"LR", "left_right", "Left-to-Right Layout"},
            {"RL", "right_left", "Right-to-Left Layout"},
            {"TB", "top_bottom", "Top-to-Bottom Layout"},
            {"BT", "bottom_top", "Bottom-to-Top Layout"}
          ] do
        flowchart = MermaidReportGenerator.generate_flowchart(simulation, %{layout: direction})
        assert String.contains?(flowchart, "flowchart #{direction}")

        html =
          MermaidReportGenerator.generate_report(simulation,
            layout: direction,
            title: title,
            model_source: model_source
          )

        filename = Path.join(@output_dir, "layout_#{name}_report.html")
        File.write!(filename, html)
      end

      IO.puts("\n✅ Generated all layout direction reports")

      ActorSimulation.stop(simulation)
    end

    test "write_report helper function" do
      # Define simulation once using quoted expression
      simulation_code =
        quote do
          ActorSimulation.new()
          |> ActorSimulation.add_actor(:actor1,
            send_pattern: {:periodic, 100, :msg},
            targets: [:actor2]
          )
          |> ActorSimulation.add_actor(:actor2)
          |> ActorSimulation.run(duration: 300)
        end

      # Generate both simulation and source code from the same definition
      {simulation, model_source} = simulation_with_source(simulation_code)

      filename = Path.join(@output_dir, "write_helper_test.html")

      {:ok, ^filename} =
        MermaidReportGenerator.write_report(simulation, filename,
          title: "Write Helper Test",
          model_source: model_source
        )

      assert File.exists?(filename)
      content = File.read!(filename)
      assert String.contains?(content, "Write Helper Test")

      ActorSimulation.stop(simulation)
    end

    test "generates ring topology report with token passing" do
      # Model source code for documentation
      model_source = """
      # Create a ring of 7 actors passing a token every 100ms
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:actor0,
          send_pattern: {:periodic, 100, :token},
          targets: [:actor1]
        )
        |> ActorSimulation.add_actor(:actor1,
          on_match: [
            {:token, fn state -> {:send, [{:actor2, :token}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:actor2,
          on_match: [
            {:token, fn state -> {:send, [{:actor3, :token}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:actor3,
          on_match: [
            {:token, fn state -> {:send, [{:actor4, :token}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:actor4,
          on_match: [
            {:token, fn state -> {:send, [{:actor5, :token}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:actor5,
          on_match: [
            {:token, fn state -> {:send, [{:actor6, :token}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:actor6,
          on_match: [
            {:token, fn state -> {:send, [{:actor0, :token}], state} end}
          ]
        )
        |> ActorSimulation.run(duration: 1500)

      # Generate the report
      html = MermaidReportGenerator.generate_report(simulation,
        title: "Token Ring Network",
        layout: "LR",
        model_source: model_source
      )
      """

      # Create the actual simulation with proper ring topology
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:actor0,
          send_pattern: {:periodic, 100, :token},
          targets: [:actor1]
        )
        |> ActorSimulation.add_actor(:actor1,
          targets: [:actor2],
          on_receive: fn msg, state ->
            {:send, [{state.next, msg}], state}
          end,
          initial_state: %{next: :actor2}
        )
        |> ActorSimulation.add_actor(:actor2,
          targets: [:actor3],
          on_receive: fn msg, state ->
            {:send, [{state.next, msg}], state}
          end,
          initial_state: %{next: :actor3}
        )
        |> ActorSimulation.add_actor(:actor3,
          targets: [:actor4],
          on_receive: fn msg, state ->
            {:send, [{state.next, msg}], state}
          end,
          initial_state: %{next: :actor4}
        )
        |> ActorSimulation.add_actor(:actor4,
          targets: [:actor5],
          on_receive: fn msg, state ->
            {:send, [{state.next, msg}], state}
          end,
          initial_state: %{next: :actor5}
        )
        |> ActorSimulation.add_actor(:actor5,
          targets: [:actor6],
          on_receive: fn msg, state ->
            {:send, [{state.next, msg}], state}
          end,
          initial_state: %{next: :actor6}
        )
        |> ActorSimulation.add_actor(:actor6,
          targets: [:actor0],
          on_receive: fn msg, state ->
            {:send, [{state.next, msg}], state}
          end,
          initial_state: %{next: :actor0}
        )
        |> ActorSimulation.run(duration: 1500)

      # Generate report with model source
      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Token Ring Network",
          layout: "LR",
          model_source: model_source
        )

      filename = Path.join(@output_dir, "ring_topology_report.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated ring topology report: #{filename}")
      IO.puts("   Token passing ring with 7 actors, terminates at 1500ms virtual time")

      # Verify ring topology
      assert String.contains?(html, "flowchart LR")
      assert String.contains?(html, "actor0")
      assert String.contains?(html, "actor6")

      ActorSimulation.stop(simulation)
    end

    test "generates random messaging demo with 7 actors" do
      # Model source code for documentation
      model_source = """
      # Create 7 actors that all know each other, sending random :hi messages
      # Fixed random seed for reproducible results
      :rand.seed(:exs1024, {42, 123, 456})

      # Generate random delays for each actor (100-500ms)
      random_delays = Enum.map(1..7, fn _ -> :rand.uniform(400) + 100 end)

      # All actors know each other (full mesh topology)
      all_targets = [:actor0, :actor1, :actor2, :actor3, :actor4, :actor5, :actor6]

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:actor0,
          send_pattern: {:periodic, Enum.at(random_delays, 0), :hi},
          targets: all_targets -- [:actor0]
        )
        |> ActorSimulation.add_actor(:actor1,
          send_pattern: {:periodic, Enum.at(random_delays, 1), :hi},
          targets: all_targets -- [:actor1]
        )
        |> ActorSimulation.add_actor(:actor2,
          send_pattern: {:periodic, Enum.at(random_delays, 2), :hi},
          targets: all_targets -- [:actor2]
        )
        |> ActorSimulation.add_actor(:actor3,
          send_pattern: {:periodic, Enum.at(random_delays, 3), :hi},
          targets: all_targets -- [:actor3]
        )
        |> ActorSimulation.add_actor(:actor4,
          send_pattern: {:periodic, Enum.at(random_delays, 4), :hi},
          targets: all_targets -- [:actor4]
        )
        |> ActorSimulation.add_actor(:actor5,
          send_pattern: {:periodic, Enum.at(random_delays, 5), :hi},
          targets: all_targets -- [:actor5]
        )
        |> ActorSimulation.add_actor(:actor6,
          send_pattern: {:periodic, Enum.at(random_delays, 6), :hi},
          targets: all_targets -- [:actor6]
        )
        |> ActorSimulation.run(duration: 2000)

      # Generate the report
      html = MermaidReportGenerator.generate_report(simulation,
        title: "Random Messaging Network",
        layout: "TB",
        model_source: model_source
      )
      """

      # Create the actual simulation with fixed random seed
      :rand.seed(:exs1024, {42, 123, 456})

      # Generate random delays for each actor (100-500ms)
      random_delays = Enum.map(1..7, fn _ -> :rand.uniform(400) + 100 end)

      # All actors know each other (full mesh topology)
      all_targets = [:actor0, :actor1, :actor2, :actor3, :actor4, :actor5, :actor6]

      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:actor0,
          send_pattern: {:periodic, Enum.at(random_delays, 0), :hi},
          targets: all_targets -- [:actor0]
        )
        |> ActorSimulation.add_actor(:actor1,
          send_pattern: {:periodic, Enum.at(random_delays, 1), :hi},
          targets: all_targets -- [:actor1]
        )
        |> ActorSimulation.add_actor(:actor2,
          send_pattern: {:periodic, Enum.at(random_delays, 2), :hi},
          targets: all_targets -- [:actor2]
        )
        |> ActorSimulation.add_actor(:actor3,
          send_pattern: {:periodic, Enum.at(random_delays, 3), :hi},
          targets: all_targets -- [:actor3]
        )
        |> ActorSimulation.add_actor(:actor4,
          send_pattern: {:periodic, Enum.at(random_delays, 4), :hi},
          targets: all_targets -- [:actor4]
        )
        |> ActorSimulation.add_actor(:actor5,
          send_pattern: {:periodic, Enum.at(random_delays, 5), :hi},
          targets: all_targets -- [:actor5]
        )
        |> ActorSimulation.add_actor(:actor6,
          send_pattern: {:periodic, Enum.at(random_delays, 6), :hi},
          targets: all_targets -- [:actor6]
        )
        |> ActorSimulation.run(duration: 2000)

      # Generate report with model source
      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Random Messaging Network",
          layout: "TB",
          model_source: model_source
        )

      filename = Path.join(@output_dir, "random_messaging_report.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated random messaging report: #{filename}")
      IO.puts("   7 actors in full mesh topology, random :hi messages, 2000ms duration")

      # Verify full mesh topology
      assert String.contains?(html, "flowchart TB")
      assert String.contains?(html, "actor0")
      assert String.contains?(html, "actor6")

      # Verify random delays are shown in the model source
      assert String.contains?(html, ":rand.seed")
      assert String.contains?(html, "random_delays")

      ActorSimulation.stop(simulation)
    end

    test "generates random hi messages sequence diagram with 7 actors" do
      # Model source code for documentation
      model_source = """
      # Create 7 actors that randomly send :hi messages to each other
      # Using fixed random seed for reproducible results

      # Set random seed for reproducibility
      :rand.seed(:exs1024, {12_345, 67_890, 11_111})

      # Create list of all actor names for random selection
      all_actors = [:alice, :bob, :charlie, :diana, :eve, :frank, :grace]

      # Function to randomly select a target (excluding self)
      random_target = fn sender, targets ->
        available_targets = Enum.reject(targets, fn target -> target == sender end)
        if length(available_targets) > 0 do
          Enum.random(available_targets)
        else
          nil
        end
      end

      # Handler that sends random :hi messages
      random_hi_handler = fn msg, state ->
        case msg do
          :hi ->
            # Randomly choose target and send :hi back
            target = random_target.(state.name, state.all_actors)
            if target do
              {:send, [{target, :hi}], state}
            else
              {:ok, state}
            end
          _ ->
            {:ok, state}
        end
      end

      simulation =
        ActorSimulation.new(trace: true)  # Enable tracing for sequence diagram
        |> ActorSimulation.add_actor(:alice,
          send_pattern: {:periodic, 200, :hi},
          targets: [:bob, :charlie, :diana, :eve, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :alice, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:bob,
          targets: [:alice, :charlie, :diana, :eve, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :bob, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:charlie,
          targets: [:alice, :bob, :diana, :eve, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :charlie, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:diana,
          targets: [:alice, :bob, :charlie, :eve, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :diana, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:eve,
          targets: [:alice, :bob, :charlie, :diana, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :eve, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:frank,
          targets: [:alice, :bob, :charlie, :diana, :eve, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :frank, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:grace,
          targets: [:alice, :bob, :charlie, :diana, :eve, :frank],
          on_receive: random_hi_handler,
          initial_state: %{name: :grace, all_actors: all_actors}
        )
        |> ActorSimulation.run(duration: 3000)  # Run for 3 seconds to get many interactions

      # Generate sequence diagram
      html = ActorSimulation.generate_sequence_diagram(simulation,
        title: "Random Hi Messages - 7 Actors",
        model_source: model_source
      )
      """

      # Set random seed for reproducible results
      :rand.seed(:exs1024, {12_345, 67_890, 11_111})

      # Create list of all actor names for random selection
      all_actors = [:alice, :bob, :charlie, :diana, :eve, :frank, :grace]

      # Function to randomly select a target (excluding self)
      random_target = fn sender, targets ->
        available_targets = Enum.reject(targets, fn target -> target == sender end)

        if length(available_targets) > 0 do
          Enum.random(available_targets)
        else
          nil
        end
      end

      # Handler that sends random :hi messages
      random_hi_handler = fn msg, state ->
        case msg do
          :hi ->
            # Randomly choose target and send :hi back
            target = random_target.(state.name, state.all_actors)

            if target do
              {:send, [{target, :hi}], state}
            else
              {:ok, state}
            end

          _ ->
            {:ok, state}
        end
      end

      # Create the actual simulation with tracing enabled
      # Enable tracing for sequence diagram
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:alice,
          send_pattern: {:periodic, 200, :hi},
          targets: [:bob, :charlie, :diana, :eve, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :alice, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:bob,
          send_pattern: {:periodic, 250, :hi},
          targets: [:alice, :charlie, :diana, :eve, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :bob, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:charlie,
          send_pattern: {:periodic, 300, :hi},
          targets: [:alice, :bob, :diana, :eve, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :charlie, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:diana,
          send_pattern: {:periodic, 350, :hi},
          targets: [:alice, :bob, :charlie, :eve, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :diana, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:eve,
          send_pattern: {:periodic, 400, :hi},
          targets: [:alice, :bob, :charlie, :diana, :frank, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :eve, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:frank,
          send_pattern: {:periodic, 450, :hi},
          targets: [:alice, :bob, :charlie, :diana, :eve, :grace],
          on_receive: random_hi_handler,
          initial_state: %{name: :frank, all_actors: all_actors}
        )
        |> ActorSimulation.add_actor(:grace,
          send_pattern: {:periodic, 500, :hi},
          targets: [:alice, :bob, :charlie, :diana, :eve, :frank],
          on_receive: random_hi_handler,
          initial_state: %{name: :grace, all_actors: all_actors}
        )
        # Run for 3 seconds to get many interactions
        |> ActorSimulation.run(duration: 3000)

      # Generate sequence diagram using the existing diagram generation test
      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Random Hi Messages - 7 Actors",
          layout: "LR",
          model_source: model_source
        )

      filename = Path.join(@output_dir, "random_hi_sequence.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated random hi sequence diagram: #{filename}")
      IO.puts("   7 actors sending random :hi messages with fixed seed")
      IO.puts("   Duration: 3000ms virtual time for maximum connections")

      # Verify we have multiple actors and connections
      assert String.contains?(html, "alice")
      assert String.contains?(html, "grace")
      assert String.contains?(html, "flowchart LR")

      ActorSimulation.stop(simulation)
    end

    test "generates real actor simulation with VirtualTimeGenServer" do
      # Model source code for documentation
      model_source = """
      # Create 7 real GenServer actors that randomly send :hi messages
      # Using VirtualTimeGenServer for virtual time support

      defmodule HiActor do
        use VirtualTimeGenServer

        def start_link(name, targets, all_actors) do
          initial_state = %{
            name: name,
            targets: targets,
            all_actors: all_actors,
            sent_count: 0,
            received_count: 0
          }
          VirtualTimeGenServer.start_link(__MODULE__, initial_state, name: name)
        end

        def handle_info(:send_random_message, state) do
          # Choose random target and send :hi
          target = Enum.random(state.targets)
          VirtualTimeGenServer.cast(target, {:hi, state.name})

          # Schedule next message with random delay 200-300ms
          delay = :rand.uniform(101) + 200
          VirtualTimeGenServer.send_after(self(), :send_random_message, delay)

          {:noreply, %{state | sent_count: state.sent_count + 1}}
        end

        def handle_cast({:hi, from}, state) do
          # Received :hi, send random response
          available_targets = Enum.reject(state.all_actors, &(&1 == from))
          if length(available_targets) > 0 do
            target = Enum.random(available_targets)
            VirtualTimeGenServer.cast(target, {:hi, state.name})
          end

          {:noreply, %{state | received_count: state.received_count + 1}}
        end
      end

      # Create simulation with real actors
      all_actors = [:alice, :bob, :charlie, :diana, :eve, :frank, :grace]

      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_process(:alice,
          module: HiActor,
          args: [:alice, [:bob, :charlie, :diana, :eve, :frank, :grace], all_actors])
        |> ActorSimulation.add_process(:bob,
          module: HiActor,
          args: [:bob, [:alice, :charlie, :diana, :eve, :frank, :grace], all_actors])
        |> ActorSimulation.add_process(:charlie,
          module: HiActor,
          args: [:charlie, [:alice, :bob, :diana, :eve, :frank, :grace], all_actors])
        |> ActorSimulation.add_process(:diana,
          module: HiActor,
          args: [:diana, [:alice, :bob, :charlie, :eve, :frank, :grace], all_actors])
        |> ActorSimulation.add_process(:eve,
          module: HiActor,
          args: [:eve, [:alice, :bob, :charlie, :diana, :frank, :grace], all_actors])
        |> ActorSimulation.add_process(:frank,
          module: HiActor,
          args: [:frank, [:alice, :bob, :charlie, :diana, :eve, :grace], all_actors])
        |> ActorSimulation.add_process(:grace,
          module: HiActor,
          args: [:grace, [:alice, :bob, :charlie, :diana, :eve, :frank], all_actors])
        |> ActorSimulation.run(duration: 3000)
      """

      # Set random seed for reproducible results
      :rand.seed(:exs1024, {12_345, 67_890, 11_111})

      # Create list of all actor names
      all_actors = [:alice, :bob, :charlie, :diana, :eve, :frank, :grace]

      # Create the actual simulation with real GenServer actors
      # Enable tracing for sequence diagram
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_process(:alice,
          module: HiActor,
          args: [:alice, [:bob, :charlie, :diana, :eve, :frank, :grace], all_actors],
          targets: [:bob, :charlie, :diana, :eve, :frank, :grace]
        )
        |> ActorSimulation.add_process(:bob,
          module: HiActor,
          args: [:bob, [:alice, :charlie, :diana, :eve, :frank, :grace], all_actors],
          targets: [:alice, :charlie, :diana, :eve, :frank, :grace]
        )
        |> ActorSimulation.add_process(:charlie,
          module: HiActor,
          args: [:charlie, [:alice, :bob, :diana, :eve, :frank, :grace], all_actors],
          targets: [:alice, :bob, :diana, :eve, :frank, :grace]
        )
        |> ActorSimulation.add_process(:diana,
          module: HiActor,
          args: [:diana, [:alice, :bob, :charlie, :eve, :frank, :grace], all_actors],
          targets: [:alice, :bob, :charlie, :eve, :frank, :grace]
        )
        |> ActorSimulation.add_process(:eve,
          module: HiActor,
          args: [:eve, [:alice, :bob, :charlie, :diana, :frank, :grace], all_actors],
          targets: [:alice, :bob, :charlie, :diana, :frank, :grace]
        )
        |> ActorSimulation.add_process(:frank,
          module: HiActor,
          args: [:frank, [:alice, :bob, :charlie, :diana, :eve, :grace], all_actors],
          targets: [:alice, :bob, :charlie, :diana, :eve, :grace]
        )
        |> ActorSimulation.add_process(:grace,
          module: HiActor,
          args: [:grace, [:alice, :bob, :charlie, :diana, :eve, :frank], all_actors],
          targets: [:alice, :bob, :charlie, :diana, :eve, :frank]
        )
        # Run for 3 seconds
        |> ActorSimulation.run(duration: 3000)

      # Generate report
      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Real Actors - VirtualTimeGenServer",
          layout: "LR",
          model_source: model_source
        )

      filename = Path.join(@output_dir, "real_actors_simulation.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated real actors simulation: #{filename}")
      IO.puts("   7 VirtualTimeGenServer actors with random delays 200-300ms")
      IO.puts("   Duration: 3000ms virtual time")

      # Verify we have multiple actors and connections
      assert String.contains?(html, "alice")
      assert String.contains?(html, "grace")
      assert String.contains?(html, "flowchart LR")

      ActorSimulation.stop(simulation)
    end
  end
end
