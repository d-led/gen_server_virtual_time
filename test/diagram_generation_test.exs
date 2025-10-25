defmodule DiagramGenerationTest do
  use ExUnit.Case, async: true

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

  # Helper to define simulation and generate source code from quoted expression
  # This eliminates code duplication by defining the simulation once
  defp simulation_with_source(quoted_code) do
    simulation = Code.eval_quoted(quoted_code) |> elem(0)
    source = "simulation =\n#{Macro.to_string(quoted_code)}"
    {simulation, source}
  end

  describe "Mermaid diagram generation" do
    test "generates viewable Mermaid HTML file" do
      # Define simulation once using quoted expression
      simulation_code =
        quote do
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
        end

      # Generate both simulation and source code from the same definition
      {simulation, model_source} = simulation_with_source(simulation_code)

      # Generate Mermaid diagram
      mermaid = ActorSimulation.trace_to_mermaid(simulation)

      # Create self-contained HTML with Mermaid
      html = generate_mermaid_html(mermaid, "Simple Request-Response", model_source: model_source)

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
      model_source = """
      # Create a pipeline with message forwarding
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
      """

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
      html = generate_mermaid_html(mermaid, "Authentication Pipeline", model_source: model_source)

      filename = Path.join(@output_dir, "mermaid_pipeline.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated Mermaid pipeline: #{filename}")

      ActorSimulation.stop(simulation)
    end

    test "generates Mermaid diagram with sync/async calls" do
      model_source = """
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
      """

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

      html =
        generate_mermaid_html(mermaid, "Sync vs Async Communication", model_source: model_source)

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
      model_source = """
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
      """

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

      html =
        generate_mermaid_html(mermaid, "Timeline with Timestamps", model_source: model_source)

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

  defp generate_mermaid_html(mermaid_code, title, opts) do
    model_source = Keyword.get(opts, :model_source)

    model_source_section =
      if model_source do
        """
        <div class="section">
          <h2>💻 Model Source Code</h2>
          <p>This is the Elixir code that defines the actor simulation model:</p>
          <div class="code-block">
            <pre><code class="language-elixir">#{model_source}</code></pre>
          </div>
        </div>
        """
      else
        ""
      end

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{title} - Mermaid Diagram</title>
      <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
      <link href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism.min.css" rel="stylesheet" />
      <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-core.min.js"></script>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/plugins/autoloader/prism-autoloader.min.js"></script>
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
        .section {
          background: white;
          padding: 30px;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          margin-bottom: 30px;
        }
        .section h2 {
          color: #495057;
          margin-top: 0;
          margin-bottom: 20px;
          border-bottom: 2px solid #e9ecef;
          padding-bottom: 10px;
        }
        .section p {
          color: #6c757d;
          margin-bottom: 15px;
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
          background: #f8f9fa;
          padding: 0;
          border-radius: 4px;
          overflow: hidden;
        }
        .code-block pre {
          margin: 0;
          padding: 20px;
        }
        .code-block code {
          font-family: 'Monaco', 'Menlo', 'Consolas', monospace;
          font-size: 14px;
        }
        pre {
          margin: 0;
          font-family: 'Monaco', 'Menlo', monospace;
          font-size: 14px;
        }
        .source-links {
          margin-top: 30px;
          padding: 20px;
          background: #f8f9fa;
          border-radius: 8px;
          border: 1px solid #e9ecef;
        }
        .source-links h3 {
          margin: 0 0 15px 0;
          color: #2c3e50;
          font-size: 1.1em;
        }
        .source-links a {
          display: inline-block;
          margin: 5px 10px 5px 0;
          padding: 8px 16px;
          background: #007bff;
          color: white;
          text-decoration: none;
          border-radius: 4px;
          font-size: 14px;
          transition: background 0.2s;
        }
        .source-links a:hover {
          background: #0056b3;
        }
        .source-links a.github {
          background: #24292e;
        }
        .source-links a.github:hover {
          background: #1a1e22;
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

      #{model_source_section}

      <div class="source-links">
        <h3>🔗 Source & Links</h3>
        <a href="https://github.com/d-led/gen_server_virtual_time" target="_blank" class="github">📚 GitHub Repository</a>
        <a href="https://github.com/d-led/gen_server_virtual_time/blob/main/test/diagram_generation_test.exs" target="_blank" class="github">🧪 Test Source</a>
        <a href="https://hexdocs.pm/gen_server_virtual_time" target="_blank">📖 Documentation</a>
        <a href="https://hex.pm/packages/gen_server_virtual_time" target="_blank">📦 Hex Package</a>
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
