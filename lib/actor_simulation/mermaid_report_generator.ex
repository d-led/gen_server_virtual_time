defmodule ActorSimulation.MermaidReportGenerator do
  @moduledoc """
  Generates Mermaid-based flowchart simulation reports with statistics.

  This generator creates standalone HTML reports with embedded diagrams that show:
  - Actor topology as a Mermaid flowchart
  - Message flow connections between actors
  - Statistics embedded in the diagram (message counts, rates)
  - Styled nodes based on actor activity
  - Complete simulation statistics and model source code
  - Syntax-highlighted Elixir code for the simulation model

  These reports can be embedded in your documentation, shared with stakeholders,
  or used as standalone design documents. Perfect for visualizing distributed
  system architectures and message passing patterns.

  Based on [Mermaid Flowchart Syntax](https://mermaid.js.org/syntax/flowchart.html)

  ## Example

      simulation = ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
            send_pattern: {:periodic, 100, :data},
            targets: [:consumer])
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 1000)

      html = MermaidReportGenerator.generate_report(simulation,
        title: "Producer-Consumer System",
        output_file: "report.html")

  ## Options

  - `:title` - Report title (default: "Simulation Report")
  - `:show_stats_on_nodes` - Show stats directly on nodes (default: true)
  - `:show_message_labels` - Show message types on edges (default: true)
  - `:layout` - Flowchart direction: "TB", "LR", "RL", "BT" (default: "TB")
  - `:style_by_activity` - Color nodes by message activity (default: true)
  """

  alias ActorSimulation.Stats

  @doc """
  Generates a complete HTML report with Mermaid flowchart and statistics.

  Returns HTML string containing:
  - Mermaid flowchart showing actor topology
  - Statistics embedded in nodes
  - Detailed stats table
  - Simulation summary
  """
  def generate_report(simulation, opts \\ []) do
    title = Keyword.get(opts, :title, "Simulation Report")
    show_stats_on_nodes = Keyword.get(opts, :show_stats_on_nodes, true)
    show_message_labels = Keyword.get(opts, :show_message_labels, true)
    layout = Keyword.get(opts, :layout, "TB")
    style_by_activity = Keyword.get(opts, :style_by_activity, true)
    model_source = Keyword.get(opts, :model_source)

    stats = simulation.stats

    mermaid_code =
      generate_flowchart(simulation, %{
        show_stats: show_stats_on_nodes,
        show_labels: show_message_labels,
        layout: layout,
        style_by_activity: style_by_activity
      })

    generate_html(mermaid_code, simulation, title, stats, model_source)
  end

  @doc """
  Generates just the Mermaid flowchart code (without HTML wrapper).
  """
  def generate_flowchart(simulation, opts \\ %{}) do
    show_stats = Map.get(opts, :show_stats, true)
    show_labels = Map.get(opts, :show_labels, true)
    layout = Map.get(opts, :layout, "TB")
    style_by_activity = Map.get(opts, :style_by_activity, true)

    actors = simulation.actors
    stats = simulation.stats

    # Build flowchart
    lines = ["flowchart #{layout}"]

    # Add nodes with stats
    node_lines = generate_nodes(actors, stats, show_stats)

    # Add edges (connections)
    edge_lines = generate_edges(actors, show_labels)

    # Add styling based on activity
    style_lines =
      if style_by_activity do
        generate_styles(actors, stats)
      else
        []
      end

    (lines ++ node_lines ++ edge_lines ++ style_lines)
    |> Enum.join("\n    ")
  end

  @doc """
  Writes the report to a file.
  """
  def write_report(simulation, filename, opts \\ []) do
    html = generate_report(simulation, opts)
    File.mkdir_p!(Path.dirname(filename))
    File.write!(filename, html)
    {:ok, filename}
  end

  # Private functions

  defp generate_nodes(actors, stats, show_stats) do
    Enum.map(actors, fn {name, actor_info} ->
      case actor_info.type do
        :simulated ->
          generate_node(name, actor_info, stats, show_stats)

        :real_process ->
          generate_process_node(name, actor_info, show_stats)
      end
    end)
  end

  defp generate_node(name, actor_info, stats, show_stats) do
    definition = actor_info.definition
    actor_stats = get_actor_stats(stats, name)

    # Choose node shape based on actor type
    {shape_start, shape_end} = node_shape(definition)

    # Build node label
    label =
      if show_stats && actor_stats do
        """
        #{name}<br/>
        📤 Sent: #{actor_stats.sent_count}<br/>
        📥 Recv: #{actor_stats.received_count}
        """
        |> String.trim()
      else
        "#{name}"
      end

    # Sanitize label for Mermaid
    safe_label = label |> String.replace("\"", "&quot;")

    "#{name}#{shape_start}\"#{safe_label}\"#{shape_end}"
  end

  defp generate_process_node(name, _actor_info, show_stats) do
    # Real processes get a different shape (subroutine)
    label =
      if show_stats do
        "#{name}<br/>Real Process"
      else
        "#{name}"
      end

    safe_label = label |> String.replace("\"", "&quot;")
    "#{name}[[\"#{safe_label}\"]]"
  end

  defp node_shape(definition) do
    cond do
      # Source actors (only send): stadium shape (oval) - matches legend
      definition.send_pattern != nil && definition.on_receive == nil &&
          definition.on_match == [] ->
        {"([", "])"}

      # Sink actors (only receive): asymmetric shape (L-shape) - matches legend
      definition.send_pattern == nil &&
          (definition.on_receive != nil || definition.on_match != []) ->
        {">", "]"}

      # Processing actors (send and receive): rounded rectangle - matches legend
      definition.send_pattern != nil &&
          (definition.on_receive != nil || definition.on_match != []) ->
        {"(", ")"}

      # Passive actors: regular rectangle
      true ->
        {"[", "]"}
    end
  end

  defp generate_edges(actors, show_labels) do
    Enum.flat_map(actors, fn {name, actor_info} ->
      case actor_info.type do
        :simulated ->
          definition = actor_info.definition
          targets = definition.targets || []

          Enum.map(targets, fn target ->
            generate_edge_label(name, target, definition, show_labels)
          end)

        :real_process ->
          []
      end
    end)
  end

  defp generate_edge_label(name, target, definition, show_labels) do
    if show_labels do
      msg_label = get_message_label(definition)
      if msg_label do
        "#{name} -->|#{msg_label}| #{target}"
      else
        "#{name} --> #{target}"
      end
    else
      "#{name} --> #{target}"
    end
  end

  defp get_message_label(definition) do
    cond do
      # Actors with send_pattern (periodic/rate/burst)
      definition.send_pattern ->
        extract_message_label(definition.send_pattern)

      # Actors that forward messages via on_receive
      definition.on_receive && definition.targets && length(definition.targets) > 0 ->
        # Try to infer the forwarded message type from common patterns
        case definition.initial_state do
          %{next: _} ->
            # This looks like a forwarding actor, use a generic label
            "forwarded<br/>message"
          _ ->
            nil
        end

      true ->
        nil
    end
  end

  defp extract_message_label(send_pattern) do
    case send_pattern do
      {:periodic, interval, message} ->
        "#{inspect(message)}<br/>every #{interval}ms"

      {:rate, per_second, message} ->
        "#{inspect(message)}<br/>#{per_second}/s"

      {:burst, count, interval, message} ->
        "#{inspect(message)}<br/>#{count} per #{interval}ms"

      _ ->
        "message"
    end
  end

  defp generate_styles(actors, stats) do
    Enum.flat_map(actors, fn {name, actor_info} ->
      case actor_info.type do
        :simulated ->
          actor_stats = get_actor_stats(stats, name)
          style_for_activity(name, actor_stats)

        :real_process ->
          ["style #{name} fill:#e1f5fe,stroke:#01579b,stroke-width:2px"]
      end
    end)
  end

  defp style_for_activity(name, nil) do
    ["style #{name} fill:#f5f5f5,stroke:#9e9e9e"]
  end

  defp style_for_activity(name, actor_stats) do
    total_activity = actor_stats.sent_count + actor_stats.received_count

    cond do
      total_activity == 0 ->
        # Inactive: gray
        ["style #{name} fill:#f5f5f5,stroke:#9e9e9e"]

      total_activity < 10 ->
        # Low activity: light blue
        ["style #{name} fill:#e3f2fd,stroke:#1976d2"]

      total_activity < 50 ->
        # Medium activity: green
        ["style #{name} fill:#e8f5e9,stroke:#388e3c"]

      true ->
        # High activity: orange
        ["style #{name} fill:#fff3e0,stroke:#f57c00,stroke-width:3px"]
    end
  end

  defp get_actor_stats(stats, actor_name) do
    Map.get(stats.actors, actor_name)
  end

  defp generate_html(mermaid_code, simulation, title, stats, model_source) do
    formatted_stats = Stats.format(stats)
    stats_table = generate_stats_table(formatted_stats)
    simulation_summary = generate_simulation_summary(simulation)
    model_source_section = if model_source, do: generate_model_source_section(model_source), else: ""

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{title}</title>
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
          color: #212529;
        }
        h1 {
          color: #2c3e50;
          margin-bottom: 10px;
        }
        .subtitle {
          color: #6c757d;
          font-size: 14px;
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
        .diagram-container {
          display: flex;
          justify-content: center;
          overflow-x: auto;
          padding: 20px 0;
        }
        .mermaid {
          min-width: 600px;
        }
        .summary-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 20px;
          margin-bottom: 20px;
        }
        .summary-card {
          background: #f8f9fa;
          padding: 15px;
          border-radius: 6px;
          border-left: 4px solid #007bff;
        }
        .summary-card.warning {
          border-left-color: #ffc107;
        }
        .summary-card.success {
          border-left-color: #28a745;
        }
        .summary-card .label {
          font-size: 12px;
          color: #6c757d;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 5px;
        }
        .summary-card .value {
          font-size: 24px;
          font-weight: bold;
          color: #212529;
        }
        .summary-card .unit {
          font-size: 14px;
          color: #6c757d;
          margin-left: 4px;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          margin-top: 20px;
        }
        th, td {
          padding: 12px;
          text-align: left;
          border-bottom: 1px solid #e9ecef;
        }
        th {
          background: #f8f9fa;
          font-weight: 600;
          color: #495057;
        }
        tr:hover {
          background: #f8f9fa;
        }
        .metric {
          font-variant-numeric: tabular-nums;
        }
        .badge {
          display: inline-block;
          padding: 4px 8px;
          background: #e3f2fd;
          color: #1976d2;
          border-radius: 4px;
          font-size: 12px;
          font-weight: 500;
        }
        .badge.high {
          background: #fff3e0;
          color: #f57c00;
        }
        .badge.low {
          background: #f5f5f5;
          color: #9e9e9e;
        }
        .legend {
          display: flex;
          gap: 20px;
          flex-wrap: wrap;
          margin-top: 20px;
          padding: 15px;
          background: #f8f9fa;
          border-radius: 6px;
        }
        .legend-item {
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .legend-shape {
          width: 40px;
          height: 24px;
          border: 2px solid #495057;
          background: white;
        }
        .legend-shape.stadium {
          border-radius: 12px;
        }
        .legend-shape.rounded {
          border-radius: 4px;
        }
        .legend-shape.asymmetric {
          clip-path: polygon(0 0, 100% 20%, 100% 100%, 0 80%);
        }
        .code-link {
          color: #007bff;
          text-decoration: none;
          font-size: 14px;
        }
        .code-link:hover {
          text-decoration: underline;
        }
        footer {
          margin-top: 40px;
          padding-top: 20px;
          border-top: 1px solid #e9ecef;
          text-align: center;
          color: #6c757d;
          font-size: 14px;
        }
        .source-links {
          margin-top: 20px;
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
      <div class="subtitle">
        Generated by GenServerVirtualTime •
        <a href="https://mermaid.js.org/syntax/flowchart.html" class="code-link" target="_blank">Mermaid Flowchart</a>
      </div>

      #{simulation_summary}

      <div class="section">
        <h2>📊 Actor Topology</h2>
        <div class="diagram-container">
          <div class="mermaid">
    #{mermaid_code}
          </div>
        </div>

        <div class="legend">
          <div class="legend-item">
            <div class="legend-shape stadium"></div>
            <span>Source (sends only)</span>
          </div>
          <div class="legend-item">
            <div class="legend-shape asymmetric"></div>
            <span>Sink (receives only)</span>
          </div>
          <div class="legend-item">
            <div class="legend-shape rounded"></div>
            <span>Processor (send & receive)</span>
          </div>
        </div>
      </div>

      #{stats_table}

      #{model_source_section}

      <div class="source-links">
        <h3>🔗 Source & Links</h3>
        <a href="https://github.com/d-led/gen_server_virtual_time" target="_blank" class="github">📚 GitHub Repository</a>
        <a href="https://github.com/d-led/gen_server_virtual_time/blob/main/lib/actor_simulation/mermaid_report_generator.ex" target="_blank" class="github">🧪 Report Generator</a>
        <a href="https://hexdocs.pm/gen_server_virtual_time" target="_blank">📖 Documentation</a>
        <a href="https://hex.pm/packages/gen_server_virtual_time" target="_blank">📦 Hex Package</a>
      </div>

      <footer>
        Generated by
        <a href="https://hexdocs.pm/gen_server_virtual_time" style="color: #007bff;">GenServerVirtualTime</a>
        using <a href="https://mermaid.js.org" style="color: #007bff;">Mermaid</a>
      </footer>

      <script>
        mermaid.initialize({
          startOnLoad: true,
          theme: 'default',
          flowchart: {
            useMaxWidth: true,
            htmlLabels: true,
            curve: 'basis'
          }
        });
      </script>
    </body>
    </html>
    """
  end

  defp generate_simulation_summary(simulation) do
    actual_duration = Map.get(simulation, :actual_duration, 0)
    terminated_early = Map.get(simulation, :terminated_early, false)
    real_time_elapsed = Map.get(simulation, :real_time_elapsed, 0)

    # Calculate speedup
    speedup =
      if real_time_elapsed > 0 do
        Float.round(actual_duration / real_time_elapsed, 1)
      else
        0
      end

    termination_card =
      if terminated_early do
        """
        <div class="summary-card success">
          <div class="label">Termination</div>
          <div class="value">⚡ Early</div>
        </div>
        """
      else
        """
        <div class="summary-card">
          <div class="label">Termination</div>
          <div class="value">✓ Quiescence</div>
        </div>
        """
      end

    """
    <div class="section">
      <h2>📈 Simulation Summary</h2>
      <div class="summary-grid">
        <div class="summary-card">
          <div class="label">Virtual Time</div>
          <div class="value">#{actual_duration}<span class="unit">ms</span></div>
        </div>
        <div class="summary-card">
          <div class="label">Real Time</div>
          <div class="value">#{real_time_elapsed}<span class="unit">ms</span></div>
        </div>
        <div class="summary-card success">
          <div class="label">Speedup</div>
          <div class="value">#{speedup}x</div>
        </div>
        #{termination_card}
      </div>
    </div>
    """
  end

  defp generate_stats_table(formatted_stats) do
    actor_rows =
      Enum.map_join(formatted_stats.actors, "\n", fn {name, actor_stats} ->
        activity_level = actor_stats.sent + actor_stats.received

        badge_class =
          if(activity_level > 50, do: "high", else: if(activity_level > 10, do: "", else: "low"))

        """
        <tr>
          <td><strong>#{name}</strong></td>
          <td class="metric">#{actor_stats.sent}</td>
          <td class="metric">#{actor_stats.received}</td>
          <td class="metric">#{actor_stats.sent_rate} msg/s</td>
          <td class="metric">#{actor_stats.received_rate} msg/s</td>
          <td><span class="badge #{badge_class}">#{activity_level} total</span></td>
        </tr>
        """
      end)

    """
    <div class="section">
      <h2>📉 Detailed Statistics</h2>
      <table>
        <thead>
          <tr>
            <th>Actor</th>
            <th>Sent</th>
            <th>Received</th>
            <th>Send Rate</th>
            <th>Receive Rate</th>
            <th>Activity</th>
          </tr>
        </thead>
        <tbody>
          #{actor_rows}
        </tbody>
      </table>

      <div style="margin-top: 20px; padding: 15px; background: #e3f2fd; border-radius: 6px;">
        <strong>Summary:</strong>
        Total messages: #{formatted_stats.total_messages} •
        Duration: #{formatted_stats.duration_ms}ms •
        Actors: #{map_size(formatted_stats.actors)}
      </div>
    </div>
    """
  end

  defp generate_model_source_section(model_source) do
    """
    <div class="section">
      <h2>💻 Model Source Code</h2>
      <p>This is the Elixir code that defines the actor simulation model:</p>
      <div class="code-block">
        <pre><code class="language-elixir">#{model_source}</code></pre>
      </div>
    </div>
    """
  end
end
