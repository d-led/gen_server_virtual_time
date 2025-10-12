# Generated Sequence Diagrams

This directory contains automatically generated sequence diagrams from the test suite.

## 📋 View the Diagrams

**👉 Open [`index.html`](index.html) in your browser to browse all diagrams!**

## 🎬 What's Inside

### Mermaid Diagrams
- **[mermaid_simple.html](mermaid_simple.html)** - Simple request-response pattern
- **[mermaid_pipeline.html](mermaid_pipeline.html)** - Multi-stage authentication pipeline
- **[mermaid_sync_async.html](mermaid_sync_async.html)** - Synchronous vs asynchronous communication
- **[mermaid_with_timestamps.html](mermaid_with_timestamps.html)** - Timeline with virtual time annotations

### PlantUML Diagrams
- **[plantuml_simple.html](plantuml_simple.html)** - Alice and Bob conversation
- **[plantuml_pubsub.html](plantuml_pubsub.html)** - Pub-sub pattern with multiple subscribers

## 🎨 Enhanced Mermaid Features

Based on the [Mermaid sequence diagram documentation](https://docs.mermaidchart.com/mermaid-oss/syntax/sequenceDiagram.html), our generated diagrams use:

- **Different arrow types**:
  - `->>`  Solid arrows for synchronous calls (`:call`)
  - `-->>` Dotted arrows for asynchronous casts (`:cast`)
- **Activation boxes** showing when actors are processing
- **Timestamp notes** showing virtual time progression
- **Self-contained HTML** with CDN-based MermaidJS rendering

## 🔄 Regenerating Diagrams

### Running Diagram Generation Tests

**⚠️ Important for Contributors:** Diagram generation tests are **excluded by default** to avoid generating HTML files on every test run. 

You should run them if you:
- Change any diagram generator code (`ActorSimulation.trace_to_mermaid`, `trace_to_plantuml`, etc.)
- Modify the simulation framework that affects trace output
- Update diagram HTML templates
- Want to preview diagrams before building documentation

### How to Run

Run all diagram generation tests:

```bash
mix test --include diagram_generation
```

Or run specific test files:

```bash
mix test test/diagram_generation_test.exs
mix test test/dining_philosophers_test.exs
mix test test/termination_indicator_test.exs
```

### Automatic Generation in CI

These tests run automatically in the CI pipeline's `docs` job before building documentation, ensuring diagrams are always up-to-date for releases.

## 📖 Features Demonstrated

### Virtual Time Progression
The timestamp diagrams show how virtual time advances instantly in tests, allowing you to simulate hours of behavior in milliseconds.

### Message Type Differentiation
The sync/async diagram clearly shows the difference between:
- Synchronous calls (solid arrows with activation)
- Asynchronous casts (dotted arrows)

### Complex Interactions
The pipeline diagram shows multi-actor request-response chains, demonstrating how messages flow through a system.

## 🌐 Viewing Online

Since these are self-contained HTML files with CDN resources:
1. Open any file directly in your browser
2. Or use a local server: `python3 -m http.server 8000`
3. Navigate to `http://localhost:8000/`

## 📚 More Information

See the main [README.md](../../README.md) for complete documentation on GenServerVirtualTime.

