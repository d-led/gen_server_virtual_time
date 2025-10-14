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

  alias ActorSimulation.GeneratorMetadata
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

    # Auto-detect generator metadata if not provided
    generated_by = Keyword.get(opts, :generated_by) || GeneratorMetadata.from_stacktrace()

    stats = simulation.stats

    mermaid_code =
      generate_flowchart(simulation, %{
        show_stats: show_stats_on_nodes,
        show_labels: show_message_labels,
        layout: layout,
        style_by_activity: style_by_activity
      })

    generate_html(mermaid_code, simulation, title, stats, model_source, generated_by)
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

    # Add edges (connections) from both definitions and actual trace
    edge_lines = generate_edges(actors, simulation.trace, show_labels)

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
          generate_process_node(name, actor_info, stats, show_stats)
      end
    end)
  end

  defp generate_node(name, actor_info, stats, show_stats) do
    definition = actor_info.definition
    actor_stats = get_actor_stats(stats, name)

    # Choose node shape based on actor type (considering actual stats)
    {shape_start, shape_end} = node_shape(definition, stats, name)

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

    "#{name}#{shape_start}#{safe_label}#{shape_end}"
  end

  defp generate_process_node(name, actor_info, stats, show_stats) do
    # Determine node shape based on targets and stats
    targets = actor_info.targets || []
    actor_stats = get_actor_stats(stats, name)

    # Determine if this is a source, sink, or processor based on behavior
    has_targets = length(targets) > 0
    has_stats = actor_stats != nil
    sent_count = if has_stats, do: actor_stats.sent_count, else: 0
    received_count = if has_stats, do: actor_stats.received_count, else: 0

    # Determine node type based on behavior (not just targets)
    # A processor is an actor that can both send AND receive (has targets and can receive)
    # A source is an actor that only sends (has targets but never receives)
    # A sink is an actor that only receives (no targets)
    is_sink = !has_targets
    is_source = has_targets && !is_sink && sent_count > 0 && received_count == 0
    is_processor = has_targets && !is_sink && !is_source

    # Choose shape
    {left_shape, right_shape} =
      cond do
        # Stadium shape (oval) for source
        is_source -> {"([\"", "\"])"}
        # Rectangle for sink
        is_sink -> {"[\"", "\"]"}
        # Rounded rectangle for processor
        is_processor -> {"(\"", "\")"}
        # Regular rectangle for unknown
        true -> {"[\"", "\"]"}
      end

    # Build label with stats
    label =
      cond do
        show_stats && has_stats ->
          "#{name}<br/>📤 Sent: #{sent_count}<br/>📥 Recv: #{received_count}"

        show_stats ->
          "#{name}<br/>Real Process"

        true ->
          "#{name}"
      end

    safe_label = label |> String.replace("\"", "&quot;")
    "#{name}#{left_shape}#{safe_label}#{right_shape}"
  end

  defp node_shape(definition, stats, name) do
    capabilities = analyze_actor_capabilities(definition, stats, name)
    select_shape_for_capabilities(capabilities)
  end

  defp analyze_actor_capabilities(_definition, stats, name) do
    # Determine capabilities purely based on actual message behavior from trace
    actor_stats = get_actor_stats(stats, name)
    actually_receives = actor_stats != nil && actor_stats.received_count > 0
    actually_sends = actor_stats != nil && actor_stats.sent_count > 0

    %{
      is_source: actually_sends && !actually_receives,
      is_sink: actually_receives && !actually_sends,
      is_processor: actually_sends && actually_receives
    }
  end

  defp select_shape_for_capabilities(%{is_source: true}), do: {"([\"", "\"])"}
  defp select_shape_for_capabilities(%{is_processor: true}), do: {"(\"", "\")"}
  defp select_shape_for_capabilities(%{is_sink: true}), do: {"[\"", "\"]"}
  defp select_shape_for_capabilities(_), do: {"[\"", "\"]"}

  defp generate_edges(actors, trace, show_labels) do
    # Hybrid approach: use trace events for simulated actors, synthetic edges for real processes

    # First, try to extract edges from trace (works for simulated actors)
    trace_edges = extract_edges_from_trace(trace, actors, show_labels)

    # Then, generate synthetic edges for real processes that don't have trace events
    synthetic_edges = generate_synthetic_edges_from_stats(actors, show_labels)

    # Finally, fall back to definition-based edges for simulated actors without trace
    definition_edges = generate_definition_edges(actors, show_labels)

    # Combine all edge sources and deduplicate
    (trace_edges ++ synthetic_edges ++ definition_edges)
    |> Enum.uniq()
  end

  # Extract edges from actual message trace
  # This captures dynamic interactions not defined in static targets
  defp extract_edges_from_trace(nil, _actors, _show_labels), do: []
  defp extract_edges_from_trace([], _actors, _show_labels), do: []

  defp extract_edges_from_trace(trace, actors, show_labels) do
    # First, handle events with known senders (simulated actors)
    known_edges =
      trace
      |> Enum.filter(fn event ->
        # Only include edges between known actors (exclude self-loops if not meaningful)
        event.from != event.to &&
          event.from != :unknown &&
          Map.has_key?(actors, event.from) &&
          Map.has_key?(actors, event.to)
      end)
      |> Enum.group_by(fn event -> {event.from, event.to} end)
      |> Enum.map(fn {{from, to}, events} ->
        # Get the most common message type for this edge
        if show_labels do
          message_label = extract_trace_message_label(events)
          "#{from} -->|#{escape_mermaid_label(message_label)}| #{to}"
        else
          "#{from} --> #{to}"
        end
      end)

    # Then, handle events with unknown senders (real processes) by inferring connections
    inferred_edges =
      trace
      |> Enum.filter(fn event -> event.from == :unknown end)
      |> Enum.group_by(fn event -> event.to end)
      |> Enum.flat_map(fn {to, events} ->
        # Find potential senders based on message patterns
        find_potential_senders(events, actors, to, show_labels)
      end)

    known_edges ++ inferred_edges
  end

  # Infer potential senders for messages with unknown senders
  defp find_potential_senders(events, actors, to, show_labels) do
    # Get all other actors that could be senders
    potential_senders =
      actors
      |> Enum.reject(fn {name, _} -> name == to end)
      |> Enum.map(fn {name, _} -> name end)

    # For each potential sender, create an edge if the message pattern suggests it
    potential_senders
    |> Enum.flat_map(fn sender ->
      events
      |> Enum.map(fn event ->
        message_label = if show_labels, do: inspect(event.message), else: ""

        if show_labels do
          "#{sender} -->|#{escape_mermaid_label(message_label)}| #{to}"
        else
          "#{sender} --> #{to}"
        end
      end)
    end)
    |> Enum.uniq()
  end

  # Extract a representative label for an edge from trace events
  defp extract_trace_message_label(events) do
    # Count message types
    message_counts =
      events
      |> Enum.map(fn event -> inspect(event.message) end)
      |> Enum.frequencies()

    # Find the most frequent message
    {most_common_msg, count} = Enum.max_by(message_counts, fn {_msg, count} -> count end)

    if length(events) > count do
      # Multiple different messages on this edge
      "#{count}× #{most_common_msg}<br/>+#{length(events) - count} more"
    else
      # Single message type
      most_common_msg
    end
  end

  # Generate synthetic edges from stats when no trace is available
  # This is used for real processes that don't generate trace events
  defp generate_synthetic_edges_from_stats(actors, show_labels) do
    # Find all real processes that have activity
    real_processes =
      Enum.filter(actors, fn {_name, actor_info} ->
        actor_info.type == :real_process
      end)

    # Generate edges based on actual message patterns we can infer
    # For quiescence batching example: sender -> receiver with {:msg, i}, receiver -> sender with {:batch, list}
    real_processes
    |> Enum.flat_map(fn {from_name, from_info} ->
      real_processes
      |> Enum.reject(fn {to_name, _to_info} -> from_name == to_name end)
      |> Enum.map(fn {to_name, to_info} ->
        # Try to infer message direction and type from actor names and behavior
        message_label = infer_message_label(from_name, to_name, from_info, to_info)

        if show_labels do
          "#{from_name} -->|#{escape_mermaid_label(message_label)}| #{to_name}"
        else
          "#{from_name} --> #{to_name}"
        end
      end)
    end)
    |> Enum.uniq()
  end

  # Infer message labels from actor names and behavior patterns
  defp infer_message_label(from_name, to_name, _from_info, _to_info) do
    cond do
      # Common patterns in actor simulations
      String.contains?(to_string(from_name), "sender") and
          String.contains?(to_string(to_name), "receiver") ->
        ":msg"

      String.contains?(to_string(from_name), "receiver") and
          String.contains?(to_string(to_name), "sender") ->
        ":batch"

      String.contains?(to_string(from_name), "producer") and
          String.contains?(to_string(to_name), "consumer") ->
        ":data"

      String.contains?(to_string(from_name), "consumer") and
          String.contains?(to_string(to_name), "producer") ->
        ":ack"

      # Default to a generic message
      true ->
        ":message"
    end
  end

  # Generate edges from actor definitions (for simulated actors with targets)
  defp generate_definition_edges(actors, show_labels) do
    Enum.flat_map(actors, fn {name, actor_info} ->
      case actor_info.type do
        :simulated ->
          definition = actor_info.definition
          targets = definition.targets || []
          Enum.map(targets, &generate_definition_edge(name, &1, definition, show_labels))

        :real_process ->
          # Real processes don't have definition-based targets
          []
      end
    end)
  end

  defp generate_definition_edge(name, target, definition, show_labels) do
    if show_labels do
      msg_label = get_message_label(definition)

      if msg_label do
        escaped_label = escape_mermaid_label(msg_label)
        "#{name} -->|#{escaped_label}| #{target}"
      else
        "#{name} --> #{target}"
      end
    else
      "#{name} --> #{target}"
    end
  end

  # Escape special characters in Mermaid edge labels
  # Curly braces {} have special meaning in Mermaid and need to be escaped
  defp escape_mermaid_label(label) do
    label
    |> String.replace("{", "#123;")
    |> String.replace("}", "#125;")
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
          actor_stats = get_actor_stats(stats, name)
          style_for_activity(name, actor_stats)
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

  defp generate_html(mermaid_code, simulation, title, stats, model_source, generated_by) do
    actors = simulation.actors
    formatted_stats = Stats.format(stats)
    stats_table = generate_stats_table(formatted_stats)
    simulation_summary = generate_simulation_summary(simulation)

    model_source_section =
      if model_source, do: generate_model_source_section(model_source), else: ""

    generator_comment = GeneratorMetadata.to_html_comment(generated_by)

    """
    <!DOCTYPE html>
    <html>
    #{generator_comment}<head>
      <meta charset="utf-8">
      <title>#{title}</title>
      <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
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

        #{generate_dynamic_legend(actors, stats)}
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
    termination_reason = Map.get(simulation, :termination_reason)

    # Calculate speedup
    speedup =
      if real_time_elapsed > 0 do
        Float.round(actual_duration / real_time_elapsed, 1)
      else
        # Very fast execution - show ∞ instead of 0
        "∞"
      end

    termination_card =
      case {termination_reason, terminated_early} do
        {:condition, _} ->
          """
          <div class=\"summary-card success\">
            <div class=\"label\">Termination</div>
            <div class=\"value\">⚡ Early</div>
          </div>
          """

        {:quiescence, _} ->
          """
          <div class=\"summary-card\">
            <div class=\"label\">Termination</div>
            <div class=\"value\">✓ Quiescence</div>
          </div>
          """

        {:max_time, _} ->
          """
          <div class=\"summary-card warning\">
            <div class=\"label\">Termination</div>
            <div class=\"value\">⏱ Max Time</div>
          </div>
          """

        {nil, true} ->
          """
          <div class=\"summary-card success\">
            <div class=\"label\">Termination</div>
            <div class=\"value\">⚡ Early</div>
          </div>
          """

        _ ->
          """
          <div class=\"summary-card\">
            <div class=\"label\">Termination</div>
            <div class=\"value\">✓ Quiescence</div>
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

  defp generate_dynamic_legend(actors, stats) do
    actor_types = collect_actor_types(actors, stats)

    legend_nodes = build_legend_nodes(actor_types)

    if Enum.empty?(legend_nodes) do
      ""
    else
      legend_styles = build_legend_styles(actor_types)
      activity_legend = build_activity_legend(actors, stats)
      render_legend_html(legend_nodes, legend_styles, activity_legend)
    end
  end

  defp collect_actor_types(actors, stats) do
    Enum.reduce(actors, %{}, fn {name, actor_info}, acc ->
      actor_type = determine_actor_type(actor_info, name, stats)
      Map.put(acc, actor_type, true)
    end)
  end

  defp determine_actor_type(actor_info, name, stats) do
    case actor_info.type do
      :simulated -> determine_simulated_actor_type(actor_info.definition, name, stats)
      :real_process -> determine_real_process_actor_type(actor_info, name, stats)
    end
  end

  defp determine_simulated_actor_type(definition, name, stats) do
    actor_stats = get_actor_stats(stats, name)

    if actor_stats do
      determine_type_from_runtime_stats(actor_stats, definition)
    else
      determine_type_from_definition(definition)
    end
  end

  defp determine_type_from_runtime_stats(actor_stats, definition) do
    actual_sent = actor_stats.sent_count
    actual_received = actor_stats.received_count
    has_targets = length(definition.targets || []) > 0

    cond do
      actual_sent > 0 && actual_received > 0 && has_targets -> :processor
      actual_sent > 0 && actual_received == 0 -> :source
      actual_received > 0 && actual_sent == 0 -> :sink
      true -> determine_type_from_definition(definition)
    end
  end

  defp determine_type_from_definition(definition) do
    targets = definition.targets || []
    has_targets = length(targets) > 0
    can_receive = definition.on_receive != nil || definition.on_match != []
    can_send = definition.send_pattern != nil || (can_receive && has_targets)

    cond do
      can_send && !can_receive -> :source
      can_receive && !has_targets -> :sink
      can_send && can_receive && has_targets -> :processor
      true -> :sink
    end
  end

  defp determine_real_process_actor_type(_actor_info, name, stats) do
    actor_stats = get_actor_stats(stats, name)

    has_stats = actor_stats != nil
    sent_count = if has_stats, do: actor_stats.sent_count, else: 0
    received_count = if has_stats, do: actor_stats.received_count, else: 0

    # Determine type purely based on actual message behavior from trace
    cond do
      # Source: sends but doesn't receive
      sent_count > 0 && received_count == 0 -> :source
      # Sink: receives but doesn't send
      received_count > 0 && sent_count == 0 -> :sink
      # Processor: both sends and receives
      sent_count > 0 && received_count > 0 -> :processor
      # Default to sink if no activity detected
      true -> :sink
    end
  end

  defp build_legend_nodes(actor_types) do
    []
    |> add_legend_node_if(actor_types, :source, "legend_source([\"Source<br/>(sends only)\"])")
    |> add_legend_node_if(
      actor_types,
      :processor,
      "legend_processor(\"Processor<br/>(send & receive)\")"
    )
    |> add_legend_node_if(actor_types, :sink, "legend_sink[\"Sink<br/>(receives only)\"]")
  end

  defp add_legend_node_if(nodes, actor_types, type, node_def) do
    if Map.get(actor_types, type), do: nodes ++ [node_def], else: nodes
  end

  defp build_legend_styles(actor_types) do
    # Use neutral colors for legend shapes to avoid confusion
    neutral_style = "fill:#ffffff,stroke:#666666,stroke-width:2px"

    []
    |> add_legend_style_if(
      actor_types,
      :source,
      "style legend_source #{neutral_style}"
    )
    |> add_legend_style_if(
      actor_types,
      :processor,
      "style legend_processor #{neutral_style}"
    )
    |> add_legend_style_if(actor_types, :sink, "style legend_sink #{neutral_style}")
  end

  defp add_legend_style_if(styles, actor_types, type, style_def) do
    if Map.get(actor_types, type), do: styles ++ [style_def], else: styles
  end

  defp build_activity_legend(actors, stats) do
    # Collect which activity levels are actually present in the diagram
    activity_levels =
      Enum.reduce(actors, MapSet.new(), fn {name, _actor_info}, acc ->
        actor_stats = get_actor_stats(stats, name)

        if actor_stats do
          total_activity = actor_stats.sent_count + actor_stats.received_count
          level = activity_level(total_activity)
          MapSet.put(acc, level)
        else
          acc
        end
      end)

    # Build legend items for each activity level present
    activity_levels
    |> Enum.sort_by(&activity_level_order/1)
    |> Enum.map(&activity_level_description/1)
  end

  defp activity_level(total_activity) do
    cond do
      total_activity == 0 -> :inactive
      total_activity < 10 -> :low
      total_activity < 50 -> :medium
      true -> :high
    end
  end

  defp activity_level_order(level) do
    case level do
      :inactive -> 0
      :low -> 1
      :medium -> 2
      :high -> 3
    end
  end

  defp activity_level_description(level) do
    case level do
      :inactive ->
        {"⚪ Inactive (0 msgs)", "fill:#f5f5f5,stroke:#9e9e9e"}

      :low ->
        {"🔵 Low Activity (<10 msgs)", "fill:#e3f2fd,stroke:#1976d2"}

      :medium ->
        {"🟢 Medium Activity (10-50 msgs)", "fill:#e8f5e9,stroke:#388e3c"}

      :high ->
        {"🟠 High Activity (>50 msgs)", "fill:#fff3e0,stroke:#f57c00,stroke-width:3px"}
    end
  end

  defp render_legend_html(legend_nodes, legend_styles, activity_legend) do
    mermaid_legend = """
    flowchart TD
        #{Enum.join(legend_nodes, "\n    ")}
        #{Enum.join(legend_styles, "\n    ")}
    """

    # Build activity legend nodes and styles
    activity_nodes_and_styles =
      if Enum.empty?(activity_legend) do
        ""
      else
        activity_items =
          activity_legend
          |> Enum.with_index()
          |> Enum.map(fn {{label, style}, idx} ->
            node_name = "activity_#{idx}"
            node_def = "#{node_name}[\"#{label}\"]"
            style_def = "style #{node_name} #{style}"
            {node_def, style_def}
          end)

        nodes = Enum.map(activity_items, fn {node, _} -> node end)
        styles = Enum.map(activity_items, fn {_, style} -> style end)

        activity_mermaid = """
        flowchart LR
            #{Enum.join(nodes, "\n    ")}
            #{Enum.join(styles, "\n    ")}
        """

        """
        <div style="margin-top: 20px;">
          <h3 style="color: #495057; font-size: 0.9em; margin-bottom: 8px;">Node Colors (Activity Level)</h3>
          <div>
            <div class="mermaid">
        #{activity_mermaid}
            </div>
          </div>
        </div>
        """
      end

    """
    <hr style="margin: 30px 0 20px 0; border: none; border-top: 1px solid #e9ecef;">
    <div style="margin-top: 20px;">
      <h3 style="color: #495057; font-size: 0.9em; margin-bottom: 8px;">Node Shapes (Actor Type)</h3>
       <div>
         <div class="mermaid">
    #{mermaid_legend}
        </div>
      </div>
    </div>
    #{activity_nodes_and_styles}
    """
  end
end
