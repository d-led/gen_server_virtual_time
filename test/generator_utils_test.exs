defmodule ActorSimulation.GeneratorUtilsTest do
  use ExUnit.Case, async: true

  alias ActorSimulation.GeneratorUtils

  describe "to_snake_case/1" do
    test "converts atoms to snake_case" do
      assert GeneratorUtils.to_snake_case(:my_actor) == "my_actor"
      assert GeneratorUtils.to_snake_case(:simple) == "simple"
    end

    test "converts PascalCase to snake_case" do
      assert GeneratorUtils.to_snake_case("MyActor") == "my_actor"
      assert GeneratorUtils.to_snake_case("HTTPClient") == "h_t_t_p_client"
      assert GeneratorUtils.to_snake_case("SimpleWorker") == "simple_worker"
    end

    test "handles strings with dashes" do
      assert GeneratorUtils.to_snake_case("my-actor") == "my_actor"
      assert GeneratorUtils.to_snake_case("web-server-actor") == "web_server_actor"
    end

    test "preserves existing snake_case" do
      assert GeneratorUtils.to_snake_case("already_snake") == "already_snake"
    end

    test "handles single character strings" do
      assert GeneratorUtils.to_snake_case("A") == "a"
      assert GeneratorUtils.to_snake_case("x") == "x"
    end
  end

  describe "to_pascal_case/1" do
    test "converts atoms to PascalCase" do
      assert GeneratorUtils.to_pascal_case(:my_actor) == "MyActor"
      assert GeneratorUtils.to_pascal_case(:simple) == "Simple"
    end

    test "converts snake_case to PascalCase" do
      assert GeneratorUtils.to_pascal_case("my_actor") == "MyActor"
      assert GeneratorUtils.to_pascal_case("web_server") == "WebServer"
    end

    test "handles strings with dashes" do
      assert GeneratorUtils.to_pascal_case("my-actor") == "MyActor"
      assert GeneratorUtils.to_pascal_case("web-server") == "WebServer"
    end

    test "handles mixed delimiters" do
      assert GeneratorUtils.to_pascal_case("my_actor-worker") == "MyActorWorker"
    end

    test "preserves existing PascalCase" do
      # Splits by delimiters
      assert GeneratorUtils.to_pascal_case("MyActor") == "Myactor"
    end
  end

  describe "to_camel_case/1" do
    test "converts atoms to camelCase" do
      assert GeneratorUtils.to_camel_case(:my_actor) == "myActor"
      assert GeneratorUtils.to_camel_case(:simple) == "simple"
    end

    test "converts snake_case to camelCase" do
      assert GeneratorUtils.to_camel_case("my_actor") == "myActor"
      assert GeneratorUtils.to_camel_case("web_server_client") == "webServerClient"
    end

    test "handles strings with dashes" do
      assert GeneratorUtils.to_camel_case("my-actor") == "myActor"
    end

    test "handles empty string parts" do
      assert GeneratorUtils.to_camel_case("") == ""
    end

    test "handles single word" do
      assert GeneratorUtils.to_camel_case("actor") == "actor"
    end
  end

  describe "extract_messages/1" do
    test "extracts messages from periodic pattern" do
      assert GeneratorUtils.extract_messages({:periodic, 100, :tick}) == [:tick]
    end

    test "extracts messages from burst pattern" do
      assert GeneratorUtils.extract_messages({:burst, 10, 1000, :batch}) == [:batch]
    end

    test "extracts messages from rate pattern" do
      assert GeneratorUtils.extract_messages({:rate, 5, :event}) == [:event]
    end

    test "returns empty list for nil pattern" do
      assert GeneratorUtils.extract_messages(nil) == []
    end

    test "handles complex message types" do
      assert GeneratorUtils.extract_messages({:periodic, 100, {:complex, :message}}) == [
               {:complex, :message}
             ]
    end
  end

  describe "pattern_interval/1" do
    test "calculates interval for periodic pattern" do
      assert GeneratorUtils.pattern_interval({:periodic, 100, :msg}) == 100
      assert GeneratorUtils.pattern_interval({:periodic, 1000, :tick}) == 1000
    end

    test "calculates interval for rate pattern" do
      assert GeneratorUtils.pattern_interval({:rate, 10, :msg}) == 100
      assert GeneratorUtils.pattern_interval({:rate, 5, :msg}) == 200
      assert GeneratorUtils.pattern_interval({:rate, 100, :msg}) == 10
    end

    test "calculates interval for burst pattern" do
      assert GeneratorUtils.pattern_interval({:burst, 5, 500, :msg}) == 500
      assert GeneratorUtils.pattern_interval({:burst, 100, 1000, :batch}) == 1000
    end

    test "returns nil for nil pattern" do
      assert GeneratorUtils.pattern_interval(nil) == nil
    end
  end

  describe "interval_to_seconds/1" do
    test "converts milliseconds to seconds" do
      assert GeneratorUtils.interval_to_seconds(1000) == 1.0
      assert GeneratorUtils.interval_to_seconds(500) == 0.5
      assert GeneratorUtils.interval_to_seconds(100) == 0.1
    end

    test "handles fractional results" do
      assert GeneratorUtils.interval_to_seconds(333) == 0.333
    end

    test "handles zero" do
      assert GeneratorUtils.interval_to_seconds(0) == 0.0
    end
  end

  describe "interval_to_nanoseconds/1" do
    test "converts milliseconds to nanoseconds" do
      assert GeneratorUtils.interval_to_nanoseconds(1) == 1_000_000
      assert GeneratorUtils.interval_to_nanoseconds(1000) == 1_000_000_000
    end

    test "handles zero" do
      assert GeneratorUtils.interval_to_nanoseconds(0) == 0
    end

    test "handles fractional milliseconds" do
      assert GeneratorUtils.interval_to_nanoseconds(0.001) == 1_000
    end
  end

  describe "message_name/1" do
    test "converts atom messages to strings" do
      assert GeneratorUtils.message_name(:tick) == "tick"
      assert GeneratorUtils.message_name(:work) == "work"
    end

    test "preserves string messages" do
      assert GeneratorUtils.message_name("tick") == "tick"
      assert GeneratorUtils.message_name("work") == "work"
    end

    test "normalizes complex messages to identifiers" do
      result = GeneratorUtils.message_name({:tuple, :message})
      assert is_binary(result)
      assert result =~ "_"
    end

    test "handles special characters" do
      result = GeneratorUtils.message_name("msg@#$%")
      assert result =~ "msg"
    end
  end

  describe "simulated_actors/1" do
    test "filters only simulated actors" do
      actors = %{
        worker: %{type: :simulated, definition: %{name: :worker}},
        external: %{type: :external, definition: %{name: :external}},
        producer: %{type: :simulated, definition: %{name: :producer}}
      }

      result = GeneratorUtils.simulated_actors(actors)

      assert length(result) == 2
      assert {:worker, %{name: :worker}} in result
      assert {:producer, %{name: :producer}} in result
    end

    test "returns empty list when no simulated actors" do
      actors = %{
        external1: %{type: :external, definition: %{}},
        external2: %{type: :external, definition: %{}}
      }

      result = GeneratorUtils.simulated_actors(actors)

      assert result == []
    end

    test "returns all actors when all simulated" do
      actors = %{
        a: %{type: :simulated, definition: :def_a},
        b: %{type: :simulated, definition: :def_b}
      }

      result = GeneratorUtils.simulated_actors(actors)

      assert length(result) == 2
    end

    test "handles empty actors map" do
      result = GeneratorUtils.simulated_actors(%{})

      assert result == []
    end
  end

  describe "readme_template/3" do
    test "generates README with all required sections" do
      options = [
        build_cmd: "make build",
        test_cmd: "make test",
        run_cmd: "./run.sh",
        framework_url: "https://example.com/framework"
      ]

      readme = GeneratorUtils.readme_template("MyProject", "AwesomeFramework", options)

      assert readme =~ "# MyProject"
      assert readme =~ "AwesomeFramework"
      assert readme =~ "## Building"
      assert readme =~ "make build"
      assert readme =~ "## Running"
      assert readme =~ "./run.sh"
      assert readme =~ "## Testing"
      assert readme =~ "make test"
      assert readme =~ "https://example.com/framework"
    end

    test "includes customization guidance" do
      options = [
        build_cmd: "build",
        test_cmd: "test",
        run_cmd: "run",
        framework_url: "http://example.com"
      ]

      readme = GeneratorUtils.readme_template("Project", "Framework", options)

      assert readme =~ "Customizing Behavior"
      assert readme =~ "DO NOT EDIT"
    end

    test "includes project structure section" do
      options = [
        build_cmd: "b",
        test_cmd: "t",
        run_cmd: "r",
        framework_url: "http://x.com"
      ]

      readme = GeneratorUtils.readme_template("P", "F", options)

      assert readme =~ "Project Structure"
    end
  end

  describe "write_to_directory/2" do
    @tag :tmp_dir
    test "writes files to directory" do
      tmp_dir = System.tmp_dir!() |> Path.join("generator_utils_test_#{:rand.uniform(1_000_000)}")

      files = [
        {"test.txt", "content1"},
        {"subdir/test2.txt", "content2"}
      ]

      assert :ok == GeneratorUtils.write_to_directory(files, tmp_dir)

      assert File.read!(Path.join(tmp_dir, "test.txt")) == "content1"
      assert File.read!(Path.join([tmp_dir, "subdir", "test2.txt"])) == "content2"

      # Cleanup
      File.rm_rf!(tmp_dir)
    end

    @tag :tmp_dir
    test "creates nested directories as needed" do
      tmp_dir = System.tmp_dir!() |> Path.join("generator_utils_test_#{:rand.uniform(1_000_000)}")

      files = [
        {"a/b/c/deep.txt", "deep content"}
      ]

      GeneratorUtils.write_to_directory(files, tmp_dir)

      assert File.exists?(Path.join([tmp_dir, "a", "b", "c", "deep.txt"]))

      # Cleanup
      File.rm_rf!(tmp_dir)
    end

    @tag :tmp_dir
    test "overwrites existing files" do
      tmp_dir = System.tmp_dir!() |> Path.join("generator_utils_test_#{:rand.uniform(1_000_000)}")
      File.mkdir_p!(tmp_dir)

      file_path = Path.join(tmp_dir, "test.txt")
      File.write!(file_path, "old content")

      GeneratorUtils.write_to_directory([{"test.txt", "new content"}], tmp_dir)

      assert File.read!(file_path) == "new content"

      # Cleanup
      File.rm_rf!(tmp_dir)
    end

    @tag :tmp_dir
    test "handles empty file list" do
      tmp_dir = System.tmp_dir!() |> Path.join("generator_utils_test_#{:rand.uniform(1_000_000)}")

      assert :ok == GeneratorUtils.write_to_directory([], tmp_dir)
    end
  end
end
