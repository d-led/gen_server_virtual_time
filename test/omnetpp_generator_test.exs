defmodule OMNeTPPGeneratorTest do
  use ExUnit.Case, async: true
  doctest ActorSimulation.OMNeTPPGenerator

  alias ActorSimulation
  alias ActorSimulation.OMNeTPPGenerator

  describe "generate/2" do
    test "generates complete OMNeT++ project files" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} =
        OMNeTPPGenerator.generate(simulation,
          network_name: "SimpleNetwork",
          sim_time_limit: 10
        )

      assert is_list(files)
      assert length(files) > 0

      filenames = Enum.map(files, fn {name, _content} -> name end)

      # Check essential files exist
      assert "SimpleNetwork.ned" in filenames
      assert "Sender.h" in filenames
      assert "Sender.cc" in filenames
      assert "Receiver.h" in filenames
      assert "Receiver.cc" in filenames
      assert "CMakeLists.txt" in filenames
      assert "conanfile.txt" in filenames
      assert "omnetpp.ini" in filenames
    end

    test "generates NED file with correct network topology" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:client, targets: [:server])
        |> ActorSimulation.add_actor(:server)

      {:ok, files} =
        OMNeTPPGenerator.generate(simulation,
          network_name: "ClientServer"
        )

      {_name, ned_content} = Enum.find(files, fn {name, _} -> name == "ClientServer.ned" end)

      assert ned_content =~ "simple Client"
      assert ned_content =~ "simple Server"
      assert ned_content =~ "network ClientServer"
      assert ned_content =~ "client.out"
      assert ned_content =~ "server.in"
    end

    test "generates C++ header with correct class definition" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} = OMNeTPPGenerator.generate(simulation, network_name: "Test")

      {_name, header} = Enum.find(files, fn {name, _} -> name == "Worker.h" end)

      assert header =~ "#ifndef WORKER_H"
      assert header =~ "#define WORKER_H"
      assert header =~ "class Worker : public cSimpleModule"
      assert header =~ "void initialize()"
      assert header =~ "void handleMessage"
      assert header =~ "void finish()"
    end

    test "generates C++ source with periodic pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:generator,
          send_pattern: {:periodic, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} = OMNeTPPGenerator.generate(simulation, network_name: "Test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "Generator.cc" end)

      assert source =~ "Define_Module(Generator)"
      assert source =~ "void Generator::initialize()"
      assert source =~ "scheduleAt(simTime() + 0.1, selfMsg)"
      assert source =~ "void Generator::handleMessage"
    end

    test "generates C++ source with rate pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:rate, 50, :data},
          targets: [:processor]
        )
        |> ActorSimulation.add_actor(:processor)

      {:ok, files} = OMNeTPPGenerator.generate(simulation, network_name: "Test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "Producer.cc" end)

      assert source =~ "scheduleAt(simTime() + 0.02, selfMsg)"
    end

    test "generates C++ source with burst pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:burster,
          send_pattern: {:burst, 10, 1000, :batch},
          targets: [:processor]
        )
        |> ActorSimulation.add_actor(:processor)

      {:ok, files} = OMNeTPPGenerator.generate(simulation, network_name: "Test")

      {_name, source} = Enum.find(files, fn {name, _} -> name == "Burster.cc" end)

      assert source =~ "for (int i = 0; i < 1; i++)"
      assert source =~ "scheduleAt(simTime() + 1.0, selfMsg)"
    end

    test "generates CMakeLists.txt with all source files" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:alice, targets: [:bob])
        |> ActorSimulation.add_actor(:bob)

      {:ok, files} =
        OMNeTPPGenerator.generate(simulation,
          network_name: "TestNetwork"
        )

      {_name, cmake} = Enum.find(files, fn {name, _} -> name == "CMakeLists.txt" end)

      assert cmake =~ "cmake_minimum_required"
      assert cmake =~ "project(TestNetwork)"
      assert cmake =~ "Alice.cc"
      assert cmake =~ "Bob.cc"
      assert cmake =~ "find_package(OMNeT++ REQUIRED)"
    end

    test "generates conanfile.txt" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = OMNeTPPGenerator.generate(simulation, network_name: "Test")

      {_name, conan} = Enum.find(files, fn {name, _} -> name == "conanfile.txt" end)

      assert conan =~ "[requires]"
      assert conan =~ "[generators]"
    end

    test "generates omnetpp.ini with simulation config" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} =
        OMNeTPPGenerator.generate(simulation,
          network_name: "MyNetwork",
          sim_time_limit: 42
        )

      {_name, ini} = Enum.find(files, fn {name, _} -> name == "omnetpp.ini" end)

      assert ini =~ "network = MyNetwork"
      assert ini =~ "sim-time-limit = 42"
    end

    test "handles multiple targets correctly" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:publisher,
          targets: [:sub1, :sub2, :sub3]
        )
        |> ActorSimulation.add_actor(:sub1)
        |> ActorSimulation.add_actor(:sub2)
        |> ActorSimulation.add_actor(:sub3)

      {:ok, files} = OMNeTPPGenerator.generate(simulation, network_name: "PubSub")

      {_name, ned} = Enum.find(files, fn {name, _} -> name == "PubSub.ned" end)

      assert ned =~ "output out[3]"
    end
  end

  describe "write_to_directory/2" do
    setup do
      # Use a temporary directory
      temp_dir = Path.join([System.tmp_dir!(), "omnetpp_test_#{:rand.uniform(1_000_000)}"])
      on_exit(fn -> File.rm_rf(temp_dir) end)
      {:ok, temp_dir: temp_dir}
    end

    test "writes all files to directory", %{temp_dir: temp_dir} do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:node)

      {:ok, files} = OMNeTPPGenerator.generate(simulation, network_name: "Test")

      :ok = OMNeTPPGenerator.write_to_directory(files, temp_dir)

      assert File.dir?(temp_dir)

      Enum.each(files, fn {filename, content} ->
        file_path = Path.join(temp_dir, filename)
        assert File.exists?(file_path)
        assert File.read!(file_path) == content
      end)
    end

    test "creates directory if it doesn't exist", %{temp_dir: temp_dir} do
      subdir = Path.join(temp_dir, "nested/path")
      refute File.dir?(subdir)

      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} = OMNeTPPGenerator.generate(simulation, network_name: "Test")

      :ok = OMNeTPPGenerator.write_to_directory(files, subdir)

      assert File.dir?(subdir)
    end
  end
end
