# Mermaid Flowchart Reports

GenServerVirtualTime can generate beautiful flowchart reports that visualize your actor system topology with embedded statistics. This feature complements the existing sequence diagrams by showing the overall system structure and message flow patterns.

## Overview

Flowchart reports show:
- **Actor topology** - Visual representation of your system structure
- **Message flows** - Arrows showing which actors communicate
- **Embedded statistics** - Message counts and rates directly on nodes
- **Activity-based styling** - Color coding based on message traffic
- **Performance metrics** - Virtual time speedup and simulation stats

Based on [Mermaid Flowchart Syntax](https://mermaid.js.org/syntax/flowchart.html).

## Quick Start

```elixir
# Create and run a simulation
simulation = ActorSimulation.new()
|> ActorSimulation.add_actor(:producer,
    send_pattern: {:rate, 100, :data},
    targets: [:consumer])
|> ActorSimulation.add_actor(:consumer)
|> ActorSimulation.run(duration: 5000)

# Generate flowchart report
html = ActorSimulation.generate_flowchart_report(simulation,
  title: "Producer-Consumer System")

File.write!("report.html", html)
```

Open `report.html` in your browser to see:
- Interactive Mermaid flowchart
- Statistics table with message counts and rates
- Simulation summary with timing metrics
- Activity-based color coding

## Options

```elixir
ActorSimulation.generate_flowchart_report(simulation,
  title: "My System",              # Report title
  layout: "TB",                     # Direction: TB, LR, RL, BT
  show_stats_on_nodes: true,        # Show stats on nodes
  show_message_labels: true,        # Show message types on edges
  style_by_activity: true           # Color code by activity
)
```

### Layout Directions

- `"TB"` (Top to Bottom) - Default, vertical layout
- `"LR"` (Left to Right) - Horizontal layout
- `"RL"` (Right to Left) - Horizontal, reversed
- `"BT"` (Bottom to Top) - Vertical, reversed

## Node Shapes

Actors are automatically assigned shapes based on their behavior:

| Shape | Behavior | Visual |
|-------|----------|--------|
| Stadium `([...])` | Source (sends only) | Rounded pill shape |
| Asymmetric `>...]` | Sink (receives only) | Trapezoid pointing right |
| Rounded `(...)` | Processor (send & receive) | Rounded rectangle |
| Rectangle `[...]` | Passive (no send pattern) | Square corners |
| Subroutine `[[...]]` | Real process | Double brackets |

## Color Coding

When `style_by_activity: true` (default), nodes are colored by message activity:

- **Gray** - Inactive (0 messages)
- **Light Blue** - Low activity (< 10 messages)
- **Green** - Medium activity (10-49 messages)
- **Orange** - High activity (50+ messages)
- **Blue** - Real processes (special indicator)

## Examples

### Pipeline System

```elixir
forward = fn msg, state ->
  {:send, [{state.next, msg}], state}
end

simulation = ActorSimulation.new()
|> ActorSimulation.add_actor(:source,
    send_pattern: {:periodic, 100, :request},
    targets: [:stage1])
|> ActorSimulation.add_actor(:stage1,
    on_receive: forward,
    initial_state: %{next: :stage2})
|> ActorSimulation.add_actor(:stage2,
    on_receive: forward,
    initial_state: %{next: :sink})
|> ActorSimulation.add_actor(:sink)
|> ActorSimulation.run(duration: 1000)

html = ActorSimulation.generate_flowchart_report(simulation,
  title: "Pipeline Processing",
  layout: "LR")  # Horizontal layout

File.write!("pipeline.html", html)
```

### Pub-Sub System

```elixir
simulation = ActorSimulation.new()
|> ActorSimulation.add_actor(:publisher,
    send_pattern: {:rate, 10, :event},
    targets: [:sub1, :sub2, :sub3])
|> ActorSimulation.add_actor(:sub1)
|> ActorSimulation.add_actor(:sub2)
|> ActorSimulation.add_actor(:sub3)
|> ActorSimulation.run(duration: 1000)

html = ActorSimulation.generate_flowchart_report(simulation,
  title: "Pub-Sub System",
  layout: "TB")  # Vertical layout

File.write!("pubsub.html", html)
```

### Load Balanced Workers

```elixir
simulation = ActorSimulation.new()
|> ActorSimulation.add_actor(:load_balancer,
    send_pattern: {:burst, 3, 200, :work},
    targets: [:worker1, :worker2, :worker3])
|> ActorSimulation.add_actor(:worker1,
    on_match: [
      {:work, fn s -> {:send, [{:collector, :result}], s} end}
    ])
|> ActorSimulation.add_actor(:worker2,
    on_match: [
      {:work, fn s -> {:send, [{:collector, :result}], s} end}
    ])
|> ActorSimulation.add_actor(:worker3,
    on_match: [
      {:work, fn s -> {:send, [{:collector, :result}], s} end}
    ])
|> ActorSimulation.add_actor(:collector)
|> ActorSimulation.run(duration: 1000)

html = ActorSimulation.generate_flowchart_report(simulation,
  title: "Load-Balanced System")

File.write!("loadbalanced.html", html)
```

## Writing Directly to File

```elixir
# Shortcut to write directly to file
{:ok, path} = ActorSimulation.write_flowchart_report(
  simulation,
  "my_report.html",
  title: "My System"
)

IO.puts("Report written to: #{path}")
```

## Generating Just the Mermaid Code

```elixir
# Get just the Mermaid flowchart code (no HTML wrapper)
mermaid = ActorSimulation.MermaidReportGenerator.generate_flowchart(simulation, %{
  layout: "LR",
  show_stats: true,
  show_labels: true,
  style_by_activity: true
})

IO.puts(mermaid)
# Output:
# flowchart LR
#     producer(["producer<br/>📤 Sent: 100<br/>📥 Recv: 0"])
#     consumer(["consumer<br/>📤 Sent: 0<br/>📥 Recv: 100"])
#     producer -->|:data<br/>every 10ms| consumer
#     style producer fill:#e8f5e9,stroke:#388e3c
#     style consumer fill:#e8f5e9,stroke:#388e3c
```

## Report Components

Each HTML report includes:

### 1. Simulation Summary
- Virtual time duration
- Real time elapsed
- Speedup calculation (virtual time / real time)
- Termination status (normal or early)

### 2. Actor Topology Flowchart
- Interactive Mermaid diagram
- Nodes with embedded statistics
- Edges showing message flows
- Activity-based color coding
- Shape legend

### 3. Detailed Statistics Table
- Per-actor message counts
- Send and receive rates (msg/s)
- Activity level badges
- Sortable columns

### 4. Summary Box
- Total message count
- Simulation duration
- Number of actors

## Live Examples

View live examples at:
- [Interactive Flowchart Reports](https://d-led.github.io/gen_server_virtual_time/examples/reports/)

Examples include:
- Pipeline processing
- Pub-sub systems
- Load-balanced workers
- Early termination scenarios
- Multiple layout directions

## Comparison with Sequence Diagrams

| Feature | Flowchart Reports | Sequence Diagrams |
|---------|------------------|-------------------|
| **Shows** | System topology | Message timeline |
| **Best for** | Architecture overview | Debugging interactions |
| **Statistics** | Embedded in nodes | Optional timestamps |
| **Time axis** | No | Yes |
| **Activity view** | Color coding | Message frequency |
| **Use case** | System design, documentation | Debugging, protocol analysis |

**Recommendation**: Use both! Flowcharts for architecture and statistics, sequence diagrams for detailed message flows.

## Integration with CI/CD

```elixir
# In your test suite
defmodule MySystemTest do
  use ExUnit.Case
  
  test "generates system report", %{tmp_dir: tmp_dir} do
    simulation = build_simulation()
    |> ActorSimulation.run(duration: 5000)
    
    report_path = Path.join(tmp_dir, "system_report.html")
    {:ok, _} = ActorSimulation.write_flowchart_report(
      simulation, 
      report_path,
      title: "System Test Report"
    )
    
    # Optionally upload to artifact storage
    upload_test_artifact(report_path)
  end
end
```

## Customization

For advanced customization, use the `MermaidReportGenerator` module directly:

```elixir
alias ActorSimulation.MermaidReportGenerator

# Custom options
html = MermaidReportGenerator.generate_report(simulation, 
  title: "Custom Report",
  show_stats_on_nodes: false,  # Hide stats from nodes
  show_message_labels: false,  # Hide message details
  layout: "RL",
  style_by_activity: false     # No color coding
)
```

## API Reference

See full API documentation:
- `ActorSimulation.generate_flowchart_report/2`
- `ActorSimulation.write_flowchart_report/3`
- `ActorSimulation.MermaidReportGenerator`

## Learn More

- [Mermaid Flowchart Syntax](https://mermaid.js.org/syntax/flowchart.html)
- [ActorSimulation Documentation](./README.md)
- [Sequence Diagrams Guide](./sequence_diagrams.md)
- [Live Examples](https://d-led.github.io/gen_server_virtual_time/examples/)

