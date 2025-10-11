defmodule DiagramGenerationTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Tests that generate viewable HTML files with sequence diagrams.
  Open the generated HTML files in a browser to see the diagrams!
  """

  @output_dir "test/output"

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

  describe "PlantUML diagram generation" do
    test "generates viewable PlantUML HTML file" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:alice,
          send_pattern: {:periodic, 100, :hello},
          targets: [:bob]
        )
        |> ActorSimulation.add_actor(:bob,
          on_match: [
            {:hello, fn state -> {:send, [{:alice, :hi}], state} end}
          ]
        )
        |> ActorSimulation.run(duration: 300)

      # Generate PlantUML diagram
      plantuml = ActorSimulation.trace_to_plantuml(simulation)

      # Create self-contained HTML with PlantUML
      html = generate_plantuml_html(plantuml, "Alice and Bob")

      # Write to file
      filename = Path.join(@output_dir, "plantuml_simple.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated PlantUML diagram: #{filename}")
      IO.puts("   Open in browser to view!")

      # Verify content
      assert String.contains?(plantuml, "@startuml")
      assert String.contains?(html, "plantuml.com/plantuml")

      ActorSimulation.stop(simulation)
    end

    test "generates PlantUML pub-sub diagram" do
      simulation =
        ActorSimulation.new(trace: true)
        |> ActorSimulation.add_actor(:publisher,
          send_pattern: {:periodic, 100, :event},
          targets: [:sub1, :sub2, :sub3]
        )
        |> ActorSimulation.add_actor(:sub1)
        |> ActorSimulation.add_actor(:sub2)
        |> ActorSimulation.add_actor(:sub3)
        |> ActorSimulation.run(duration: 200)

      plantuml = ActorSimulation.trace_to_plantuml(simulation)
      html = generate_plantuml_html(plantuml, "Pub-Sub Pattern")

      filename = Path.join(@output_dir, "plantuml_pubsub.html")
      File.write!(filename, html)

      IO.puts("\n✅ Generated PlantUML pub-sub: #{filename}")

      ActorSimulation.stop(simulation)
    end
  end

  describe "Combined output" do
    test "generates index page with links to all diagrams" do
      # Create an index page
      html = """
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>GenServerVirtualTime - Generated Diagrams</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 1200px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
          }
          h1 { color: #333; }
          .diagram-list {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 30px;
          }
          .diagram-card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            transition: transform 0.2s;
          }
          .diagram-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
          }
          .diagram-card h3 {
            margin-top: 0;
            color: #2c5282;
          }
          .diagram-card a {
            display: inline-block;
            margin-top: 10px;
            padding: 8px 16px;
            background: #4299e1;
            color: white;
            text-decoration: none;
            border-radius: 4px;
          }
          .diagram-card a:hover {
            background: #2b6cb0;
          }
          .badge {
            display: inline-block;
            padding: 4px 8px;
            background: #48bb78;
            color: white;
            border-radius: 4px;
            font-size: 12px;
            margin-bottom: 10px;
          }
          .mermaid-badge { background: #ff6b6b; }
          .plantuml-badge { background: #4299e1; }
        </style>
      </head>
      <body>
        <h1>🎬 GenServerVirtualTime - Generated Sequence Diagrams</h1>
        <p>These diagrams were automatically generated during testing to visualize actor message flows.</p>

        <div class="diagram-list">
          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>Simple Request-Response</h3>
            <p>Basic client-server interaction with request and response messages.</p>
            <a href="mermaid_simple.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>Authentication Pipeline</h3>
            <p>Multi-stage authentication flow: API → Auth → Database → Response.</p>
            <a href="mermaid_pipeline.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>Sync vs Async</h3>
            <p>Demonstrates synchronous calls and asynchronous casts with different arrow styles.</p>
            <a href="mermaid_sync_async.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>Timeline with Timestamps</h3>
            <p>Shows virtual time progression with timestamp annotations.</p>
            <a href="mermaid_with_timestamps.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge plantuml-badge">PlantUML</span>
            <h3>Alice and Bob</h3>
            <p>Simple two-actor conversation showing PlantUML rendering.</p>
            <a href="plantuml_simple.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge plantuml-badge">PlantUML</span>
            <h3>Pub-Sub Pattern</h3>
            <p>One publisher broadcasting to multiple subscribers.</p>
            <a href="plantuml_pubsub.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>🍴 2 Philosophers</h3>
            <p>Minimal dining philosophers - simplest case with clear interactions.</p>
            <a href="dining_philosophers_2.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>🍴 3 Philosophers</h3>
            <p>Small table - easier to follow message patterns.</p>
            <a href="dining_philosophers_3.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>🍴 5 Philosophers</h3>
            <p>Classic problem - full complexity with deadlock-free solution.</p>
            <a href="dining_philosophers_5.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>⚡ 2 Phil Terminated</h3>
            <p>Stops when goal achieved - shows exact termination time!</p>
            <a href="dining_philosophers_2_condition_terminated.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>⚡ 3 Phil Terminated</h3>
            <p>Condition-based termination for 3 philosophers.</p>
            <a href="dining_philosophers_3_condition_terminated.html" target="_blank">View Diagram →</a>
          </div>

          <div class="diagram-card">
            <span class="badge mermaid-badge">Mermaid</span>
            <h3>⚡ 5 Phil Terminated</h3>
            <p>Classic table with termination indicator.</p>
            <a href="dining_philosophers_5_condition_terminated.html" target="_blank">View Diagram →</a>
          </div>
        </div>

        <h2 style="margin-top: 40px;">📊 Summary</h2>
        <div style="background: #e3f2fd; padding: 20px; border-radius: 8px; margin-top: 20px;">
          <p><strong>Total Diagrams:</strong> 14</p>
          <p><strong>Mermaid:</strong> 11 (with enhanced features)</p>
          <p><strong>PlantUML:</strong> 2</p>
          <p><strong>Dining Philosophers:</strong></p>
          <ul>
            <li>Fixed duration: 2, 3, 5 philosophers</li>
            <li>Condition-terminated (⚡): 2, 3, 5 philosophers</li>
          </ul>
          <p><strong>Enhanced Mermaid Features:</strong></p>
          <ul>
            <li>✅ Different arrow types (->> vs -->>)</li>
            <li>✅ Activation boxes showing processing</li>
            <li>✅ Timestamp annotations (virtual time)</li>
            <li>✅ Termination indicators (⚡ when goals achieved)</li>
            <li>✅ Self-contained HTML with CDN</li>
            <li>✅ Based on <a href="https://docs.mermaidchart.com/mermaid-oss/syntax/sequenceDiagram.html">Mermaid spec</a></li>
          </ul>
        </div>

        <hr style="margin: 40px 0; border: none; border-top: 1px solid #ddd;">
        <p style="color: #666; font-size: 14px;">
          Generated by
          <a href="https://hexdocs.pm/gen_server_virtual_time" style="color: #4299e1; text-decoration: none;">GenServerVirtualTime</a>
          test suite •
          <a href="https://github.com/d-led/gen_server_virtual_time" style="color: #4299e1; text-decoration: none;">
            <svg style="display: inline-block; vertical-align: middle; width: 16px; height: 16px; margin-right: 4px;" viewBox="0 0 16 16" fill="currentColor">
              <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"/>
            </svg>
            View on GitHub
          </a>
        </p>
      </body>
      </html>
      """

      filename = Path.join(@output_dir, "index.html")
      File.write!(filename, html)

      IO.puts("\n📋 Generated index page: #{filename}")
      IO.puts("   Open this to browse all diagrams!")
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

  defp generate_plantuml_html(plantuml_code, title) do
    # Encode PlantUML for the server
    encoded = encode_plantuml(plantuml_code)

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{title} - PlantUML Diagram</title>
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
          text-align: center;
        }
        .diagram-container img {
          max-width: 100%;
          height: auto;
        }
        .info {
          background: #fff3e0;
          padding: 15px;
          border-left: 4px solid #ff9800;
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
        <strong>📊 PlantUML Sequence Diagram</strong> - Generated by GenServerVirtualTime<br>
        This diagram was automatically generated from simulation trace events.
      </div>

      <div class="diagram-container">
        <img src="https://www.plantuml.com/plantuml/svg/#{encoded}" alt="PlantUML Diagram">
      </div>

      <div class="code-block">
        <strong>Source Code:</strong>
        <pre>#{plantuml_code}</pre>
      </div>
    </body>
    </html>
    """
  end

  defp encode_plantuml(text) do
    # Simple PlantUML encoding (deflate + base64)
    # For production use, you'd want a proper encoder library
    # This is a simplified version for demonstration
    compressed = :zlib.compress(text)
    Base.url_encode64(compressed, padding: false)
  end
end
