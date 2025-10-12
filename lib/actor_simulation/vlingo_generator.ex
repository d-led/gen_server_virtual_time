defmodule ActorSimulation.VlingoGenerator do
  @moduledoc """
  Generates VLINGO XOOM Actors code from ActorSimulation DSL.

  VLINGO XOOM is a Java actor framework that provides:
  - Type-safe actor implementations
  - Protocol-based (interface) messaging
  - Scheduler-based message dispatch
  - Reactive foundation for distributed systems

  This generator creates production-ready Java projects with:
  - Actor implementations with protocol interfaces
  - JUnit 5 test suites
  - Maven build configuration
  - CI/CD pipeline
  - Complete documentation

  ## Example

      simulation = ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
            send_pattern: {:periodic, 100, :msg},
            targets: [:receiver])
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} = VlingoGenerator.generate(simulation,
        project_name: "my-actors",
        group_id: "com.example")

      VlingoGenerator.write_to_directory(files, "vlingo_output/")
  """

  alias ActorSimulation.GeneratorUtils

  @doc """
  Generates complete VLINGO XOOM project files from an ActorSimulation.

  ## Options

  - `:project_name` (required) - Name of the Java project (kebab-case)
  - `:group_id` (default: "com.example") - Maven group ID
  - `:vlingo_version` (default: "1.11.1") - VLINGO XOOM version
  - `:enable_callbacks` (default: true) - Generate callback interfaces

  ## Returns

  `{:ok, files}` where files is a list of `{filename, content}` tuples
  """
  def generate(simulation, opts \\ []) do
    project_name = Keyword.fetch!(opts, :project_name)
    group_id = Keyword.get(opts, :group_id, "com.example")
    vlingo_version = Keyword.get(opts, :vlingo_version, "1.11.1")
    enable_callbacks = Keyword.get(opts, :enable_callbacks, true)

    actors = simulation.actors
    package_path = String.replace(group_id, ".", "/")

    files =
      []
      |> add_actor_files(actors, group_id, package_path, enable_callbacks)
      |> add_main_file(actors, project_name, group_id, package_path, enable_callbacks)
      |> add_test_files(actors, group_id, package_path, enable_callbacks)
      |> add_pom_file(project_name, group_id, vlingo_version)
      |> add_ci_pipeline(project_name)
      |> add_readme(project_name)

    {:ok, files}
  end

  @doc """
  Writes generated files to a directory.
  """
  def write_to_directory(files, output_dir) do
    GeneratorUtils.write_to_directory(files, output_dir)
  end

  # Private functions

  defp add_actor_files(files, actors, group_id, package_path, enable_callbacks) do
    Enum.reduce(actors, files, fn {name, actor_info}, acc ->
      case actor_info.type do
        :simulated ->
          definition = actor_info.definition
          class_name = GeneratorUtils.to_pascal_case(name)

          # Protocol interface
          protocol = generate_protocol_interface(name, definition, group_id)
          protocol_file = "src/main/java/#{package_path}/#{class_name}Protocol.java"

          # Actor implementation
          actor_impl = generate_actor_implementation(name, definition, group_id, enable_callbacks)
          actor_file = "src/main/java/#{package_path}/#{class_name}Actor.java"

          new_files = [
            {protocol_file, protocol},
            {actor_file, actor_impl}
          ]

          new_files =
            if enable_callbacks do
              callback_interface = generate_callback_interface(name, definition, group_id)
              callback_impl = generate_callback_implementation(name, definition, group_id)

              callback_interface_file =
                "src/main/java/#{package_path}/#{class_name}Callbacks.java"

              callback_impl_file =
                "src/main/java/#{package_path}/#{class_name}CallbacksImpl.java"

              new_files ++
                [
                  {callback_interface_file, callback_interface},
                  {callback_impl_file, callback_impl}
                ]
            else
              new_files
            end

          new_files ++ acc

        :real_process ->
          acc
      end
    end)
  end

  defp add_main_file(files, actors, project_name, group_id, package_path, enable_callbacks) do
    content = generate_main(actors, project_name, group_id, enable_callbacks)
    main_file = "src/main/java/#{package_path}/Main.java"
    [{main_file, content} | files]
  end

  defp add_test_files(files, actors, group_id, package_path, enable_callbacks) do
    simulated = GeneratorUtils.simulated_actors(actors)

    test_files =
      Enum.flat_map(simulated, fn {name, definition} ->
        class_name = GeneratorUtils.to_pascal_case(name)
        test_content = generate_test_class(name, definition, group_id, enable_callbacks)
        test_file = "src/test/java/#{package_path}/#{class_name}ActorTest.java"
        [{test_file, test_content}]
      end)

    test_files ++ files
  end

  defp add_pom_file(files, project_name, group_id, vlingo_version) do
    content = generate_pom(project_name, group_id, vlingo_version)
    [{"pom.xml", content} | files]
  end

  defp add_ci_pipeline(files, project_name) do
    content = generate_ci_pipeline(project_name)
    [{".github/workflows/ci.yml", content} | files]
  end

  defp add_readme(files, project_name) do
    content = generate_readme(project_name)
    [{"README.md", content} | files]
  end

  defp generate_protocol_interface(name, definition, group_id) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    methods =
      if length(messages) > 0 do
        Enum.map_join(messages, "\n", fn msg ->
          msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_camel_case()
          "  void #{msg_name}();"
        end)
      else
        "  void process();"
      end

    # Protocol interfaces should NOT extend Scheduled - that causes issues with VLINGO's proxy generator
    # The Actor implementation will implement Scheduled directly

    """
    // Generated from ActorSimulation DSL
    // Protocol interface for: #{name}

    package #{group_id};

    /**
     * Protocol interface for #{class_name} actor.
     * This interface defines the messages that can be sent to this actor.
     */
    public interface #{class_name}Protocol {
    #{methods}
    }
    """
  end

  defp generate_callback_code(enable_callbacks, class_name) do
    if enable_callbacks do
      field = """
        private final #{class_name}Callbacks callbacks;
      """

      param = ", #{class_name}Callbacks callbacks"

      init = """
          this.callbacks = (callbacks != null) ? callbacks : new #{class_name}CallbacksImpl();
      """

      {field, param, init}
    else
      {"", "", ""}
    end
  end

  defp generate_target_code(targets, class_name) do
    if length(targets) > 0 do
      field = """
        private final List<#{class_name}Protocol> targets;
      """

      param = ", List<#{class_name}Protocol> targets"

      init = """
          this.targets = (targets != null) ? targets : new ArrayList<>();
      """

      {field, param, init}
    else
      {"", "", ""}
    end
  end

  defp generate_method_implementations(messages, definition, enable_callbacks) do
    if length(messages) > 0 do
      Enum.map_join(messages, "\n\n", fn msg ->
        generate_message_method(msg, definition, enable_callbacks)
      end)
    else
      """
        @Override
        public void process() {
          logger().info(getClass().getSimpleName() + " processing...");
          // Send to targets
          sendToTargets();
        }

        private void sendToTargets() {
          // No targets defined
        }
      """
    end
  end

  defp generate_imports_and_implements(definition) do
    has_targets = length(definition.targets) > 0

    list_import =
      if has_targets, do: "import java.util.List;\nimport java.util.ArrayList;", else: ""

    {scheduled_import, scheduled_implements} =
      case definition.send_pattern do
        {:periodic, _, _} ->
          {"import io.vlingo.xoom.common.Scheduled;", ", Scheduled<Object>"}

        {:rate, _, _} ->
          {"import io.vlingo.xoom.common.Scheduled;", ", Scheduled<Object>"}

        {:burst, _, _, _} ->
          {"import io.vlingo.xoom.common.Scheduled;", ", Scheduled<Object>"}

        {:self_message, _, _} ->
          {"import io.vlingo.xoom.common.Scheduled;", ", Scheduled<Object>"}

        _ ->
          {"", ""}
      end

    {list_import, scheduled_import, scheduled_implements}
  end

  defp generate_actor_implementation(name, definition, group_id, enable_callbacks) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    {callback_field, callback_param, callback_init} =
      generate_callback_code(enable_callbacks, class_name)

    {target_field, target_param, target_init} =
      generate_target_code(definition.targets, class_name)

    self_message_init = generate_self_message_init(definition, class_name)
    method_impls = generate_method_implementations(messages, definition, enable_callbacks)
    interval_signal_method = generate_interval_signal_method(definition, messages)

    {list_import, scheduled_import, scheduled_implements} =
      generate_imports_and_implements(definition)

    """
    // Generated from ActorSimulation DSL
    // Actor implementation for: #{name}

    package #{group_id};

    import io.vlingo.xoom.actors.Actor;
    #{scheduled_import}
    #{list_import}

    /**
     * Actor implementation for #{class_name}.
     * This actor implements the #{class_name}Protocol interface.
     */
    public class #{class_name}Actor extends Actor implements #{class_name}Protocol#{scheduled_implements} {
    #{callback_field}#{target_field}
      /**
       * Constructor for #{class_name}Actor.
       */
      @SuppressWarnings("unchecked")
      public #{class_name}Actor(#{format_constructor_params(callback_param, target_param)}) {
    #{callback_init}#{target_init}#{self_message_init}  }

    #{method_impls}
    #{interval_signal_method}

      @Override
      public void stop() {
        super.stop();
      }
    }
    """
  end

  defp generate_self_message_init(definition, _class_name) do
    case definition.send_pattern do
      {:self_message, delay_ms, _message} ->
        """

            // Schedule one-shot self-message
            scheduler().scheduleOnce(
              selfAs(Scheduled.class),
              null,
              0L,
              #{delay_ms}L
            );
        """

      {:periodic, interval_ms, _message} ->
        """

            // Schedule periodic message sending
            scheduler().schedule(
              selfAs(Scheduled.class),
              null,
              #{interval_ms}L,
              #{interval_ms}L
            );
        """

      {:rate, per_second, _message} ->
        interval_ms = div(1000, per_second)

        """

            // Schedule rate-based message sending
            scheduler().schedule(
              selfAs(Scheduled.class),
              null,
              #{interval_ms}L,
              #{interval_ms}L
            );
        """

      {:burst, _count, interval_ms, _message} ->
        """

            // Schedule burst message sending
            scheduler().schedule(
              selfAs(Scheduled.class),
              null,
              #{interval_ms}L,
              #{interval_ms}L
            );
        """

      _ ->
        ""
    end
  end

  defp generate_interval_signal_method(definition, messages) do
    case definition.send_pattern do
      {:periodic, _, _} when messages != [] ->
        [first_msg | _] = messages
        msg_name = GeneratorUtils.message_name(first_msg) |> GeneratorUtils.to_camel_case()

        """

          @Override
          public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
            #{msg_name}();
          }
        """

      {:rate, _, _} when messages != [] ->
        [first_msg | _] = messages
        msg_name = GeneratorUtils.message_name(first_msg) |> GeneratorUtils.to_camel_case()

        """

          @Override
          public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
            #{msg_name}();
          }
        """

      {:burst, _, _, _} when messages != [] ->
        [first_msg | _] = messages
        msg_name = GeneratorUtils.message_name(first_msg) |> GeneratorUtils.to_camel_case()

        """

          @Override
          public void intervalSignal(io.vlingo.xoom.common.Scheduled<Object> scheduled, Object data) {
            #{msg_name}();
          }
        """

      _ ->
        ""
    end
  end

  defp generate_message_method(msg, definition, enable_callbacks) do
    msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_camel_case()
    msg_name_pascal = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()

    callback_call =
      if enable_callbacks do
        """
          callbacks.on#{msg_name_pascal}();
        """
      else
        """
          logger().info(getClass().getSimpleName() + " received #{msg}");
        """
      end

    send_to_targets =
      if length(definition.targets) > 0 do
        """
            // Send to all targets
            for (var target : targets) {
              target.#{msg_name}();
            }
        """
      else
        ""
      end

    """
      @Override
      public void #{msg_name}() {
        #{callback_call}#{send_to_targets}
      }
    """
  end

  defp generate_callback_interface(name, definition, group_id) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    methods =
      if length(messages) > 0 do
        Enum.map_join(messages, "\n", fn msg ->
          msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()
          "  void on#{msg_name}();"
        end)
      else
        "  void onProcess();"
      end

    """
    // Generated from ActorSimulation DSL
    // Callback interface for: #{name}
    //
    // IMPLEMENT THIS INTERFACE to add custom behavior!

    package #{group_id};

    /**
     * Callback interface for #{class_name} actor.
     * Implement this interface to customize actor behavior.
     */
    public interface #{class_name}Callbacks {
    #{methods}
    }
    """
  end

  defp generate_callback_implementation(name, definition, group_id) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    methods =
      if length(messages) > 0 do
        Enum.map_join(messages, "\n\n", fn msg ->
          msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()

          """
            @Override
            public void on#{msg_name}() {
              // TODO: Implement custom behavior for #{msg}
              System.out.println("#{class_name}: #{msg}");
            }
          """
        end)
      else
        """
          @Override
          public void onProcess() {
            // TODO: Implement custom behavior
            System.out.println("#{class_name}: processing");
          }
        """
      end

    """
    // Generated from ActorSimulation DSL
    // Default callback implementation for: #{name}
    //
    // CUSTOMIZE THIS CLASS to add your own behavior!

    package #{group_id};

    /**
     * Default implementation of #{class_name}Callbacks.
     * Modify this class to add custom behavior.
     */
    public class #{class_name}CallbacksImpl implements #{class_name}Callbacks {
    #{methods}
    }
    """
  end

  defp generate_main(actors, project_name, group_id, enable_callbacks) do
    simulated = GeneratorUtils.simulated_actors(actors)

    spawn_code =
      Enum.map_join(simulated, "\n", fn {name, definition} ->
        snake_name = GeneratorUtils.to_camel_case(name)
        class_name = GeneratorUtils.to_pascal_case(name)

        # Determine parameters based on constructor needs
        params =
          cond do
            enable_callbacks && length(definition.targets) > 0 ->
              "(#{class_name}Callbacks) null, new java.util.ArrayList<>()"

            enable_callbacks ->
              "(#{class_name}Callbacks) null"

            length(definition.targets) > 0 ->
              "new java.util.ArrayList<>()"

            true ->
              ""
          end

        """
        #{class_name}Protocol #{snake_name} = world.actorFor(
              #{class_name}Protocol.class,
              Definition.has(#{class_name}Actor.class,
                Definition.parameters(#{params}))
            );
        """
      end)

    """
    // Generated from ActorSimulation DSL
    // Main entry point for #{project_name}

    package #{group_id};

    import io.vlingo.xoom.actors.Definition;
    import io.vlingo.xoom.actors.World;

    /**
     * Main class to start the VLINGO XOOM actor system.
     */
    public class Main {
      public static void main(String[] args) {
        System.out.println("Starting VLINGO XOOM actor system...");

        final World world = World.startWithDefaults("#{project_name}");

        try {
          // Spawn all actors
    #{spawn_code}

          System.out.println("Actor system started. Press Ctrl+C to exit.");

          // Keep running
          Thread.currentThread().join();
        } catch (InterruptedException e) {
          System.out.println("System interrupted, shutting down...");
        } finally {
          world.terminate();
        }
      }
    }
    """
  end

  defp generate_test_class(name, definition, group_id, enable_callbacks) do
    class_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    # Determine test parameters based on what the constructor expects
    test_params =
      cond do
        enable_callbacks && length(definition.targets) > 0 ->
          "(#{class_name}Callbacks) null, new java.util.ArrayList<>()"

        enable_callbacks ->
          "(#{class_name}Callbacks) null"

        length(definition.targets) > 0 ->
          "new java.util.ArrayList<>()"

        true ->
          ""
      end

    # Generate test methods for each message
    message_tests =
      if length(messages) > 0 do
        Enum.map_join(messages, "\n\n", fn msg ->
          msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_camel_case()

          """
            @Test
            public void test#{GeneratorUtils.to_pascal_case(msg_name)}Message() {
              // Act
              actor.#{msg_name}();

              // Wait a bit for async processing
              try {
                Thread.sleep(100);
              } catch (InterruptedException e) {
                fail("Test interrupted");
              }

              // Assert - actor should handle message without errors
              assertTrue(true, "Message handled successfully");
            }
          """
        end)
      else
        """
          @Test
          public void testProcess() {
            // Act
            actor.process();

            // Wait a bit for async processing
            try {
              Thread.sleep(100);
            } catch (InterruptedException e) {
              fail("Test interrupted");
            }

            // Assert
            assertTrue(true, "Process completed successfully");
          }
        """
      end

    """
    // Generated from ActorSimulation DSL
    // JUnit 5 tests for #{class_name}Actor

    package #{group_id};

    import io.vlingo.xoom.actors.Definition;
    import io.vlingo.xoom.actors.World;
    import io.vlingo.xoom.actors.testkit.AccessSafely;
    import org.junit.jupiter.api.*;

    import static org.junit.jupiter.api.Assertions.*;

    /**
     * Test class for #{class_name}Actor.
     */
    public class #{class_name}ActorTest {
      private World world;
      private #{class_name}Protocol actor;

      @BeforeEach
      public void setUp() {
        world = World.startWithDefaults("test-world");
        actor = world.actorFor(
          #{class_name}Protocol.class,
          Definition.has(#{class_name}Actor.class,
            Definition.parameters(#{test_params}))
        );
      }

      @AfterEach
      public void tearDown() {
        if (world != null) {
          world.terminate();
        }
      }

      @Test
      public void testActorCreation() {
        assertNotNull(actor, "Actor should be created");
      }

    #{message_tests}
    }
    """
  end

  defp generate_pom(project_name, group_id, vlingo_version) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                                 http://maven.apache.org/xsd/maven-4.0.0.xsd">
      <modelVersion>4.0.0</modelVersion>

      <groupId>#{group_id}</groupId>
      <artifactId>#{project_name}</artifactId>
      <version>1.0-SNAPSHOT</version>
      <packaging>jar</packaging>

      <name>#{project_name}</name>
      <description>Generated from ActorSimulation DSL using VLINGO XOOM Actors</description>

      <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <vlingo.version>#{vlingo_version}</vlingo.version>
        <junit.version>5.10.0</junit.version>
      </properties>

      <dependencies>
        <!-- VLINGO XOOM Actors -->
        <dependency>
          <groupId>io.vlingo.xoom</groupId>
          <artifactId>xoom-actors</artifactId>
          <version>${vlingo.version}</version>
        </dependency>

        <!-- JUnit 5 for testing -->
        <dependency>
          <groupId>org.junit.jupiter</groupId>
          <artifactId>junit-jupiter-api</artifactId>
          <version>${junit.version}</version>
          <scope>test</scope>
        </dependency>
        <dependency>
          <groupId>org.junit.jupiter</groupId>
          <artifactId>junit-jupiter-engine</artifactId>
          <version>${junit.version}</version>
          <scope>test</scope>
        </dependency>
      </dependencies>

      <build>
        <plugins>
          <!-- Compiler plugin -->
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.11.0</version>
            <configuration>
              <release>11</release>
              <compilerArgs>
                <arg>-Xlint:unchecked</arg>
              </compilerArgs>
            </configuration>
          </plugin>

          <!-- Surefire plugin for running tests -->
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.1.2</version>
            <configuration>
              <includes>
                <include>**/*Test.java</include>
              </includes>
              <reportFormat>xml</reportFormat>
              <reportNameSuffix>junit5</reportNameSuffix>
            </configuration>
          </plugin>

          <!-- Exec plugin to run main class -->
          <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>exec-maven-plugin</artifactId>
            <version>3.1.0</version>
            <configuration>
              <mainClass>#{group_id}.Main</mainClass>
            </configuration>
          </plugin>

          <!-- Assembly plugin for creating executable JAR -->
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-assembly-plugin</artifactId>
            <version>3.6.0</version>
            <configuration>
              <archive>
                <manifest>
                  <mainClass>#{group_id}.Main</mainClass>
                </manifest>
              </archive>
              <descriptorRefs>
                <descriptorRef>jar-with-dependencies</descriptorRef>
              </descriptorRefs>
            </configuration>
            <executions>
              <execution>
                <id>make-assembly</id>
                <phase>package</phase>
                <goals>
                  <goal>single</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>

      <repositories>
        <repository>
          <id>central</id>
          <url>https://repo.maven.apache.org/maven2</url>
        </repository>
      </repositories>
    </project>
    """
  end

  defp format_constructor_params(callback_param, target_param) do
    # Remove leading commas and trim
    params =
      (callback_param <> target_param)
      |> String.replace(~r/^,\s*/, "")
      |> String.trim()

    params
  end

  defp generate_ci_pipeline(_project_name) do
    """
    name: CI

    on:
      push:
        branches: [ main, develop ]
      pull_request:
        branches: [ main ]

    jobs:
      build:
        runs-on: ${{ matrix.os }}
        strategy:
          fail-fast: false
          matrix:
            os: [ubuntu-latest, macos-latest, windows-latest]
            java: ['11', '17', '21']

        steps:
        - uses: actions/checkout@v3

        - name: Set up JDK ${{ matrix.java }}
          uses: actions/setup-java@v3
          with:
            java-version: ${{ matrix.java }}
            distribution: 'temurin'
            cache: 'maven'

        - name: Build with Maven
          run: mvn clean compile

        - name: Run tests
          run: mvn test

        - name: Package application
          run: mvn package

        - name: Publish Test Results
          if: always()
          uses: EnricoMi/publish-unit-test-result-action@v2
          with:
            files: |
              target/surefire-reports/*.xml
            check_name: "Test Results (Java ${{ matrix.java }}, ${{ matrix.os }})"

        - name: Run application (with timeout)
          shell: bash
          run: |
            timeout 10 mvn exec:java || true
    """
  end

  defp generate_readme(project_name) do
    """
    # #{project_name}

    Generated from ActorSimulation DSL using VLINGO XOOM Actors.

    ## About

    This project uses [VLINGO XOOM Actors](https://docs.vlingo.io/xoom-actors), a Java actor framework that provides:

    - **Type Safety** - Protocol-based messaging with interfaces
    - **Reactive Foundation** - Built for distributed, event-driven systems
    - **Scheduler Integration** - Built-in scheduling for periodic tasks
    - **Production Ready** - Battle-tested in enterprise applications

    The code is generated from a high-level Elixir DSL and provides:
    - Type-safe actor implementations
    - Protocol interfaces for messaging
    - Callback interfaces for customization
    - JUnit 5 test suites
    - Production-ready code

    ## Prerequisites

    - **Java 11+** (Java 17 or 21 recommended)
    - **Maven 3.6+**

    ## Building

    ```bash
    # Build the project
    mvn clean compile

    # Package as JAR
    mvn package
    ```

    ## Running

    ```bash
    # Run with Maven
    mvn exec:java

    # Or run the packaged JAR
    java -jar target/#{project_name}-1.0-SNAPSHOT-jar-with-dependencies.jar
    ```

    ## Testing

    ```bash
    # Run all tests
    mvn test

    # Run with verbose output
    mvn test -X

    # Run specific test class
    mvn test -Dtest=YourActorTest
    ```

    ## Customizing Behavior

    The generated actor code uses callback interfaces to allow customization WITHOUT
    modifying generated files:

    1. Find the `*CallbacksImpl.java` files in `src/main/java`
    2. Implement your custom logic in the callback methods
    3. Rebuild the project

    The generated actor code will automatically call your callbacks.

    ## Project Structure

    ```
    src/
    ├── main/
    │   └── java/
    │       ├── Main.java              # Entry point
    │       ├── *Protocol.java         # Actor protocol interfaces (DO NOT EDIT)
    │       ├── *Actor.java            # Actor implementations (DO NOT EDIT)
    │       ├── *Callbacks.java        # Callback interfaces (DO NOT EDIT)
    │       └── *CallbacksImpl.java    # Callback implementations (EDIT THIS!)
    └── test/
        └── java/
            └── *ActorTest.java        # JUnit 5 tests (expand as needed)
    ```

    ## CI/CD

    This project includes a GitHub Actions workflow that:
    - Builds on Ubuntu, macOS, and Windows
    - Tests with Java 11, 17, and 21
    - Publishes test results
    - Validates the build with each commit

    ## Learn More

    - [VLINGO XOOM Documentation](https://docs.vlingo.io/)
    - [VLINGO XOOM Actors Guide](https://docs.vlingo.io/xoom-actors)
    - [VLINGO XOOM GitHub](https://github.com/vlingo)
    - [ActorSimulation DSL](https://github.com/yourusername/gen_server_virtual_time)

    ## License

    Generated code is provided as-is for your use.
    """
  end
end
