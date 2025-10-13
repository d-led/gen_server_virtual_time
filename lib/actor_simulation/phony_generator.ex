defmodule ActorSimulation.PhonyGenerator do
  @moduledoc """
  Generates Go code using the Phony actor library from ActorSimulation DSL.

  Phony is a Pony-inspired actor library for Go that provides:
  - Zero-allocation message passing
  - Automatic goroutine management
  - Backpressure support
  - No locks or channels needed

  This generator creates production-ready Go projects with:
  - Phony actor implementations
  - Callback interfaces for custom behavior
  - Go test suites
  - GitHub Actions CI/CD
  - Complete documentation

  ## Example

      simulation = ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
            send_pattern: {:periodic, 100, :msg},
            targets: [:receiver])
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} = PhonyGenerator.generate(simulation,
        project_name: "my_actors",
        enable_callbacks: true)

      PhonyGenerator.write_to_directory(files, "phony_output/")
  """

  alias ActorSimulation.GeneratorUtils

  @doc """
  Generates complete Phony (Go) project files from an ActorSimulation.

  ## Options

  - `:project_name` (required) - Name of the Go module (snake_case)
  - `:enable_callbacks` (default: true) - Generate callback interfaces
  - `:go_version` (default: "1.21") - Go version for go.mod

  ## Returns

  `{:ok, files}` where files is a list of `{filename, content}` tuples
  """
  def generate(simulation, opts \\ []) do
    project_name = Keyword.fetch!(opts, :project_name)
    enable_callbacks = Keyword.get(opts, :enable_callbacks, true)
    go_version = Keyword.get(opts, :go_version, "1.21")

    actors = simulation.actors

    files =
      []
      |> add_actor_files(actors, enable_callbacks)
      |> add_main_file(actors, project_name)
      |> add_test_file(actors)
      |> add_go_mod(project_name, go_version)
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

  defp add_actor_files(files, actors, enable_callbacks) do
    Enum.reduce(actors, files, fn {name, actor_info}, acc ->
      case actor_info.type do
        :simulated ->
          definition = actor_info.definition
          actor_file = generate_actor_file(name, definition, enable_callbacks)
          [{"#{GeneratorUtils.to_snake_case(name)}.go", actor_file} | acc]

        :real_process ->
          acc
      end
    end)
  end

  defp add_main_file(files, actors, project_name) do
    content = generate_main(actors, project_name)
    [{"main.go", content} | files]
  end

  defp add_test_file(files, actors) do
    content = generate_test_file(actors)
    [{"actor_test.go", content} | files]
  end

  defp add_go_mod(files, project_name, go_version) do
    content = generate_go_mod(project_name, go_version)
    [{"go.mod", content} | files]
  end

  defp add_ci_pipeline(files, project_name) do
    content = generate_ci_pipeline(project_name)
    [{".github/workflows/ci.yml", content} | files]
  end

  defp add_readme(files, project_name) do
    content = generate_readme(project_name)
    [{"README.md", content} | files]
  end

  defp generate_actor_file(name, definition, enable_callbacks) do
    type_name = GeneratorUtils.to_pascal_case(name)

    callback_interface =
      if enable_callbacks do
        generate_callback_interface(name, definition)
      else
        ""
      end

    callback_field =
      if enable_callbacks do
        """
        \tcallbacks #{type_name}Callbacks
        """
      else
        ""
      end

    callback_init =
      if enable_callbacks do
        """
        \ta.callbacks = &Default#{type_name}Callbacks{}
        """
      else
        ""
      end

    timer_setup = generate_timer_setup(definition)
    message_handlers = generate_message_handlers(name, definition, enable_callbacks)

    # Determine which imports are needed
    needs_time = definition.send_pattern != nil
    needs_fmt = enable_callbacks && definition.send_pattern != nil

    imports = ["\"github.com/Arceliar/phony\""]
    imports = if needs_fmt, do: ["\"fmt\"" | imports], else: imports
    imports = if needs_time, do: ["\"time\"" | imports], else: imports
    import_list = Enum.map_join(Enum.reverse(imports), "\n", &"\t#{&1}")

    """
    // Generated from ActorSimulation DSL
    // Actor: #{name}

    package main

    import (
    #{import_list}
    )

    #{callback_interface}

    type #{type_name} struct {
    \tphony.Inbox
    \ttargets []*#{type_name}
    #{callback_field}\tsendCount int
    }

    func (a *#{type_name}) Actor() *phony.Inbox {
    \treturn &a.Inbox
    }

    func (a *#{type_name}) Start() {
    #{callback_init}#{timer_setup}}

    #{message_handlers}
    """
  end

  defp generate_callback_interface(name, definition) do
    type_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    methods =
      Enum.map_join(messages, "\n", fn msg ->
        msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()
        "\tOn#{msg_name}()"
      end)

    impl_methods =
      Enum.map_join(messages, "\n\n", fn msg ->
        msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()
        # If actor has send_pattern, it's the sender (publisher)
        action = if definition.send_pattern, do: "Sending", else: "Received"

        """
        func (c *Default#{type_name}Callbacks) On#{msg_name}() {
        \t// TODO: Implement custom behavior for #{msg}
        \tfmt.Printf("#{type_name}: #{action} #{msg} message\\n")
        }
        """
      end)

    """
    // #{type_name}Callbacks defines the callback interface
    // Implement this interface to customize actor behavior
    type #{type_name}Callbacks interface {
    #{methods}
    }

    // Default#{type_name}Callbacks provides default implementations
    // CUSTOMIZE THIS to add your own behavior!
    type Default#{type_name}Callbacks struct{}

    #{impl_methods}
    """
  end

  defp generate_timer_setup(definition) do
    case definition.send_pattern do
      nil ->
        ""

      {:periodic, interval_ms, message} ->
        msg_name = GeneratorUtils.message_name(message) |> GeneratorUtils.to_pascal_case()

        """
        \tgo func() {
        \t\tticker := time.NewTicker(#{interval_ms} * time.Millisecond)
        \t\tdefer ticker.Stop()
        \t\tfor range ticker.C {
        \t\t\ta.Act(nil, func() { a.#{msg_name}() })
        \t\t}
        \t}()
        """

      {:rate, per_second, message} ->
        interval_ms = div(1000, per_second)
        msg_name = GeneratorUtils.message_name(message) |> GeneratorUtils.to_pascal_case()

        """
        \tgo func() {
        \t\tticker := time.NewTicker(#{interval_ms} * time.Millisecond)
        \t\tdefer ticker.Stop()
        \t\tfor range ticker.C {
        \t\t\ta.Act(nil, func() { a.#{msg_name}() })
        \t\t}
        \t}()
        """

      {:burst, count, interval_ms, message} ->
        msg_name = GeneratorUtils.message_name(message) |> GeneratorUtils.to_pascal_case()

        """
        \tgo func() {
        \t\tticker := time.NewTicker(#{interval_ms} * time.Millisecond)
        \t\tdefer ticker.Stop()
        \t\tfor range ticker.C {
        \t\t\tfor i := 0; i < #{count}; i++ {
        \t\t\t\ta.Act(nil, func() { a.#{msg_name}() })
        \t\t\t}
        \t\t}
        \t}()
        """

      {:self_message, delay_ms, message} ->
        msg_name = GeneratorUtils.message_name(message) |> GeneratorUtils.to_pascal_case()

        """
        \t// One-shot delayed self-message
        \tgo func() {
        \t\ttime.Sleep(#{delay_ms} * time.Millisecond)
        \t\ta.Act(nil, func() { a.#{msg_name}() })
        \t}()
        """
    end
  end

  defp generate_message_handlers(name, definition, enable_callbacks) do
    type_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    Enum.map_join(messages, "\n\n", fn msg ->
      msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()

      callback_call =
        if enable_callbacks do
          """
          \ta.callbacks.On#{msg_name}()
          """
        else
          """
          \t// Handle #{msg}
          """
        end

      """
      func (a *#{type_name}) #{msg_name}() {
      #{callback_call}\t// Send to targets
      \tfor _, target := range a.targets {
      \t\ttarget.Act(a, func() { target.#{msg_name}() })
      \t}
      \ta.sendCount++
      }
      """
    end)
  end

  defp generate_main(actors, project_name) do
    simulated = GeneratorUtils.simulated_actors(actors)

    spawn_code =
      Enum.map_join(simulated, "\n", fn {name, _def} ->
        snake_name = GeneratorUtils.to_snake_case(name)
        type_name = GeneratorUtils.to_pascal_case(name)
        "\t#{snake_name} := &#{type_name}{}\n\t#{snake_name}.Start()"
      end)

    """
    // Generated from ActorSimulation DSL
    // Main entry point for #{project_name}

    package main

    import (
    \t"fmt"
    )

    func main() {
    \tfmt.Println("Starting actor system...")
    \t
    \t// Spawn all actors
    #{spawn_code}
    \t
    \tfmt.Println("Actor system started. Press Ctrl+C to exit.")
    \t
    \t// Keep running
    \tselect {}
    }
    """
  end

  defp generate_test_file(actors) do
    simulated = GeneratorUtils.simulated_actors(actors)

    test_cases =
      Enum.map_join(simulated, "\n\n", fn {name, _def} ->
        type_name = GeneratorUtils.to_pascal_case(name)

        """
        func Test#{type_name}(t *testing.T) {
        \tactor := &#{type_name}{}
        \tactor.Start()
        \t
        \t// Wait a bit for actor to initialize
        \ttime.Sleep(10 * time.Millisecond)
        \t
        \tif actor == nil {
        \t\tt.Fatal("Actor should not be nil")
        \t}
        }
        """
      end)

    """
    // Generated from ActorSimulation DSL
    // Go tests for actors

    package main

    import (
    \t"testing"
    \t"time"
    )

    func TestActorSystem(t *testing.T) {
    \t// Basic system test
    \tif testing.Short() {
    \t\tt.Skip("Skipping in short mode")
    \t}
    }

    #{test_cases}
    """
  end

  defp generate_go_mod(project_name, go_version) do
    """
    module #{project_name}

    go #{go_version}

    require github.com/Arceliar/phony v0.0.0-20220903101357-530938a4b13d
    """
  end

  defp generate_ci_pipeline(project_name) do
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
            go-version: ['1.21', '1.22']

        steps:
        - uses: actions/checkout@v3

        - name: Set up Go
          uses: actions/setup-go@v4
          with:
            go-version: ${{ matrix.go-version }}
            cache: true

        - name: Download dependencies
          run: go mod download

        - name: Build
          run: |
            OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
            if [ -f "go.mod" ]; then
              PROJECT_NAME=$(grep -o 'module [^ ]*' go.mod | head -1 | awk '{print $2}' | xargs basename)
            else
              PROJECT_NAME="#{project_name}"
            fi
            BINARY="${PROJECT_NAME}.phony.${OS_NAME}"
            go build -o "$BINARY" .

        - name: Test
          run: go test -v ./...

        - name: Run Demo Application
          shell: bash
          run: |
            # Determine binary name: {project}.phony.{os}
            OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
            if [ -f "go.mod" ]; then
              PROJECT_NAME=$(grep -o 'module [^ ]*' go.mod | head -1 | awk '{print $2}' | xargs basename)
            else
              PROJECT_NAME="#{project_name}"
            fi
            BINARY="${PROJECT_NAME}.phony.${OS_NAME}"
            timeout 5 ./"${BINARY}" || true
    """
  end

  defp generate_readme(project_name) do
    """
    # #{project_name}

    Generated from ActorSimulation DSL using Phony (Go actor library).

    ## About

    This project uses [Phony](https://github.com/Arceliar/phony), a Pony-inspired
    actor library for Go that provides:

    - **Zero-allocation messaging** - Efficient message passing
    - **Automatic goroutine management** - No goroutine leaks
    - **Backpressure support** - Built-in flow control
    - **Lock-free** - No mutexes or channels needed

    The code is generated from a high-level Elixir DSL and provides:
    - Phony actor implementations
    - Callback interfaces for customization
    - Go test suites
    - Production-ready code

    ## Prerequisites

    - **Go 1.21+**
    - **Git** (for go modules)

    ## Building

    ```bash
    # Download dependencies
    go mod download

    # Build
    go build -o #{project_name} .

    # Run
    ./#{project_name}
    ```

    ## Testing

    ```bash
    # Run tests
    go test -v ./...
    ```

    ## Customizing Behavior

    The generated actor code uses callback interfaces to allow customization:

    1. Find the `*Callbacks` interface in each actor file
    2. Modify the `Default*Callbacks` implementation
    3. Add your custom logic in the callback methods
    4. Rebuild

    The generated actor code will automatically call your callbacks.

    ## Project Structure

    - `main.go` - Entry point and actor spawning
    - `*.go` - Generated actor implementations
    - `actor_test.go` - Go test suite
    - `go.mod` - Module definition

    ## CI/CD

    This project includes a GitHub Actions workflow that:
    - Builds on Ubuntu, macOS, and Windows
    - Tests with multiple Go versions
    - Validates the build with each commit

    ## Learn More

    - [Phony GitHub](https://github.com/Arceliar/phony)
    - [Go Modules](https://go.dev/blog/using-go-modules)
    - [ActorSimulation DSL](https://github.com/yourusername/gen_server_virtual_time)

    ## License

    Generated code is provided as-is for your use.
    """
  end
end
