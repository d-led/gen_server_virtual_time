defmodule PhonyGeneratorTest do
  use ExUnit.Case, async: true
  doctest ActorSimulation.PhonyGenerator

  alias ActorSimulation
  alias ActorSimulation.PhonyGenerator

  describe "generate/2" do
    test "generates complete Phony (Go) project files" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} =
        PhonyGenerator.generate(simulation,
          project_name: "simple_actors"
        )

      assert is_list(files)
      assert length(files) > 0

      filenames = Enum.map(files, fn {name, _content} -> name end)

      # Check essential files exist
      assert "main.go" in filenames
      assert "sender.go" in filenames
      assert "receiver.go" in filenames
      assert "go.mod" in filenames
      assert ".github/workflows/ci.yml" in filenames
      assert "README.md" in filenames
    end

    test "generates Go actor with Phony inbox" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} = PhonyGenerator.generate(simulation, project_name: "test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "worker.go" end)

      assert source =~ "type Worker struct"
      assert source =~ "phony.Inbox"
      assert source =~ "func (a *Worker) Actor()"
    end

    test "generates main.go with actor spawning" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:alice, targets: [:bob])
        |> ActorSimulation.add_actor(:bob)

      {:ok, files} = PhonyGenerator.generate(simulation, project_name: "test")

      {_name, main} = Enum.find(files, fn {name, _} -> name == "main.go" end)

      assert main =~ "package main"
      assert main =~ "import"
      assert main =~ "alice := &Alice"
      assert main =~ "bob := &Bob"
      assert main =~ ".Start()"
    end

    test "generates go.mod with Phony dependency" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = PhonyGenerator.generate(simulation, project_name: "test_actors")

      {_name, gomod} = Enum.find(files, fn {name, _} -> name == "go.mod" end)

      assert gomod =~ "module test_actors"
      assert gomod =~ "go 1.21"
      assert gomod =~ "github.com/Arceliar/phony"
    end

    test "generates CI pipeline for Go" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = PhonyGenerator.generate(simulation, project_name: "test")

      {_name, ci} = Enum.find(files, fn {name, _} -> name == ".github/workflows/ci.yml" end)

      assert ci =~ "name: CI"
      assert ci =~ "ubuntu-latest"
      assert ci =~ "actions/setup-go"
      assert ci =~ "go test"
      assert ci =~ "Run Demo Application"
    end

    test "generates Go test file" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} = PhonyGenerator.generate(simulation, project_name: "test")

      {_name, test_file} = Enum.find(files, fn {name, _} -> name == "actor_test.go" end)

      assert test_file =~ "package main"
      assert test_file =~ "testing"
      assert test_file =~ "func TestWorker"
    end

    test "generates README with build instructions" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = PhonyGenerator.generate(simulation, project_name: "MyActors")

      {_name, readme} = Enum.find(files, fn {name, _} -> name == "README.md" end)

      assert readme =~ "# MyActors"
      assert readme =~ "Phony"
      assert readme =~ "go build"
      assert readme =~ "Generated from ActorSimulation DSL"
    end

    test "handles periodic send pattern with time.Ticker" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:generator,
          send_pattern: {:periodic, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} = PhonyGenerator.generate(simulation, project_name: "test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "generator.go" end)

      assert source =~ "time.NewTicker"
      assert source =~ "100 * time.Millisecond"
    end

    test "supports callback interfaces for Go" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:processor,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} =
        PhonyGenerator.generate(simulation,
          project_name: "test",
          enable_callbacks: true
        )

      {_name, source} = Enum.find(files, fn {name, _} -> name == "processor.go" end)

      assert source =~ "type ProcessorCallbacks interface"
      assert source =~ "OnTick()"
    end

    test "generates self-message pattern with time.Sleep" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:timer,
          send_pattern: {:self_message, 500, :timeout},
          targets: []
        )

      {:ok, files} = PhonyGenerator.generate(simulation, project_name: "test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "timer.go" end)

      # Should use time.Sleep for delayed self-message
      assert source =~ "// One-shot delayed self-message"
      assert source =~ "time.Sleep(500 * time.Millisecond)"
      assert source =~ "a.Timeout()"
    end
  end

  describe "write_to_directory/2" do
    setup do
      temp_dir = Path.join([System.tmp_dir!(), "phony_test_#{:rand.uniform(1_000_000)}"])
      on_exit(fn -> File.rm_rf(temp_dir) end)
      {:ok, temp_dir: temp_dir}
    end

    test "writes all files to directory including subdirectories", %{temp_dir: temp_dir} do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:node)

      {:ok, files} = PhonyGenerator.generate(simulation, project_name: "test")

      :ok = PhonyGenerator.write_to_directory(files, temp_dir)

      assert File.dir?(temp_dir)
      assert File.dir?(Path.join(temp_dir, ".github/workflows"))

      Enum.each(files, fn {filename, content} ->
        file_path = Path.join(temp_dir, filename)
        assert File.exists?(file_path), "File #{filename} should exist"
        assert File.read!(file_path) == content
      end)
    end
  end
end
