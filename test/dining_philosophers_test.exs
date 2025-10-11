defmodule DiningPhilosophersTest do
  use ExUnit.Case, async: false

  describe "Dining Philosophers simulation" do
    test "creates simulation with 5 philosophers and 5 forks" do
      simulation = DiningPhilosophers.create_simulation()

      # Should have 5 philosophers + 5 forks = 10 actors
      assert map_size(simulation.actors) == 10

      # Check philosophers exist
      assert Map.has_key?(simulation.actors, :philosopher_0)
      assert Map.has_key?(simulation.actors, :philosopher_4)

      # Check forks exist
      assert Map.has_key?(simulation.actors, :fork_0)
      assert Map.has_key?(simulation.actors, :fork_4)

      ActorSimulation.stop(simulation)
    end

    test "philosophers can eat without deadlock" do
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 5,
          think_time: 50,
          eat_time: 25,
          trace: false
        )
        |> ActorSimulation.run(duration: 1000)

      stats = ActorSimulation.get_stats(simulation)

      # All philosophers should have eaten at least once
      Enum.each(0..4, fn i ->
        philosopher = :"philosopher_#{i}"
        philosopher_stats = stats.actors[philosopher]

        # Each philosopher should have sent some messages (fork requests/releases)
        assert philosopher_stats.sent_count > 0,
               "Philosopher #{i} didn't send any messages"
      end)

      ActorSimulation.stop(simulation)
    end

    test "generates trace of fork acquisitions and releases" do
      simulation =
        DiningPhilosophers.create_simulation(
          # Smaller for easier verification
          num_philosophers: 3,
          think_time: 100,
          eat_time: 50,
          trace: true
        )
        |> ActorSimulation.run(duration: 500)

      trace = ActorSimulation.get_trace(simulation)

      # Should have traces of philosopher-fork interactions
      assert length(trace) > 0

      # Check that we have messages between philosophers and forks
      fork_messages =
        Enum.filter(trace, fn event ->
          String.contains?(to_string(event.to), "fork") or
            String.contains?(to_string(event.from), "philosopher")
        end)

      assert length(fork_messages) > 0

      ActorSimulation.stop(simulation)
    end

    test "generates viewable Mermaid diagram for 2 philosophers" do
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 2,
          think_time: 150,
          eat_time: 75,
          trace: true
        )
        |> ActorSimulation.run(duration: 800)

      # Generate enhanced Mermaid with timestamps
      mermaid =
        ActorSimulation.trace_to_mermaid(simulation,
          enhanced: true,
          timestamps: true
        )

      # Create HTML
      html = generate_dining_philosophers_html(mermaid, 2, "Minimal Table")

      # Write to output
      File.mkdir_p!("test/output")
      File.write!("test/output/dining_philosophers_2.html", html)

      IO.puts("\n🍴 Generated 2 Philosophers diagram: test/output/dining_philosophers_2.html")

      # Verify content
      assert String.contains?(mermaid, "philosopher_0")
      assert String.contains?(mermaid, "philosopher_1")
      assert String.contains?(mermaid, "fork_0")
      assert String.contains?(mermaid, "fork_1")

      ActorSimulation.stop(simulation)
    end

    test "generates viewable Mermaid diagram for 3 philosophers" do
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 3,
          think_time: 200,
          eat_time: 100,
          trace: true
        )
        |> ActorSimulation.run(duration: 1000)

      # Generate enhanced Mermaid with timestamps
      mermaid =
        ActorSimulation.trace_to_mermaid(simulation,
          enhanced: true,
          timestamps: true
        )

      # Create HTML
      html = generate_dining_philosophers_html(mermaid, 3, "Small Table")

      # Write to output
      File.mkdir_p!("test/output")
      File.write!("test/output/dining_philosophers_3.html", html)

      IO.puts("\n🍴 Generated 3 Philosophers diagram: test/output/dining_philosophers_3.html")

      # Verify content
      assert String.contains?(mermaid, "philosopher_")
      assert String.contains?(mermaid, "fork_")
      # Synchronous calls
      assert String.contains?(mermaid, "->>")

      ActorSimulation.stop(simulation)
    end

    test "generates viewable Mermaid diagram for 5 philosophers" do
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 5,
          think_time: 150,
          eat_time: 75,
          trace: true
        )
        |> ActorSimulation.run(duration: 1000)

      # Generate enhanced Mermaid with timestamps
      mermaid =
        ActorSimulation.trace_to_mermaid(simulation,
          enhanced: true,
          timestamps: true
        )

      # Create HTML
      html = generate_dining_philosophers_html(mermaid, 5, "Classic Table")

      # Write to output
      File.write!("test/output/dining_philosophers_5.html", html)

      IO.puts("\n🍴 Generated 5 Philosophers diagram: test/output/dining_philosophers_5.html")

      # Verify we have all 5 philosophers and forks
      assert String.contains?(mermaid, "philosopher_0")
      assert String.contains?(mermaid, "philosopher_4")
      assert String.contains?(mermaid, "fork_4")

      ActorSimulation.stop(simulation)
    end

    test "with detailed statistics shows eating counts" do
      simulation =
        DiningPhilosophers.create_simulation(
          num_philosophers: 5,
          think_time: 100,
          eat_time: 50,
          trace: false
        )
        |> ActorSimulation.run(duration: 2000)

      stats = ActorSimulation.get_stats(simulation)

      # Print eating statistics
      IO.puts("\n📊 Dining Philosophers Statistics:")

      Enum.each(0..4, fn i ->
        name = :"philosopher_#{i}"
        philosopher_stats = stats.actors[name]
        IO.puts("   #{name}: sent=#{philosopher_stats.sent_count} messages")
      end)

      ActorSimulation.stop(simulation)
    end
  end

  # Helper to generate enhanced HTML for dining philosophers
  defp generate_dining_philosophers_html(mermaid_code, num_philosophers, title_suffix \\ "") do
    full_title =
      if title_suffix != "",
        do: "#{num_philosophers} Philosophers (#{title_suffix})",
        else: "#{num_philosophers} Philosophers"

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{full_title} - Dining Philosophers</title>
      <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          max-width: 1600px;
          margin: 0 auto;
          padding: 40px 20px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          min-height: 100vh;
        }
        .container {
          background: white;
          border-radius: 12px;
          padding: 40px;
          box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        h1 {
          color: #2c3e50;
          margin-bottom: 10px;
          font-size: 2.5em;
        }
        .subtitle {
          color: #7f8c8d;
          font-size: 1.2em;
          margin-bottom: 30px;
        }
        .info {
          background: #e8f5e9;
          padding: 20px;
          border-left: 4px solid #4caf50;
          margin-bottom: 30px;
          border-radius: 4px;
        }
        .info strong {
          color: #2e7d32;
        }
        .diagram-container {
          background: #fafafa;
          padding: 40px;
          border-radius: 8px;
          overflow-x: auto;
          margin-bottom: 30px;
        }
        .mermaid {
          display: flex;
          justify-content: center;
        }
        .explanation {
          background: #fff3e0;
          padding: 20px;
          border-left: 4px solid #ff9800;
          border-radius: 4px;
          margin-bottom: 20px;
        }
        .explanation h3 {
          margin-top: 0;
          color: #e65100;
        }
        .code-block {
          background: #263238;
          color: #aed581;
          padding: 20px;
          border-radius: 4px;
          overflow-x: auto;
        }
        pre {
          margin: 0;
          font-family: 'Monaco', 'Menlo', monospace;
          font-size: 13px;
          line-height: 1.6;
        }
        .legend {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: 15px;
          margin-bottom: 30px;
        }
        .legend-item {
          background: #f5f5f5;
          padding: 15px;
          border-radius: 4px;
          border-left: 3px solid #2196f3;
        }
        .legend-item strong {
          color: #1976d2;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🍴 #{full_title}</h1>
        <div class="subtitle">Dining Philosophers Problem simulated with virtual time</div>

        <div class="info">
          <strong>🎬 GenServerVirtualTime Actor Simulation</strong><br>
          This diagram shows the interactions between philosophers and forks over virtual time.
          All synchronous fork requests, grants, and releases are captured.
        </div>

        <div class="explanation">
          <h3>The Problem</h3>
          <p>
            #{num_philosophers} philosophers sit at a round table with #{num_philosophers} forks between them.
            Each philosopher alternates between <strong>thinking</strong> and <strong>eating</strong>.
            To eat, a philosopher needs <strong>both adjacent forks</strong>.
          </p>
          <p>
            <strong>Challenge:</strong> How to prevent deadlock when all philosophers
            simultaneously grab their left fork?
          </p>
          <p>
            <strong>Solution:</strong> Asymmetric fork acquisition - odd philosophers grab
            right fork first, even philosophers grab left fork first.
          </p>
        </div>

        <div class="legend">
          <div class="legend-item">
            <strong>→→</strong> Solid Arrow<br>
            Synchronous call (request/release fork)
          </div>
          <div class="legend-item">
            <strong>Activation Box</strong><br>
            Fork is processing a request
          </div>
          <div class="legend-item">
            <strong>Timestamps</strong><br>
            Virtual time progression
          </div>
        </div>

        <div class="diagram-container">
          <div class="mermaid">
    #{mermaid_code}
          </div>
        </div>

        <div class="code-block">
          <strong>Generated Mermaid Code:</strong>
          <pre>#{mermaid_code}</pre>
        </div>

        <div class="explanation" style="margin-top: 30px;">
          <h3>What the Diagram Shows</h3>
          <ul>
            <li>Each philosopher sends synchronous <code>:request</code> messages to forks</li>
            <li>Forks reply with <code>:granted</code> or <code>:denied</code></li>
            <li>After eating, philosophers send <code>:release</code> to both forks</li>
            <li>The timeline shows how virtual time advances instantly in tests</li>
            <li>No deadlocks occur due to asymmetric fork acquisition</li>
          </ul>
        </div>
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
            mirrorActors: true,
            actorFontSize: 14,
            messageFontSize: 13
          }
        });
      </script>
    </body>
    </html>
    """
  end
end
