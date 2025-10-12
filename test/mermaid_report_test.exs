defmodule MermaidReportTest do
  use ExUnit.Case, async: false

  alias ActorSimulation.MermaidReportGenerator

  @output_dir "doc/examples/reports"

  setup_all do
    File.mkdir_p!(@output_dir)
    :ok
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
      # Create a more complex pipeline
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

      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Pipeline Processing",
          show_stats_on_nodes: true
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
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:publisher,
          send_pattern: {:rate, 10, :event},
          targets: [:sub1, :sub2, :sub3]
        )
        |> ActorSimulation.add_actor(:sub1)
        |> ActorSimulation.add_actor(:sub2)
        |> ActorSimulation.add_actor(:sub3)
        |> ActorSimulation.run(duration: 1000)

      html =
        MermaidReportGenerator.generate_report(simulation,
          title: "Pub-Sub System",
          layout: "TB"
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
          style_by_activity: true
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
          title: "Early Termination Test"
        )

      filename = Path.join(@output_dir, "early_termination_report.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated early termination report: #{filename}")

      assert String.contains?(html, "Early")
      assert simulation.terminated_early

      ActorSimulation.stop(simulation)
    end

    test "supports different layout directions" do
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
            title: title
          )

        filename = Path.join(@output_dir, "layout_#{name}_report.html")
        File.write!(filename, html)
      end

      IO.puts("\n✅ Generated all layout direction reports")

      ActorSimulation.stop(simulation)
    end

    test "write_report helper function" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:actor1,
          send_pattern: {:periodic, 100, :msg},
          targets: [:actor2]
        )
        |> ActorSimulation.add_actor(:actor2)
        |> ActorSimulation.run(duration: 300)

      filename = Path.join(@output_dir, "write_helper_test.html")

      {:ok, ^filename} =
        MermaidReportGenerator.write_report(simulation, filename, title: "Write Helper Test")

      assert File.exists?(filename)
      content = File.read!(filename)
      assert String.contains?(content, "Write Helper Test")

      ActorSimulation.stop(simulation)
    end

  end
end
