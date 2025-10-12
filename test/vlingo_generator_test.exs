defmodule VlingoGeneratorTest do
  use ExUnit.Case, async: true
  doctest ActorSimulation.VlingoGenerator

  alias ActorSimulation
  alias ActorSimulation.VlingoGenerator

  describe "generate/2" do
    test "generates complete VLINGO XOOM project files" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "simple-actors",
          group_id: "com.example"
        )

      assert is_list(files)
      assert length(files) > 0

      filenames = Enum.map(files, fn {name, _content} -> name end)

      # Check essential files exist
      assert "pom.xml" in filenames
      assert "src/main/java/com/example/Main.java" in filenames
      assert ".github/workflows/ci.yml" in filenames
      assert "README.md" in filenames

      # Check actor protocol interfaces
      assert "src/main/java/com/example/SenderProtocol.java" in filenames
      assert "src/main/java/com/example/ReceiverProtocol.java" in filenames

      # Check actor implementations
      assert "src/main/java/com/example/SenderActor.java" in filenames
      assert "src/main/java/com/example/ReceiverActor.java" in filenames

      # Check test files
      assert "src/test/java/com/example/SenderActorTest.java" in filenames
      assert "src/test/java/com/example/ReceiverActorTest.java" in filenames
    end

    test "generates callback interfaces for custom behavior" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "workers",
          group_id: "com.test",
          enable_callbacks: true
        )

      filenames = Enum.map(files, fn {name, _content} -> name end)

      # Callback interfaces should be generated
      assert "src/main/java/com/test/WorkerCallbacks.java" in filenames
      assert "src/main/java/com/test/ConsumerCallbacks.java" in filenames

      # Callback implementations should be generated
      assert "src/main/java/com/test/WorkerCallbacksImpl.java" in filenames
      assert "src/main/java/com/test/ConsumerCallbacksImpl.java" in filenames
    end

    test "generates protocol interface with correct package" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.myapp"
        )

      {_name, protocol} =
        Enum.find(files, fn {name, _} ->
          name == "src/main/java/com/myapp/WorkerProtocol.java"
        end)

      assert protocol =~ "package com.myapp;"
      assert protocol =~ "public interface WorkerProtocol"
      assert protocol =~ "void tick();"
    end

    test "generates actor implementation with VLINGO XOOM imports" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:generator,
          send_pattern: {:periodic, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example"
        )

      {_name, actor} =
        Enum.find(files, fn {name, _} ->
          name == "src/main/java/com/example/GeneratorActor.java"
        end)

      assert actor =~ "package com.example;"
      assert actor =~ "import io.vlingo.xoom.actors.Actor;"
      assert actor =~ "import io.vlingo.xoom.common.Scheduled;"

      assert actor =~
               "public class GeneratorActor extends Actor implements GeneratorProtocol, Scheduled<Object>"

      assert actor =~ "scheduler().schedule"
    end

    test "generates periodic pattern using scheduled messages" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:generator,
          send_pattern: {:periodic, 100, :tick},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example"
        )

      {_name, actor} =
        Enum.find(files, fn {name, _} ->
          name == "src/main/java/com/example/GeneratorActor.java"
        end)

      assert actor =~ "scheduler().schedule"
      assert actor =~ "100L"
      assert actor =~ "intervalSignal"
    end

    test "generates Main.java with actor system setup" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:alice, targets: [:bob])
        |> ActorSimulation.add_actor(:bob)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example"
        )

      {_name, main} =
        Enum.find(files, fn {name, _} -> name == "src/main/java/com/example/Main.java" end)

      assert main =~ "package com.example;"
      assert main =~ "import io.vlingo.xoom.actors.World;"
      assert main =~ "public class Main"
      assert main =~ "World.startWithDefaults"
      assert main =~ "world.actorFor"
      assert main =~ "AliceProtocol"
      assert main =~ "BobProtocol"
    end

    test "generates pom.xml with VLINGO and JUnit 5 dependencies" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:alice, targets: [:bob])
        |> ActorSimulation.add_actor(:bob)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test-actors",
          group_id: "com.example",
          vlingo_version: "1.11.1"
        )

      {_name, pom} = Enum.find(files, fn {name, _} -> name == "pom.xml" end)

      assert pom =~ "<modelVersion>4.0.0</modelVersion>"
      assert pom =~ "<groupId>com.example</groupId>"
      assert pom =~ "<artifactId>test-actors</artifactId>"
      assert pom =~ "io.vlingo.xoom"
      assert pom =~ "xoom-actors"
      assert pom =~ "1.11.1"
      assert pom =~ "junit-jupiter"
      assert pom =~ "maven-surefire-plugin"
      assert pom =~ "maven-compiler-plugin"
    end

    test "generates CI pipeline for testing builds" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example"
        )

      {_name, ci} =
        Enum.find(files, fn {name, _} -> name == ".github/workflows/ci.yml" end)

      assert ci =~ "name: CI"
      assert ci =~ "ubuntu-latest"
      assert ci =~ "macos-latest"
      assert ci =~ "windows-latest"
      assert ci =~ "setup-java@v3"
      assert ci =~ "java-version:"
      assert ci =~ "mvn clean compile"
      assert ci =~ "mvn test"
      assert ci =~ "mvn package"
      assert ci =~ "publish-unit-test-result-action"
    end

    test "generates README with build instructions" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "my-actors",
          group_id: "com.example"
        )

      {_name, readme} = Enum.find(files, fn {name, _} -> name == "README.md" end)

      assert readme =~ "# my-actors"
      assert readme =~ "VLINGO XOOM"
      assert readme =~ "mvn clean compile"
      assert readme =~ "mvn test"
      assert readme =~ "mvn exec:java"
      assert readme =~ "Generated from ActorSimulation DSL"
    end

    test "generates JUnit 5 test classes" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :tick},
          targets: []
        )

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example"
        )

      {_name, test_file} =
        Enum.find(files, fn {name, _} ->
          name == "src/test/java/com/example/WorkerActorTest.java"
        end)

      assert test_file =~ "package com.example;"
      assert test_file =~ "import org.junit.jupiter.api.*;"
      assert test_file =~ "import io.vlingo.xoom.actors.World;"
      assert test_file =~ "public class WorkerActorTest"
      assert test_file =~ "@BeforeEach"
      assert test_file =~ "@AfterEach"
      assert test_file =~ "@Test"
      assert test_file =~ "testActorCreation"
      assert test_file =~ "testTickMessage"
    end

    test "pom.xml includes test plugins" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example"
        )

      {_name, pom} = Enum.find(files, fn {name, _} -> name == "pom.xml" end)

      assert pom =~ "maven-surefire-plugin"
      assert pom =~ "maven-compiler-plugin"
      assert pom =~ "exec-maven-plugin"
      assert pom =~ "<scope>test</scope>"
    end

    test "generates callback interface with multiple messages" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:worker,
          send_pattern: {:periodic, 100, :process_data},
          targets: []
        )

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example",
          enable_callbacks: true
        )

      {_name, callback} =
        Enum.find(files, fn {name, _} ->
          name == "src/main/java/com/example/WorkerCallbacks.java"
        end)

      assert callback =~ "public interface WorkerCallbacks"
      assert callback =~ "void onProcessData();"
    end

    test "uses custom VLINGO version when specified" do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example",
          vlingo_version: "1.10.0"
        )

      {_name, pom} = Enum.find(files, fn {name, _} -> name == "pom.xml" end)

      assert pom =~ "1.10.0"
    end

    test "handles burst send pattern" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:burst_sender,
          send_pattern: {:burst, 10, 1000, :batch},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example"
        )

      {_name, actor} =
        Enum.find(files, fn {name, _} ->
          name == "src/main/java/com/example/BurstSenderActor.java"
        end)

      assert actor =~ "scheduler().schedule"
      assert actor =~ "1000L"
    end
  end

  describe "write_to_directory/2" do
    setup do
      # Use a temporary directory
      temp_dir = Path.join([System.tmp_dir!(), "vlingo_test_#{:rand.uniform(1_000_000)}"])
      on_exit(fn -> File.rm_rf(temp_dir) end)
      {:ok, temp_dir: temp_dir}
    end

    test "writes all files to directory including subdirectories", %{temp_dir: temp_dir} do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:node)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example"
        )

      :ok = VlingoGenerator.write_to_directory(files, temp_dir)

      assert File.dir?(temp_dir)

      # Check that subdirectories were created
      assert File.dir?(Path.join([temp_dir, "src", "main", "java", "com", "example"]))
      assert File.dir?(Path.join([temp_dir, "src", "test", "java", "com", "example"]))
      assert File.dir?(Path.join([temp_dir, ".github", "workflows"]))

      Enum.each(files, fn {filename, content} ->
        file_path = Path.join(temp_dir, filename)
        assert File.exists?(file_path), "File #{filename} should exist"
        assert File.read!(file_path) == content
      end)
    end

    test "creates nested package directories as needed", %{temp_dir: temp_dir} do
      simulation = ActorSimulation.new() |> ActorSimulation.add_actor(:node)

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.mycompany.actors"
        )

      :ok = VlingoGenerator.write_to_directory(files, temp_dir)

      package_dir = Path.join([temp_dir, "src", "main", "java", "com", "mycompany", "actors"])
      assert File.dir?(package_dir)
    end

    test "generates self-message pattern with scheduler" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:timer,
          send_pattern: {:self_message, 500, :timeout},
          targets: []
        )

      {:ok, files} =
        VlingoGenerator.generate(simulation,
          project_name: "test",
          group_id: "com.example"
        )

      {_name, actor} =
        Enum.find(files, fn {name, _} -> name == "src/main/java/com/example/TimerActor.java" end)

      # Should use scheduler for delayed self-message
      assert actor =~ "// Schedule one-shot self-message"
      assert actor =~ "scheduler().scheduleOnce"
      assert actor =~ "500L"
    end
  end
end
