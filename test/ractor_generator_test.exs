defmodule RactorGeneratorTest do
  use ExUnit.Case, async: true
  doctest ActorSimulation.RactorGenerator

  alias ActorSimulation
  alias ActorSimulation.RactorGenerator

  describe "generate/2" do
    test "generates complete Ractor (Rust) project files" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} =
        RactorGenerator.generate(simulation,
          project_name: "simple_actors"
        )

      assert is_list(files)
      assert length(files) > 0

      filenames = Enum.map(files, fn {name, _content} -> name end)

      # Check essential files exist
      assert "src/main.rs" in filenames
      assert "src/actors/sender.rs" in filenames
      assert "src/actors/receiver.rs" in filenames
      assert "src/actors/mod.rs" in filenames
      assert "Cargo.toml" in filenames
      assert ".github/workflows/ci.yml" in filenames
      assert "README.md" in filenames
    end

    test "generates Rust actor with Ractor traits" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "src/actors/worker.rs" end)

      assert source =~ "use ractor::"
      assert source =~ "pub struct Worker"
      assert source =~ "impl Actor for Worker"
      assert source =~ "async fn pre_start"
    end

    test "generates main.rs with actor spawning" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:alice, targets: [:bob])
        |> ActorSimulation.add_actor(:bob)

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      {_name, main} = Enum.find(files, fn {name, _} -> name == "src/main.rs" end)

      assert main =~ "use ractor::Actor"
      assert main =~ "#[tokio::main]"
      assert main =~ "async fn main"
      assert main =~ "Alice::spawn"
      assert main =~ "Bob::spawn"
    end

    test "generates Cargo.toml with Ractor dependency" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test_actors")

      {_name, cargo} = Enum.find(files, fn {name, _} -> name == "Cargo.toml" end)

      assert cargo =~ "name = \"test_actors\""
      assert cargo =~ "edition = \"2021\""
      assert cargo =~ "ractor = "
      assert cargo =~ "tokio = "
    end

    test "generates CI pipeline for Rust" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      {_name, ci} = Enum.find(files, fn {name, _} -> name == ".github/workflows/ci.yml" end)

      assert ci =~ "name: CI"
      assert ci =~ "ubuntu-latest"
      assert ci =~ "actions-rust-lang/setup-rust-toolchain"
      assert ci =~ "cargo test"
      assert ci =~ "cargo build --release"
    end

    test "generates Rust test file" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      {_name, test_file} =
        Enum.find(files, fn {name, _} -> name == "tests/integration_test.rs" end)

      assert test_file =~ "#[tokio::test]"
      assert test_file =~ "async fn test_worker"
    end

    test "generates README with build instructions" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "MyActors")

      {_name, readme} = Enum.find(files, fn {name, _} -> name == "README.md" end)

      assert readme =~ "# MyActors"
      assert readme =~ "Ractor"
      assert readme =~ "cargo build"
      assert readme =~ "Generated from ActorSimulation DSL"
    end

    test "handles periodic send pattern with tokio::time" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:generator,
          send_pattern: {:periodic, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "src/actors/generator.rs" end)

      assert source =~ "interval(Duration::from_millis(100))"
      assert source =~ "// Spawn periodic timer"
    end

    test "supports callback traits for Rust" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:processor,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} =
        RactorGenerator.generate(simulation,
          project_name: "test",
          enable_callbacks: true
        )

      {_name, source} = Enum.find(files, fn {name, _} -> name == "src/actors/processor.rs" end)

      assert source =~ "pub trait ProcessorCallbacks"
      assert source =~ "fn on_tick"
    end

    test "generates self-message pattern with tokio::time::sleep" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:timer,
          send_pattern: {:self_message, 500, :timeout},
          targets: []
        )

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "src/actors/timer.rs" end)

      # Should use sleep for delayed self-message
      assert source =~ "// One-shot delayed self-message"
      assert source =~ "sleep(Duration::from_millis(500))"
      assert source =~ "Timeout"
    end

    test "generates actors module file" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:alice)
        |> ActorSimulation.add_actor(:bob)

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      {_name, mod_file} = Enum.find(files, fn {name, _} -> name == "src/actors/mod.rs" end)

      assert mod_file =~ "pub mod alice;"
      assert mod_file =~ "pub mod bob;"
    end

    test "supports rate-based send pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:rate, 50, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "src/actors/producer.rs" end)

      # Rate of 50/sec = 20ms interval
      assert source =~ "Duration::from_millis(20)"
    end

    test "supports burst send pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:bursty,
          send_pattern: {:burst, 10, 500, :batch},
          targets: [:sink]
        )
        |> ActorSimulation.add_actor(:sink)

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "src/actors/bursty.rs" end)

      assert source =~ "for _ in 0..10"
      assert source =~ "Duration::from_millis(500)"
    end
  end

  describe "write_to_directory/2" do
    setup do
      temp_dir = Path.join([System.tmp_dir!(), "ractor_test_#{:rand.uniform(1_000_000)}"])
      on_exit(fn -> File.rm_rf(temp_dir) end)
      {:ok, temp_dir: temp_dir}
    end

    test "writes all files to directory including subdirectories", %{temp_dir: temp_dir} do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:node)

      {:ok, files} = RactorGenerator.generate(simulation, project_name: "test")

      :ok = RactorGenerator.write_to_directory(files, temp_dir)

      assert File.dir?(temp_dir)
      assert File.dir?(Path.join(temp_dir, "src/actors"))
      assert File.dir?(Path.join(temp_dir, ".github/workflows"))

      Enum.each(files, fn {filename, content} ->
        file_path = Path.join(temp_dir, filename)
        assert File.exists?(file_path), "File #{filename} should exist"
        assert File.read!(file_path) == content
      end)
    end
  end
end
