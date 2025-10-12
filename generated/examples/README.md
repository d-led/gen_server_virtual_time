# GenServerVirtualTime - Live Examples

This directory contains interactive HTML examples that demonstrate the visualization capabilities of GenServerVirtualTime.

## 📁 Structure

```
doc/examples/
├── index.html              # Main entry point for all examples
└── reports/
    ├── index.html          # Reports & diagrams index
    ├── *_report.html       # Mermaid flowchart reports with statistics
    ├── mermaid_*.html      # Mermaid sequence diagrams
    ├── plantuml_*.html     # PlantUML sequence diagrams
    └── dining_*.html       # Dining philosophers examples
```

## 🚀 Publishing to GitHub Pages

These examples are automatically published to GitHub Pages. The structure is designed to work with GitHub Pages deployment from the `/doc` directory.

### Setup

1. Go to your GitHub repository settings
2. Navigate to **Pages** section
3. Set **Source** to: `Deploy from a branch`
4. Set **Branch** to: `main` (or your default branch)
5. Set **Folder** to: `/doc`
6. Click **Save**

### Access

Once deployed, the examples will be available at:
```
https://yourusername.github.io/gen_server_virtual_time/examples/
```

Or for this repository:
```
https://d-led.github.io/gen_server_virtual_time/examples/
```

## 🔄 Regenerating Examples

To regenerate all example reports:

```bash
# Run the test suite to generate HTML files
mix test test/mermaid_report_test.exs
mix test test/diagram_generation_test.exs

# Copy generated files to doc/examples/reports/
cp test/output/*_report.html doc/examples/reports/
cp test/output/mermaid_*.html doc/examples/reports/
cp test/output/plantuml_*.html doc/examples/reports/
cp test/output/dining_*.html doc/examples/reports/
```

## 📊 Example Types

### Mermaid Flowchart Reports (NEW!)
- **Pipeline Processing** - Multi-stage data processing with forwarding
- **Pub-Sub System** - Publisher broadcasting to multiple subscribers
- **Load-Balanced Workers** - Work distribution with result collection
- **Custom Termination Condition** - Simulations that stop when goals are achieved
- **Multiple Layouts** - TB, LR, RL, BT directional layouts

Features:
- Actor topology visualization
- Embedded statistics (message counts, rates)
- Activity-based color coding
- Detailed statistics tables
- Virtual time speedup metrics

### Mermaid Sequence Diagrams
- **Request-Response** - Simple client-server interactions
- **Authentication Pipeline** - Multi-stage authentication flow
- **Sync vs Async** - Different message types with arrow styles
- **Timestamped Timeline** - Virtual time progression

### PlantUML Sequence Diagrams
- **Alice and Bob** - Basic two-actor conversation
- **Pub-Sub Pattern** - Publisher with multiple subscribers

### Dining Philosophers
Classic concurrency problem with:
- 2, 3, 5 philosopher configurations
- Fixed duration vs. early termination variants
- Deadlock-free message passing

## 🛠️ Customization

You can customize the examples by:

1. Modifying simulation parameters in test files
2. Adjusting report options (layout, styling, etc.)
3. Adding new simulation scenarios
4. Creating custom visualization templates

## 📚 Learn More

- [Main Documentation](https://hexdocs.pm/gen_server_virtual_time)
- [GitHub Repository](https://github.com/d-led/gen_server_virtual_time)
- [Hex Package](https://hex.pm/packages/gen_server_virtual_time)

## 📝 License

These examples are part of GenServerVirtualTime and share the same license.

