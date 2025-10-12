defmodule CAFGeneratorTest do
  use ExUnit.Case, async: true
  doctest ActorSimulation.CAFGenerator

  alias ActorSimulation
  alias ActorSimulation.CAFGenerator

  describe "generate/2" do
    test "generates complete CAF project files" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} =
        CAFGenerator.generate(simulation,
          project_name: "SimpleActors"
        )

      assert is_list(files)
      assert length(files) > 0

      filenames = Enum.map(files, fn {name, _content} -> name end)

      # Check essential files exist
      assert "main.cpp" in filenames
      assert "test_actors.cpp" in filenames
      assert "sender_actor.hpp" in filenames
      assert "sender_actor.cpp" in filenames
      assert "receiver_actor.hpp" in filenames
      assert "receiver_actor.cpp" in filenames
      assert "CMakeLists.txt" in filenames
      assert "conanfile.txt" in filenames
      assert ".github/workflows/ci.yml" in filenames
      assert "README.md" in filenames
    end

    test "generates callback interface for custom behavior" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} =
        CAFGenerator.generate(simulation,
          project_name: "Workers",
          enable_callbacks: true
        )

      filenames = Enum.map(files, fn {name, _content} -> name end)

      # Callback interface should be generated
      assert "worker_callbacks.hpp" in filenames
      assert "consumer_callbacks.hpp" in filenames

      # Example implementation should be generated
      assert "worker_callbacks_impl.cpp" in filenames
      assert "consumer_callbacks_impl.cpp" in filenames
    end

    test "generates C++ header with CAF actor class" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      {_name, header} = Enum.find(files, fn {name, _} -> name == "worker_actor.hpp" end)

      assert header =~ "#pragma once"
      assert header =~ "#include <caf/all.hpp>"
      assert header =~ "class worker_actor"
      assert header =~ "caf::behavior make_behavior()"
    end

    test "generates C++ source with periodic pattern using scheduled messages" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:generator,
          send_pattern: {:periodic, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "generator_actor.cpp" end)

      assert source =~ "make_behavior()"
      # CAF 1.0: Check for mail API instead of deprecated delayed_send
      assert source =~ "mail("
      assert source =~ ".delay(std::chrono::milliseconds(100))"
      assert source =~ ".send(this)"
    end

    test "generates main.cpp with actor system setup" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:alice, targets: [:bob])
        |> ActorSimulation.add_actor(:bob)

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      {_name, main} = Enum.find(files, fn {name, _} -> name == "main.cpp" end)

      assert main =~ "#include <caf/all.hpp>"
      assert main =~ "int caf_main"
      assert main =~ "actor_system"
      assert main =~ "spawn"
    end

    test "generates CMakeLists.txt with CAF dependencies" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:alice, targets: [:bob])
        |> ActorSimulation.add_actor(:bob)

      {:ok, files} =
        CAFGenerator.generate(simulation,
          project_name: "TestActors"
        )

      {_name, cmake} = Enum.find(files, fn {name, _} -> name == "CMakeLists.txt" end)

      assert cmake =~ "cmake_minimum_required"
      assert cmake =~ "project(TestActors"
      assert cmake =~ "find_package(CAF"
      assert cmake =~ "alice_actor.cpp"
      assert cmake =~ "bob_actor.cpp"
      assert cmake =~ "target_link_libraries"
      assert cmake =~ "CAF::core"
    end

    test "generates conanfile.txt with CAF and Catch2 packages" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      {_name, conan} = Enum.find(files, fn {name, _} -> name == "conanfile.txt" end)

      assert conan =~ "[requires]"
      assert conan =~ "caf/"
      assert conan =~ "catch2/"
      assert conan =~ "[generators]"
      assert conan =~ "CMakeDeps"
    end

    test "generates CI pipeline for testing builds" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      {_name, ci} = Enum.find(files, fn {name, _} -> name == ".github/workflows/ci.yml" end)

      assert ci =~ "name: CI"
      assert ci =~ "ubuntu-latest"
      assert ci =~ "macos-latest"
      assert ci =~ "conan install"
      assert ci =~ "cmake"
      assert ci =~ "make"
    end

    test "generates README with build instructions" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "MyActors")

      {_name, readme} = Enum.find(files, fn {name, _} -> name == "README.md" end)

      assert readme =~ "# MyActors"
      assert readme =~ "CAF"
      assert readme =~ "conan install"
      assert readme =~ "cmake"
      assert readme =~ "Generated from ActorSimulation DSL"
    end

    test "generates Catch2 test file" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      {_name, test_file} = Enum.find(files, fn {name, _} -> name == "test_actors.cpp" end)

      assert test_file =~ "#include <catch2/catch_test_macros.hpp>"
      assert test_file =~ "TEST_CASE"
      assert test_file =~ "REQUIRE"
      assert test_file =~ "worker_actor"
    end

    test "CMakeLists.txt includes test target" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      {_name, cmake} = Enum.find(files, fn {name, _} -> name == "CMakeLists.txt" end)

      assert cmake =~ "find_package(Catch2"
      assert cmake =~ "add_executable(Test_test"
      assert cmake =~ "Catch2::Catch2WithMain"
      assert cmake =~ "enable_testing()"
      assert cmake =~ "add_test"
    end

    test "generates self-message pattern with delayed_send" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:timer,
          send_pattern: {:self_message, 500, :timeout},
          targets: []
        )

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "timer_actor.cpp" end)
      {_name, header} = Enum.find(files, fn {name, _} -> name == "timer_actor.hpp" end)
      {_name, atoms} = Enum.find(files, fn {name, _} -> name == "atoms.hpp" end)

      # CAF 1.0: Check for shared atoms header with type ID block
      assert header =~ "#include \"atoms.hpp\""
      assert atoms =~ "CAF_BEGIN_TYPE_ID_BLOCK(ActorSimulation"
      assert atoms =~ "CAF_ADD_ATOM(ActorSimulation, timeout_atom)"
      assert atoms =~ "CAF_ADD_ATOM(ActorSimulation, event_atom)"
      assert atoms =~ "CAF_ADD_ATOM(ActorSimulation, msg_atom)"
      assert atoms =~ "CAF_END_TYPE_ID_BLOCK(ActorSimulation)"

      # CAF 1.0: Should use mail API instead of deprecated delayed_send
      assert source =~ "mail(timeout_atom_v).delay(std::chrono::milliseconds(500)).send(this)"
      assert source =~ "// CAF 1.0: Send message to self after delay (one-shot)"
      assert source =~ "timeout_atom_v"
      assert source =~ "[=](timeout_atom)"
    end
  end

  describe "write_to_directory/2" do
    setup do
      # Use a temporary directory
      temp_dir = Path.join([System.tmp_dir!(), "caf_test_#{:rand.uniform(1_000_000)}"])
      on_exit(fn -> File.rm_rf(temp_dir) end)
      {:ok, temp_dir: temp_dir}
    end

    test "writes all files to directory including subdirectories", %{temp_dir: temp_dir} do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:node)

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      :ok = CAFGenerator.write_to_directory(files, temp_dir)

      assert File.dir?(temp_dir)

      # Check that CI workflow subdirectory was created
      assert File.dir?(Path.join([temp_dir, ".github", "workflows"]))

      Enum.each(files, fn {filename, content} ->
        file_path = Path.join(temp_dir, filename)
        assert File.exists?(file_path), "File #{filename} should exist"
        assert File.read!(file_path) == content
      end)
    end

    test "creates nested directories as needed", %{temp_dir: temp_dir} do
      subdir = Path.join(temp_dir, "nested/deep/path")
      refute File.dir?(subdir)

      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = CAFGenerator.generate(simulation, project_name: "Test")

      :ok = CAFGenerator.write_to_directory(files, subdir)

      assert File.dir?(subdir)
    end
  end
end
