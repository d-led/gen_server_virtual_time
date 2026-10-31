defmodule ActorSimulation.Codegen.Phony do
  alias ActorSimulation.TemplateVersions

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

      {:ok, files} = Phony.generate(simulation,
        project_name: "my_actors",
        enable_callbacks: true)

      Phony.write_to_directory(files, "phony_output/")
  """

  alias ActorSimulation.GeneratorUtils

  @doc """
  Generates complete Phony (Go) project files from an ActorSimulation.

  ## Options

  - `:project_name` (required) - Name of the Go module (snake_case)
  - `:enable_callbacks` (default: true) - Generate callback interfaces
  - `:go_version` - Go version for go.mod, defaulting to
    `ActorSimulation.TemplateVersions.get(:go)`

  ## Returns

  `{:ok, files}` where files is a list of `{filename, content}` tuples
  """
  def generate(simulation, opts \\ []) do
    project_name = Keyword.fetch!(opts, :project_name)
    enable_callbacks = Keyword.get(opts, :enable_callbacks, true)
    go_version = Keyword.get(opts, :go_version, TemplateVersions.get(:go))

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
          snake_name = GeneratorUtils.to_snake_case(name)

          # Generate actor interface file (generated code, do not edit)
          actor_file = generate_actor_file(name, definition, enable_callbacks)
          new_files = [{"#{snake_name}.go", actor_file}]

          # Generate callbacks file (custom code, meant to be edited)
          new_files =
            if enable_callbacks do
              callback_file = generate_callbacks_file(name, definition)
              new_files ++ [{"#{snake_name}_callbacks.go", callback_file}]
            else
              new_files
            end

          new_files ++ acc

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

    imports = ["\"github.com/Arceliar/phony\""]
    imports = if needs_time, do: ["\"time\"" | imports], else: imports
    import_list = Enum.map_join(Enum.reverse(imports), "\n", &"\t#{&1}")

    """
    // Generated from ActorSimulation DSL
    // Actor: #{name}
    // DO NOT EDIT - This file is auto-generated

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

    """
    // #{type_name}Callbacks defines the callback interface
    // Implement this interface to customize actor behavior
    type #{type_name}Callbacks interface {
    #{methods}
    }

    """
  end

  defp generate_callbacks_file(name, definition) do
    type_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

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

    imports_section =
      if messages != [] do
        "import (\n\t\"fmt\"\n)\n"
      else
        ""
      end

    """
    // Generated from ActorSimulation DSL
    // Default callback implementation for: #{name}
    // CUSTOMIZE THIS FILE - This is where you add your custom behavior!

    package main

    #{imports_section}

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
      Enum.map_join(simulated, "\n\n", fn {name, definition} ->
        type_name = GeneratorUtils.to_pascal_case(name)
        generate_actor_test(type_name, definition)
      end)

    """
    // Generated from ActorSimulation DSL
    // Go tests for actors

    package main

    import (
    \t"testing"
    \t"time"

    \t"github.com/Arceliar/phony"
    )

    func TestActorSystem(t *testing.T) {
    \t// Basic system test
    \tif testing.Short() {
    \t\tt.Skip("Skipping in short mode")
    \t}
    }

    // waitFor waits until what asks for holds, or until the time it was given is up.
    func waitFor(t *testing.T, within time.Duration, what func() bool) {
    \tt.Helper()

    \tdeadline := time.Now().Add(within)
    \tfor time.Now().Before(deadline) {
    \t\tif what() {
    \t\t\treturn
    \t\t}

    \t\ttime.Sleep(time.Millisecond)
    \t}
    }

    #{test_cases}
    """
  end

  # generate_actor_test answers the test of one actor: it holds the actor to the
  # number of messages its pattern makes, which is what a test of an actor that
  # waits is for. An actor with no pattern is held to taking a message at all.
  defp generate_actor_test(type_name, definition) do
    case definition.send_pattern do
      {:burst, count, interval_ms, _message} ->
        """
        func Test#{type_name}(t *testing.T) {
        \tactor := &#{type_name}{}
        \tactor.Start()

        \t// One burst is due an interval from now, and it is the count the DSL asked
        \t// for: wait for it, then hold the actor to it.
        \twaitFor(t, 2*#{interval_ms}*time.Millisecond, func() bool {
        \t\tphony.Block(actor.Actor(), func() {})
        \t\treturn actor.sendCount >= #{count}
        \t})

        \tphony.Block(actor.Actor(), func() {})
        \tif actor.sendCount != #{count} {
        \t\tt.Fatalf("the burst sent %d messages, want #{count}", actor.sendCount)
        \t}
        }
        """

      {:self_message, delay_ms, _message} ->
        """
        func Test#{type_name}(t *testing.T) {
        \tactor := &#{type_name}{}
        \tactor.Start()

        \t// The one message is due #{delay_ms}ms from now.
        \twaitFor(t, 2*#{delay_ms}*time.Millisecond, func() bool {
        \t\tphony.Block(actor.Actor(), func() {})
        \t\treturn actor.sendCount >= 1
        \t})

        \tphony.Block(actor.Actor(), func() {})
        \tif actor.sendCount != 1 {
        \t\tt.Fatalf("the actor sent %d messages, want 1", actor.sendCount)
        \t}
        }
        """

      {:periodic, interval_ms, _message} ->
        periodic_test(type_name, interval_ms)

      {:rate, per_second, _message} ->
        periodic_test(type_name, div(1000, per_second))

      _ ->
        """
        func Test#{type_name}(t *testing.T) {
        \tactor := &#{type_name}{}
        \tactor.Start()

        \t// The actor's inbox takes work: this returns when it has run it, which it
        \t// never does if the actor is broken.
        \tphony.Block(actor.Actor(), func() {})
        }
        """
    end
  end

  # A repeating actor sends once per interval, and how many intervals the wall
  # clock fits into a wait is the machine's business, so the test holds the count
  # to the range three intervals can produce and not to one number.
  defp periodic_test(type_name, interval_ms) do
    """
    func Test#{type_name}(t *testing.T) {
    \tactor := &#{type_name}{}
    \tactor.Start()

    \tconst intervals = 3
    \ttime.Sleep(intervals*#{interval_ms}*time.Millisecond + #{interval_ms}/2*time.Millisecond)

    \tphony.Block(actor.Actor(), func() {})
    \tif actor.sendCount < intervals || actor.sendCount > intervals+1 {
    \t\tt.Fatalf("the actor sent %d messages in %d intervals, want %d or %d", actor.sendCount, intervals, intervals, intervals+1)
    \t}
    }
    """
  end

  defp generate_go_mod(project_name, go_version) do
    """
    module #{project_name}

    go #{go_version}

    require github.com/Arceliar/phony #{TemplateVersions.get(:phony)}
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
            go-version: ['#{TemplateVersions.get(:go)}', stable]

        steps:
        - uses: actions/checkout@#{TemplateVersions.get(:checkout_action)}

        - name: Set up Go
          uses: actions/setup-go@#{TemplateVersions.get(:setup_go_action)}
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

    - **Go #{TemplateVersions.get(:go)}+**
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

    The generated actor code uses callback interfaces to allow customization WITHOUT
    modifying generated files:

    1. Find the `*_callbacks.go` files
    2. Modify the `Default*Callbacks` implementation
    3. Add your custom logic in the callback methods
    4. Rebuild

    The generated actor code will automatically call your callbacks.

    ## Project Structure

    - `main.go` - Entry point and actor spawning
    - `*_actor.go` - Generated actor interface (DO NOT EDIT)
    - `*_callbacks.go` - Callback implementations (EDIT THIS!)
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
    - [ActorSimulation DSL](https://github.com/d-led/gen_server_virtual_time)

    ## License

    Generated code is provided as-is for your use.
    """
  end
end
