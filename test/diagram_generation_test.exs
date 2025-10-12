defmodule DiagramGenerationTest do
  use ExUnit.Case, async: false

  # Use fixed seed for deterministic diagram generation
  @moduletag :capture_log
  @moduletag :diagram_generation

  setup_all do
    # Set seed to make tests deterministic
    :rand.seed(:exsss, {100, 101, 102})
    :ok
  end

  @moduledoc """
  Tests that generate viewable HTML files with sequence diagrams.
  Open the generated HTML files in a browser to see the diagrams!
  """

  @output_dir "generated/examples"

  setup_all do
    File.mkdir_p!(@output_dir)
    :ok
  end

  describe "Mermaid diagram generation" do
    test "generates viewable Mermaid HTML file" do
      # Create a simple simulation
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:client,
          send_pattern: {:periodic, 100, :request},
          targets: [:server]
        )
        |> ActorSimulation.add_actor(:server,
          on_match: [
            {:request, fn state -> {:send, [{:client, :response}], state} end}
          ]
        )
        |> ActorSimulation.add_actor(:database)
        |> ActorSimulation.run(duration: 300)

      # Generate Mermaid diagram
      mermaid = ActorSimulation.trace_to_mermaid(simulation)

      # Create self-contained HTML with Mermaid
      html = generate_mermaid_html(mermaid, "Simple Request-Response")

      # Write to file
      filename = Path.join(@output_dir, "mermaid_simple.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated Mermaid diagram: #{filename}")
      IO.puts("   Open in browser to view!")

      # Verify content
      assert String.contains?(mermaid, "sequenceDiagram")
      assert String.contains?(html, "mermaid.min.js")

      ActorSimulation.stop(simulation)
    end

    test "generates complex Mermaid pipeline diagram" do
      forward = fn msg, state ->
        {:send, [{state.next, msg}], state}
      end

      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:api,
          send_pattern: {:periodic, 100, {:check_auth, :user123}},
          targets: [:auth]
        )
        |> ActorSimulation.add_actor(:auth,
          on_receive: forward,
          initial_state: %{next: :database}
        )
        |> ActorSimulation.add_actor(:database,
          on_receive: fn
            {:check_auth, _user}, state ->
              {:send, [{:api, {:auth_ok, :token456}}], state}

            _, state ->
              {:ok, state}
          end
        )
        |> ActorSimulation.run(duration: 400)

      mermaid = ActorSimulation.trace_to_mermaid(simulation)
      html = generate_mermaid_html(mermaid, "Authentication Pipeline")

      filename = Path.join(@output_dir, "mermaid_pipeline.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated Mermaid pipeline: #{filename}")

      ActorSimulation.stop(simulation)
    end

    test "generates Mermaid diagram with sync/async calls" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:requester,
          send_pattern: {:periodic, 100, {:call, :get_data}},
          targets: [:responder]
        )
        |> ActorSimulation.add_actor(:notifier,
          send_pattern: {:periodic, 150, {:cast, :notify}},
          targets: [:listener]
        )
        |> ActorSimulation.add_actor(:responder,
          on_match: [
            {:get_data, fn state -> {:reply, {:data, 42}, state} end}
          ]
        )
        |> ActorSimulation.add_actor(:listener)
        |> ActorSimulation.run(duration: 300)

      mermaid = ActorSimulation.trace_to_mermaid(simulation)
      html = generate_mermaid_html(mermaid, "Sync vs Async Communication")

      filename = Path.join(@output_dir, "mermaid_sync_async.html")
      File.write!(filename, html)

      # Verify we're using dotted lines for cast
      # Async cast
      assert String.contains?(mermaid, "-->>")
      # Activation for calls
      assert String.contains?(mermaid, "activate")

      IO.puts("\n✅ Generated sync/async diagram: #{filename}")

      ActorSimulation.stop(simulation)
    end

    test "generates Mermaid diagram with timestamps" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :tick},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)
        |> ActorSimulation.run(duration: 300)

      # Generate with timestamps enabled
      mermaid = ActorSimulation.trace_to_mermaid(simulation, timestamps: true)
      html = generate_mermaid_html(mermaid, "Timeline with Timestamps")

      filename = Path.join(@output_dir, "mermaid_with_timestamps.html")
      File.write!(filename, html)

      # Verify timestamps are included as notes
      assert String.contains?(mermaid, "Note over")
      assert String.contains?(mermaid, "t=")

      IO.puts("\n✅ Generated timeline with timestamps: #{filename}")

      ActorSimulation.stop(simulation)
    end
  end


  # Helper functions

  defp generate_mermaid_html(mermaid_code, title) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{title} - Mermaid Diagram</title>
      <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          max-width: 1400px;
          margin: 0 auto;
          padding: 40px 20px;
          background: #f8f9fa;
        }
        h1 {
          color: #2c3e50;
          margin-bottom: 30px;
        }
        .diagram-container {
          background: white;
          padding: 40px;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          overflow-x: auto;
        }
        .mermaid {
          display: flex;
          justify-content: center;
        }
        .info {
          background: #e3f2fd;
          padding: 15px;
          border-left: 4px solid #2196f3;
          margin-bottom: 20px;
          border-radius: 4px;
        }
        .code-block {
          background: #263238;
          color: #aed581;
          padding: 20px;
          border-radius: 4px;
          margin-top: 30px;
          overflow-x: auto;
        }
        pre {
          margin: 0;
          font-family: 'Monaco', 'Menlo', monospace;
          font-size: 14px;
        }
      </style>
    </head>
    <body>
      <h1>#{title}</h1>

      <div class="info">
        <strong>🎬 Mermaid Sequence Diagram</strong> - Generated by GenServerVirtualTime<br>
        This diagram was automatically generated from simulation trace events.
      </div>

      <div class="diagram-container">
        <div class="mermaid">
    #{mermaid_code}
        </div>
      </div>

      <div class="code-block">
        <strong>Source Code:</strong>
        <pre>#{mermaid_code}</pre>
      </div>

      <script>
        mermaid.initialize({
          startOnLoad: true,
          theme: 'default',
          sequence: {
            diagramMarginX: 50,
            diagramMarginY: 10,
            boxTextMargin: 5,
            noteMargin: 10,
            messageMargin: 35,
            mirrorActors: true
          }
        });
      </script>
    </body>
    </html>
    """
  end

end
