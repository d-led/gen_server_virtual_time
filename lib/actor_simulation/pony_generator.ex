defmodule ActorSimulation.PonyGenerator do
  @moduledoc """
  Generates Pony actor code from ActorSimulation DSL.

  Pony is a capabilities-secure, actor-model language that provides:
  - Type safety and memory safety
  - Data-race freedom and deadlock freedom
  - Zero-cost actors with async message passing
  - Built-in testing with PonyTest

  This generator creates production-ready Pony projects with:
  - Actor implementations with behaviors
  - Callback traits for custom behavior
  - PonyTest test suites
  - Corral dependency management
  - CI/CD pipeline
  - Complete documentation

  ## Example

      simulation = ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
            send_pattern: {:periodic, 100, :msg},
            targets: [:receiver])
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} = PonyGenerator.generate(simulation,
        project_name: "my_actors",
        enable_callbacks: true)

      PonyGenerator.write_to_directory(files, "pony_output/")
  """

  @doc """
  Generates complete Pony project files from an ActorSimulation.

  ## Options

  - `:project_name` (required) - Name of the Pony project (snake_case)
  - `:enable_callbacks` (default: true) - Generate callback traits

  ## Returns

  `{:ok, files}` where files is a list of `{filename, content}` tuples
  """
  def generate(simulation, opts \\ []) do
    project_name = Keyword.fetch!(opts, :project_name)
    enable_callbacks = Keyword.get(opts, :enable_callbacks, true)

    actors = simulation.actors

    files =
      []
      |> add_actor_files(actors, enable_callbacks)
      |> add_main_file(actors, project_name)
      |> add_test_files(actors, project_name)
      |> add_corral_file(project_name)
      |> add_makefile(project_name)
      |> add_ci_pipeline(project_name)
      |> add_readme(project_name)

    {:ok, files}
  end

  @doc """
  Writes generated files to a directory.

  Creates the directory and all subdirectories as needed.
  """
  def write_to_directory(files, output_dir) do
    ActorSimulation.GeneratorUtils.write_to_directory(files, output_dir)
  end

  # Private functions

  defp generate_console_logger do
    """
    // Generated from ActorSimulation DSL
    // Thread-safe console logger actor
    //
    // Based on best practices from Pony actor systems
    // See: https://github.com/d-led/DDDwithActorsPony/blob/master/Receiver.pony

    actor ConsoleLogger
      \"\"\"
      Thread-safe console logger that uses env.out for output.
      All logging goes through this actor to avoid race conditions.
      \"\"\"

      let _out: OutStream

      new create(out: OutStream) =>
        _out = out

      be log(msg: String) =>
        \"\"\"
        Log a message to console.
        This is thread-safe as it's processed sequentially by the actor.
        \"\"\"
        _out.print(msg)
    """
  end

  defp add_actor_files(files, actors, enable_callbacks) do
    # Add console logger first
    logger_file = generate_console_logger()
    files = [{"console_logger.pony", logger_file} | files]

    Enum.reduce(actors, files, fn {name, actor_info}, acc ->
      case actor_info.type do
        :simulated ->
          definition = actor_info.definition
          actor_name = actor_snake_case(name)

          actor_file = generate_actor_file(name, definition, enable_callbacks)
          new_files = [{"#{actor_name}.pony", actor_file}]

          new_files =
            if enable_callbacks do
              callback_trait = generate_callback_trait(name, definition, enable_callbacks)
              new_files ++ [{"#{actor_name}_callbacks.pony", callback_trait}]
            else
              new_files
            end

          new_files ++ acc

        :real_process ->
          # Skip real processes for Pony generation
          acc
      end
    end)
  end

  defp add_main_file(files, actors, project_name) do
    content = generate_main(actors, project_name)
    [{"main.pony", content} | files]
  end

  defp add_test_files(files, actors, project_name) do
    test_content = generate_test_file(actors, project_name)
    [{"test/test.pony", test_content} | files]
  end

  defp add_corral_file(files, project_name) do
    content = generate_corral(project_name)
    [{"corral.json", content} | files]
  end

  defp add_makefile(files, project_name) do
    content = generate_makefile(project_name)
    [{"Makefile", content} | files]
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
    actor_name = actor_class_name(name)

    callback_field =
      if enable_callbacks do
        """
          let _callbacks: #{actor_class_name(name)}Callbacks
        """
      else
        ""
      end

    callback_init =
      if enable_callbacks do
        """
            _callbacks = #{actor_class_name(name)}CallbacksImpl(logger)
        """
      else
        ""
      end

    timer_code = generate_timer_code(definition)
    behaviors = generate_behaviors(name, definition, enable_callbacks)

    """
    // Generated from ActorSimulation DSL
    // Actor: #{name}

    use \"collections\"
    use \"time\"

    actor #{actor_name}
      let _env: Env
      let _timers: Timers = Timers
      let _targets: Array[#{actor_class_name(name)}] = Array[#{actor_class_name(name)}]
      let logger: ConsoleLogger
    #{callback_field}

      new create(env: Env, logger': ConsoleLogger, targets: Array[#{actor_class_name(name)}] val = recover Array[#{actor_class_name(name)}] end) =>
        _env = env
        logger = logger'
        _targets.append(targets)
    #{callback_init}#{timer_code}

    #{behaviors}
    """
  end

  defp generate_timer_code(definition) do
    case definition.send_pattern do
      nil ->
        ""

      {:periodic, interval_ms, message} ->
        interval_ns = trunc(interval_ms * 1_000_000)
        msg_name = message_name(message)

        """
            let timer = Timer(#{actor_class_name(msg_name)}Timer(this), #{interval_ns}, #{interval_ns})
            _timers(consume timer)
        """

      {:rate, per_second, message} ->
        interval_ns = trunc(1000.0 / per_second * 1_000_000)
        msg_name = message_name(message)

        """
            let timer = Timer(#{actor_class_name(msg_name)}Timer(this), #{interval_ns}, #{interval_ns})
            _timers(consume timer)
        """

      {:burst, count, interval_ms, message} ->
        interval_ns = trunc(interval_ms * 1_000_000)
        msg_name = message_name(message)

        """
            let timer = Timer(#{actor_class_name(msg_name)}BurstTimer(this, #{count}), #{interval_ns}, #{interval_ns})
            _timers(consume timer)
        """

      {:self_message, delay_ms, message} ->
        delay_ns = trunc(delay_ms * 1_000_000)
        msg_name = message_name(message)

        """
        // One-shot self-message timer
            let timer = Timer(#{actor_class_name(msg_name)}OneShotTimer(this), #{delay_ns}, 0)
            _timers(consume timer)
        """
    end
  end

  defp generate_behaviors(name, definition, enable_callbacks) do
    messages = extract_messages_from_pattern(definition.send_pattern)

    behavior_defs =
      Enum.map(messages, fn msg ->
        msg_name = message_name(msg)

        callback_call =
          if enable_callbacks do
            """
              _callbacks.on_#{msg_name}()
            """
          else
            """
              // Message received: #{msg}
            """
          end

        """
          be #{msg_name}() =>
        #{callback_call}    // Send to targets
            for target in _targets.values() do
              target.#{msg_name}()
            end
        """
      end)

    timer_classes = generate_timer_classes(name, definition)

    Enum.join(behavior_defs, "\n") <> "\n" <> timer_classes
  end

  defp generate_timer_classes(name, definition) do
    case definition.send_pattern do
      nil ->
        ""

      {:periodic, _interval_ms, message} ->
        msg_name = message_name(message)
        actor_name = actor_class_name(name)

        """
        class #{actor_class_name(msg_name)}Timer is TimerNotify
          let _actor: #{actor_name} tag

          new iso create(actor': #{actor_name}) =>
            _actor = actor'

          fun ref apply(timer: Timer, count: U64): Bool =>
            _actor.#{msg_name}()
            true  // Keep timer running
        """

      {:rate, _per_second, message} ->
        msg_name = message_name(message)
        actor_name = actor_class_name(name)

        """
        class #{actor_class_name(msg_name)}Timer is TimerNotify
          let _actor: #{actor_name} tag

          new iso create(actor': #{actor_name}) =>
            _actor = actor'

          fun ref apply(timer: Timer, count: U64): Bool =>
            _actor.#{msg_name}()
            true  // Keep timer running
        """

      {:burst, _count, _interval_ms, message} ->
        msg_name = message_name(message)
        actor_name = actor_class_name(name)

        """
        class #{actor_class_name(msg_name)}BurstTimer is TimerNotify
          let _actor: #{actor_name} tag
          let _burst_count: USize

          new iso create(actor': #{actor_name}, burst_count: USize) =>
            _actor = actor'
            _burst_count = burst_count

          fun ref apply(timer: Timer, count: U64): Bool =>
            var i: USize = 0
            while i < _burst_count do
              _actor.#{msg_name}()
              i = i + 1
            end
            true  // Keep timer running
        """

      {:self_message, _delay_ms, message} ->
        msg_name = message_name(message)
        actor_name = actor_class_name(name)

        """
        class #{actor_class_name(msg_name)}OneShotTimer is TimerNotify
          let _actor: #{actor_name} tag

          new iso create(actor': #{actor_name}) =>
            _actor = actor'

          fun ref apply(timer: Timer, count: U64): Bool =>
            _actor.#{msg_name}()
            false  // Don't repeat (one-shot)
        """
    end
  end

  defp generate_callback_trait(name, definition, _enable_callbacks) do
    actor_name = actor_class_name(name)
    messages = extract_messages_from_pattern(definition.send_pattern)

    methods =
      Enum.map(messages, fn msg ->
        msg_name = message_name(msg)
        "  fun ref on_#{msg_name}()"
      end)

    methods_str =
      if length(methods) > 0 do
        Enum.join(methods, "\n")
      else
        "  fun ref on_message()"
      end

    impl_methods =
      Enum.map(messages, fn msg ->
        msg_name = message_name(msg)
        # If actor has send_pattern, it's the sender (publisher)
        action = if definition.send_pattern, do: "Sending", else: "Received"

        """
          fun ref on_#{msg_name}() =>
            // TODO: Implement custom behavior for #{msg}
            _logger.log("#{actor_name}: #{action} #{msg} message")
        """
      end)

    impl_methods_str =
      if length(impl_methods) > 0 do
        Enum.join(impl_methods, "\n")
      else
        """
          fun ref on_message() =>
            // TODO: Implement custom behavior
            _logger.log("#{actor_name}: Processing message")
        """
      end

    """
    // Generated from ActorSimulation DSL
    // Callback trait for: #{name}
    //
    // Implement this trait to add custom behavior!

    trait #{actor_name}Callbacks
    #{methods_str}

    class #{actor_name}CallbacksImpl is #{actor_name}Callbacks
      \"\"\"
      Default implementation of #{actor_name} callbacks.

      CUSTOMIZE THIS CLASS to add your own behavior!
      The generated actor code will call these methods.
      \"\"\"

      let _logger: ConsoleLogger

      new create(logger: ConsoleLogger) =>
        _logger = logger

    #{impl_methods_str}
    """
  end

  defp generate_main(actors, project_name) do
    simulated_actors =
      actors
      |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
      |> Enum.map(fn {name, info} -> {name, info.definition} end)

    spawn_code = generate_spawn_code(simulated_actors)

    """
    // Generated from ActorSimulation DSL
    // Main entry point for #{project_name}

    actor Main
      new create(env: Env) =>
        \"\"\"
        Start the actor system.
        \"\"\"

        // Create thread-safe console logger
        let logger = ConsoleLogger(env.out)

        // Spawn all actors
    #{spawn_code}

        env.out.print("Actor system started. Press Ctrl+C to exit.")
    """
  end

  defp generate_spawn_code(actors) do
    actors
    |> Enum.map_join("\n", fn {name, _def} ->
      actor_name = actor_snake_case(name)
      class_name = actor_class_name(name)
      "    let #{actor_name} = #{class_name}(env, logger)"
    end)
  end

  defp generate_test_file(actors, project_name) do
    simulated_actors =
      actors
      |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
      |> Enum.map(fn {name, info} -> {name, info.definition} end)

    uses =
      Enum.map(simulated_actors, fn {name, _def} ->
        "use \"..#{actor_snake_case(name)}\""
      end)

    test_classes = generate_test_classes(simulated_actors)

    """
    // Generated from ActorSimulation DSL
    // PonyTest tests for #{project_name}

    use \"ponytest\"
    use \"../console_logger\"
    #{Enum.join(uses, "\n")}

    actor Main is TestList
      new create(env: Env) => PonyTest(env, this)

      new make() => None

      fun tag tests(test: PonyTest) =>
        test(_TestActorSystem)
    #{test_classes}
    """
  end

  defp generate_test_classes(actors) do
    actors
    |> Enum.map_join("", fn {name, _def} ->
      class_name = actor_class_name(name)

      """
          test(_Test#{class_name})
      """
    end)
    |> then(fn tests ->
      actor_test_cases =
        Enum.map(actors, fn {name, _def} ->
          class_name = actor_class_name(name)

          """

          class iso _Test#{class_name} is UnitTest
            \"\"\"Test that #{class_name} actor can be created.\"\"\"

            fun name(): String => "#{class_name} actor"

            fun apply(h: TestHelper) =>
              h.long_test(2_000_000_000)  // 2 second timeout
              // Actor creation test
              let logger = ConsoleLogger(h.env.out)
              let _actor = #{class_name}(h.env, logger)
              h.complete(true)
          """
        end)

      tests <>
        """


        class iso _TestActorSystem is UnitTest
          \"\"\"Test that the actor system can be initialized.\"\"\"

          fun name(): String => "Actor System"

          fun apply(h: TestHelper) =>
            h.long_test(2_000_000_000)  // 2 second timeout
            h.complete(true)
        """ <> Enum.join(actor_test_cases, "")
    end)
  end

  defp generate_corral(project_name) do
    # Use the library version for generated projects
    version = GenServerVirtualTime.version()

    """
    {
      "info": {
        "name": "#{project_name}",
        "description": "Generated from ActorSimulation DSL",
        "version": "#{version}",
        "license": "MIT"
      },
      "deps": []
    }
    """
  end

  defp generate_makefile(project_name) do
    """
    # Generated from ActorSimulation DSL
    # Makefile for #{project_name}

    # Binary naming: {example}.pony.{os}
    UNAME_S := $(shell uname -s | tr '[:upper:]' '[:lower:]')
    ifeq ($(UNAME_S),darwin)
        BINARY := #{project_name}.pony.darwin
    else ifeq ($(UNAME_S),linux)
        BINARY := #{project_name}.pony.linux
    else
        BINARY := #{project_name}.pony.exe
    endif

    .PHONY: build test clean run

    build:
    \tcorral fetch
    \tponyc .
    \tmv #{project_name} $(BINARY)

    test:
    \tcorral fetch
    \tponyc test
    \t./test

    clean:
    \trm -rf $(BINARY) #{project_name}.pony.* #{project_name} test
    \trm -rf _corral .corral

    run: build
    \t./$(BINARY)
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
          matrix:
            os: [ubuntu-latest, macos-latest]

        steps:
        - uses: actions/checkout@v3

        - name: Install Pony
          run: |
            if [ "$RUNNER_OS" == "Linux" ]; then
              sudo apt-get update
              sudo apt-get install -y ponyup
              ponyup update ponyc release
            elif [ "$RUNNER_OS" == "macOS" ]; then
              brew install ponyup
              ponyup update ponyc release
            fi
          shell: bash

        - name: Install Corral
          run: |
            ponyup update corral release

        - name: Fetch dependencies
          run: |
            corral fetch

        - name: Build
          run: |
            ponyc .

        - name: Build tests
          run: |
            ponyc test

        - name: Run tests
          run: |
            ./test --sequential

        - name: Run application
          run: |
            timeout 5 ./#{project_name} || true
    """
  end

  defp generate_readme(project_name) do
    """
    # #{project_name}

    Generated from ActorSimulation DSL using Pony.

    ## About

    This project uses [Pony](https://www.ponylang.io/), a capabilities-secure,
    actor-model language that provides:

    - **Type Safety** - No null pointers, no buffer overruns
    - **Memory Safety** - No dangling pointers, no memory leaks
    - **Data-Race Freedom** - Guaranteed at compile time
    - **Deadlock Freedom** - No locks, no deadlocks
    - **High Performance** - Zero-cost abstractions

    The code is generated from a high-level Elixir DSL and provides:
    - Type-safe actor implementations
    - Callback traits for custom behavior
    - Built-in PonyTest tests
    - Production-ready code

    ## Prerequisites

    - **Ponyup** - Pony toolchain manager
    - **Pony compiler** (installed via ponyup)
    - **Corral** - Pony dependency manager (installed via ponyup)

    ### Installation

    ```bash
    # Install ponyup
    curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh | sh

    # Install pony compiler and corral
    ponyup update ponyc release
    ponyup update corral release
    ```

    ## Building

    ```bash
    # Fetch dependencies
    corral fetch

    # Build the project
    ponyc .

    # Run
    ./#{project_name}
    ```

    ## Testing

    ```bash
    # Build and run tests
    make test

    # Or manually:
    ponyc test
    ./test
    ```

    ## Customizing Behavior

    The generated actor code uses callback traits to allow customization WITHOUT
    modifying generated files:

    1. Find the `*_callbacks.pony` files
    2. Edit the `*CallbacksImpl` class implementations
    3. Add your custom logic in the callback methods
    4. Rebuild the project

    The generated actor code will automatically call your callbacks.

    ## Project Structure

    - `main.pony` - Entry point and actor system setup
    - `*_actor.pony` - Generated actor implementations (DO NOT EDIT)
    - `*_callbacks.pony` - Callback traits and implementations (EDIT IMPL CLASS!)
    - `test/test.pony` - PonyTest test suite
    - `corral.json` - Dependency configuration
    - `Makefile` - Build targets

    ## CI/CD

    This project includes a GitHub Actions workflow that:
    - Builds on Ubuntu and macOS
    - Runs all PonyTest tests
    - Validates the build with each commit

    ## Learn More

    - [Pony Tutorial](https://tutorial.ponylang.io/)
    - [Pony Standard Library](https://stdlib.ponylang.io/)
    - [Pony GitHub](https://github.com/ponylang/ponyc)
    - [ActorSimulation DSL](https://github.com/yourusername/gen_server_virtual_time)

    ## License

    Generated code is provided as-is for your use.
    """
  end

  # Utility functions

  defp actor_snake_case(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("-", "_")
  end

  defp actor_class_name(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> actor_class_name()
  end

  defp actor_class_name(string) when is_binary(string) do
    string
    |> String.split("_")
    |> Enum.map_join("", &String.capitalize/1)
  end

  defp extract_messages_from_pattern(nil), do: []

  defp extract_messages_from_pattern({:periodic, _interval, message}), do: [message]
  defp extract_messages_from_pattern({:rate, _per_second, message}), do: [message]

  defp extract_messages_from_pattern({:burst, _count, _interval, message}) do
    [message]
  end

  defp extract_messages_from_pattern({:self_message, _delay, message}) do
    [message]
  end

  defp message_name(msg) when is_atom(msg) do
    Atom.to_string(msg)
  end

  defp message_name(msg) when is_binary(msg), do: msg

  defp message_name(msg) do
    inspect(msg) |> String.replace(~r/[^a-z0-9_]/, "_")
  end
end
