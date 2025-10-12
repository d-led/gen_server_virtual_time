defmodule PonyGeneratorTest do
  use ExUnit.Case, async: true
  doctest ActorSimulation.PonyGenerator

  alias ActorSimulation
  alias ActorSimulation.PonyGenerator

  describe "generate/2" do
    test "generates complete Pony project files" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} =
        PonyGenerator.generate(simulation,
          project_name: "simple_actors"
        )

      assert is_list(files)
      assert length(files) > 0

      filenames = Enum.map(files, fn {name, _content} -> name end)

      # Check essential files exist
      assert "main.pony" in filenames
      assert "sender.pony" in filenames
      assert "receiver.pony" in filenames
      assert "corral.json" in filenames
      assert "Makefile" in filenames
      assert ".github/workflows/ci.yml" in filenames
      assert "README.md" in filenames
    end

    test "generates callback traits for custom behavior" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} =
        PonyGenerator.generate(simulation,
          project_name: "workers",
          enable_callbacks: true
        )

      filenames = Enum.map(files, fn {name, _content} -> name end)

      # Callback traits should be generated
      assert "worker_callbacks.pony" in filenames
      assert "consumer_callbacks.pony" in filenames
    end

    test "generates Pony actor with behaviors" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} = PonyGenerator.generate(simulation, project_name: "test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "worker.pony" end)

      assert source =~ "actor Worker"
      assert source =~ "be tick()"
      assert source =~ "timers"
    end

    test "generates main.pony with actor system setup" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:alice, targets: [:bob])
        |> ActorSimulation.add_actor(:bob)

      {:ok, files} = PonyGenerator.generate(simulation, project_name: "test")

      {_name, main} = Enum.find(files, fn {name, _} -> name == "main.pony" end)

      assert main =~ "actor Main"
      assert main =~ "new create(env: Env)"
      assert main =~ "Alice"
      assert main =~ "Bob"
    end

    test "generates corral.json for dependencies" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = PonyGenerator.generate(simulation, project_name: "test")

      {_name, corral} = Enum.find(files, fn {name, _} -> name == "corral.json" end)

      assert corral =~ "\"info\""
      assert corral =~ "\"deps\""
    end

    test "generates Makefile for building" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = PonyGenerator.generate(simulation, project_name: "test_actors")

      {_name, makefile} = Enum.find(files, fn {name, _} -> name == "Makefile" end)

      assert makefile =~ "ponyc"
      assert makefile =~ "test"
      assert makefile =~ "clean"
    end

    test "generates CI pipeline for Pony" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = PonyGenerator.generate(simulation, project_name: "test")

      {_name, ci} = Enum.find(files, fn {name, _} -> name == ".github/workflows/ci.yml" end)

      assert ci =~ "name: CI"
      assert ci =~ "ubuntu-latest"
      assert ci =~ "ponyup"
      assert ci =~ "corral fetch"
      assert ci =~ "ponyc"
    end

    test "generates PonyTest tests" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} = PonyGenerator.generate(simulation, project_name: "test")

      {_name, test_file} = Enum.find(files, fn {name, _} -> name == "test/test.pony" end)

      assert test_file =~ "use \"ponytest\""
      assert test_file =~ "class iso _TestWorker is UnitTest"
      assert test_file =~ "fun name(): String => \"Worker actor\""
    end

    test "generates README with build instructions" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = PonyGenerator.generate(simulation, project_name: "MyActors")

      {_name, readme} = Enum.find(files, fn {name, _} -> name == "README.md" end)

      assert readme =~ "# MyActors"
      assert readme =~ "Pony"
      assert readme =~ "ponyup"
      assert readme =~ "corral"
      assert readme =~ "Generated from ActorSimulation DSL"
    end

    test "handles callback traits correctly" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:processor,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} =
        PonyGenerator.generate(simulation,
          project_name: "test",
          enable_callbacks: true
        )

      {_name, callbacks} =
        Enum.find(files, fn {name, _} -> name == "processor_callbacks.pony" end)

      assert callbacks =~ "trait ProcessorCallbacks"
      assert callbacks =~ "fun ref on_tick()"
    end
  end

  describe "write_to_directory/2" do
    setup do
      temp_dir = Path.join([System.tmp_dir!(), "pony_test_#{:rand.uniform(1000000)}"])
      on_exit(fn -> File.rm_rf(temp_dir) end)
      {:ok, temp_dir: temp_dir}
    end

    test "writes all files to directory including subdirectories", %{temp_dir: temp_dir} do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:node)

      {:ok, files} = PonyGenerator.generate(simulation, project_name: "test")

      :ok = PonyGenerator.write_to_directory(files, temp_dir)

      assert File.dir?(temp_dir)

      # Check that test subdirectory was created
      assert File.dir?(Path.join(temp_dir, "test"))

      Enum.each(files, fn {filename, content} ->
        file_path = Path.join(temp_dir, filename)
        assert File.exists?(file_path), "File #{filename} should exist"
        assert File.read!(file_path) == content
      end)
    end
  end
end

