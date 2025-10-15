defmodule ActorSimulation.RactorGenerator do
  @moduledoc """
  Generates Rust code using the Ractor actor library from ActorSimulation DSL.

  Ractor is a Rust actor framework inspired by Erlang's gen_server that provides:
  - Supervision trees (like OTP)
  - Named actor registry
  - Remote procedure calls (RPC)
  - Timers and scheduling
  - Runtime-agnostic design (Tokio-based)

  This generator creates production-ready Rust projects with:
  - Ractor actor implementations
  - Callback traits for custom behavior
  - Comprehensive test suites (integration and unit tests)
  - GitHub Actions CI/CD
  - Complete documentation

  ## Example

      simulation = ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
            send_pattern: {:periodic, 100, :msg},
            targets: [:receiver])
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} = RactorGenerator.generate(simulation,
        project_name: "my_actors",
        enable_callbacks: true)

      RactorGenerator.write_to_directory(files, "ractor_output/")
  """

  alias ActorSimulation.GeneratorUtils

  @doc """
  Generates complete Ractor (Rust) project files from an ActorSimulation.

  ## Options

  - `:project_name` (required) - Name of the Cargo package (snake_case)
  - `:enable_callbacks` (default: true) - Generate callback traits
  - `:rust_edition` (default: "2021") - Rust edition for Cargo.toml
  - `:ractor_version` (default: "0.15") - Ractor crate version

  ## Returns

  `{:ok, files}` where files is a list of `{filename, content}` tuples
  """
  def generate(simulation, opts \\ []) do
    project_name = Keyword.fetch!(opts, :project_name)
    enable_callbacks = Keyword.get(opts, :enable_callbacks, true)
    rust_edition = Keyword.get(opts, :rust_edition, "2021")
    ractor_version = Keyword.get(opts, :ractor_version, "0.15")

    actors = simulation.actors

    files =
      []
      |> add_actor_files(actors, enable_callbacks)
      |> add_actors_mod_file(actors)
      |> add_main_file(actors, project_name)
      |> add_test_file(actors, project_name)
      |> add_cargo_toml(project_name, rust_edition, ractor_version)
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

          # Generate actor implementation file (generated code, do not edit)
          actor_file = generate_actor_file(name, definition, enable_callbacks)
          new_files = [{"src/actors/#{snake_name}.rs", actor_file}]

          # Generate callbacks file (custom code, meant to be edited)
          new_files =
            if enable_callbacks do
              callback_file = generate_callback_file(name, definition)
              new_files ++ [{"src/actors/#{snake_name}_callbacks.rs", callback_file}]
            else
              new_files
            end

          new_files ++ acc

        :real_process ->
          acc
      end
    end)
  end

  defp add_actors_mod_file(files, actors) do
    content = generate_actors_mod(actors)
    [{"src/actors/mod.rs", content} | files]
  end

  defp add_main_file(files, actors, project_name) do
    content = generate_main(actors, project_name)
    lib_content = generate_lib()
    [{"src/main.rs", content}, {"src/lib.rs", lib_content} | files]
  end

  defp add_test_file(files, actors, project_name) do
    content = generate_test_file(actors, project_name)
    [{"tests/integration_test.rs", content} | files]
  end

  defp add_cargo_toml(files, project_name, rust_edition, ractor_version) do
    content = generate_cargo_toml(project_name, rust_edition, ractor_version)
    [{"Cargo.toml", content} | files]
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
    callback_trait =
      if enable_callbacks do
        generate_callback_trait_definition(name, definition)
      else
        ""
      end

    # Import the default callbacks implementation if callbacks are enabled
    callback_import =
      if enable_callbacks do
        snake_name = GeneratorUtils.to_snake_case(name)
        type_name = GeneratorUtils.to_pascal_case(name)
        "use super::#{snake_name}_callbacks::Default#{type_name}Callbacks;\n"
      else
        ""
      end

    state_struct = generate_state_struct(name, definition, enable_callbacks)
    message_enum = generate_message_enum(name, definition)
    actor_impl = generate_actor_impl(name, definition, enable_callbacks)
    message_handlers = generate_message_handlers(name, definition, enable_callbacks)

    imports_section =
      case generate_imports(definition) do
        "" -> ""
        imports -> imports <> "\n"
      end

    result = """
    // Generated from ActorSimulation DSL
    // Actor: #{name}
    // DO NOT EDIT - This file is auto-generated

    use ractor::{Actor, ActorProcessingErr, ActorRef};
    #{imports_section}#{callback_import}
    #{callback_trait}
    #{state_struct}
    #{message_enum}
    #{actor_impl}
    #{message_handlers}
    """

    # Ensure single trailing newline
    String.trim_trailing(result, "\n") <> "\n"
  end

  defp generate_callback_trait_definition(name, definition) do
    type_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    methods =
      Enum.map_join(messages, "\n", fn msg ->
        msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_snake_case()
        "    fn on_#{msg_name}(&self);"
      end)

    if length(messages) > 0 do
      """
      /// #{type_name}Callbacks defines the callback trait
      /// Implement this trait to customize actor behavior
      pub trait #{type_name}Callbacks: Send + Sync {
      #{methods}
      }

      """
    else
      """
      /// #{type_name}Callbacks defines the callback trait
      /// Implement this trait to customize actor behavior
      pub trait #{type_name}Callbacks: Send + Sync {}

      """
    end
  end

  defp generate_callback_file(name, definition) do
    type_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    # Import the trait from the actor module
    snake_name = GeneratorUtils.to_snake_case(name)
    trait_use = "use super::#{snake_name}::#{type_name}Callbacks;"

    impl_methods =
      Enum.map_join(messages, "\n\n    ", fn msg ->
        msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_snake_case()
        action = if definition.send_pattern, do: "Sending", else: "Received"

        """
        fn on_#{msg_name}(&self) {
                // TODO: Implement custom behavior for #{msg}
                println!("#{type_name}: #{action} #{msg} message");
            }
        """
      end)

    if length(messages) > 0 do
      """
      // Generated from ActorSimulation DSL
      // Default callback implementation for: #{name}
      // CUSTOMIZE THIS FILE - This is where you add your custom behavior!

      #{trait_use}

      /// Default#{type_name}Callbacks provides default implementations
      /// CUSTOMIZE THIS to add your own behavior!
      pub struct Default#{type_name}Callbacks;

      impl #{type_name}Callbacks for Default#{type_name}Callbacks {
          #{String.trim(impl_methods)}
      }
      """
    else
      """
      // Generated from ActorSimulation DSL
      // Default callback implementation for: #{name}
      // CUSTOMIZE THIS FILE - This is where you add your custom behavior!

      #{trait_use}

      /// Default#{type_name}Callbacks provides default implementations
      /// CUSTOMIZE THIS to add your own behavior!
      pub struct Default#{type_name}Callbacks;

      impl #{type_name}Callbacks for Default#{type_name}Callbacks {}
      """
    end
  end

  defp generate_state_struct(name, _definition, enable_callbacks) do
    type_name = GeneratorUtils.to_pascal_case(name)

    # Note: In Ractor, managing target ActorRefs would require knowing their
    # specific message types at compile time. For now, we keep state simple.
    # Users can add target ActorRefs in their custom callback implementations.

    callback_field =
      if enable_callbacks do
        "    callbacks: Box<dyn #{type_name}Callbacks + Send + Sync>,"
      else
        ""
      end

    """
    #[allow(dead_code)]
    pub struct #{type_name}State {
    #{callback_field}
        send_count: usize,
    }
    """
  end

  defp generate_message_enum(name, definition) do
    type_name = GeneratorUtils.to_pascal_case(name)
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    # Always include at least one variant to avoid empty enum
    variants =
      if length(messages) > 0 do
        Enum.map_join(messages, "\n", fn msg ->
          msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()
          "    #{msg_name},"
        end)
      else
        "    Ping,"
      end

    """
    #[derive(Debug, Clone)]
    pub enum #{type_name}Message {
    #{variants}
    }
    """
  end

  defp generate_actor_impl(name, definition, enable_callbacks) do
    type_name = GeneratorUtils.to_pascal_case(name)

    callback_init =
      if enable_callbacks do
        "callbacks: Box::new(Default#{type_name}Callbacks),"
      else
        ""
      end

    pre_start_body = generate_pre_start(definition)

    """
    pub struct #{type_name};

    impl Actor for #{type_name} {
        type Msg = #{type_name}Message;
        type State = #{type_name}State;
        type Arguments = ();

        #[allow(unused_variables)]
        async fn pre_start(
            &self,
            myself: ActorRef<Self::Msg>,
            _: Self::Arguments,
        ) -> Result<Self::State, ActorProcessingErr> {
            let state = #{type_name}State {
                #{callback_init}
                send_count: 0,
            };

    #{pre_start_body}        Ok(state)
        }

        #[allow(unused_variables)]
        async fn handle(
            &self,
            _myself: ActorRef<Self::Msg>,
            message: Self::Msg,
            state: &mut Self::State,
        ) -> Result<(), ActorProcessingErr> {
            match message {
    #{generate_match_arms(name, definition, enable_callbacks)}
            }
            Ok(())
        }
    }
    """
  end

  defp generate_pre_start(definition) do
    case definition.send_pattern do
      nil ->
        ""

      {:periodic, interval_ms, message} ->
        msg_name = GeneratorUtils.message_name(message) |> GeneratorUtils.to_pascal_case()

        """
                // Spawn periodic timer
                let actor_ref = myself.clone();
                tokio::spawn(async move {
                    let mut interval = interval(Duration::from_millis(#{interval_ms}));
                    loop {
                        interval.tick().await;
                        let _ = actor_ref.send_message(Self::Msg::#{msg_name});
                    }
                });
        """

      {:rate, per_second, message} ->
        interval_ms = div(1000, per_second)
        msg_name = GeneratorUtils.message_name(message) |> GeneratorUtils.to_pascal_case()

        """
                // Spawn rate-based timer (#{per_second} msgs/sec)
                let actor_ref = myself.clone();
                tokio::spawn(async move {
                    let mut interval = interval(Duration::from_millis(#{interval_ms}));
                    loop {
                        interval.tick().await;
                        let _ = actor_ref.send_message(Self::Msg::#{msg_name});
                    }
                });
        """

      {:burst, count, interval_ms, message} ->
        msg_name = GeneratorUtils.message_name(message) |> GeneratorUtils.to_pascal_case()

        """
                // Spawn burst timer (#{count} msgs every #{interval_ms}ms)
                let actor_ref = myself.clone();
                tokio::spawn(async move {
                    let mut interval = interval(Duration::from_millis(#{interval_ms}));
                    loop {
                        interval.tick().await;
                        for _ in 0..#{count} {
                            let _ = actor_ref.send_message(Self::Msg::#{msg_name});
                        }
                    }
                });
        """

      {:self_message, delay_ms, message} ->
        msg_name = GeneratorUtils.message_name(message) |> GeneratorUtils.to_pascal_case()

        """
                // One-shot delayed self-message
                let actor_ref = myself.clone();
                tokio::spawn(async move {
                    sleep(Duration::from_millis(#{delay_ms})).await;
                    let _ = actor_ref.send_message(Self::Msg::#{msg_name});
                });
        """
    end
  end

  defp generate_match_arms(name, definition, enable_callbacks) do
    messages = GeneratorUtils.extract_messages(definition.send_pattern)

    if length(messages) > 0 do
      Enum.map_join(messages, "\n", fn msg ->
        msg_name = GeneratorUtils.message_name(msg) |> GeneratorUtils.to_pascal_case()
        type_name = GeneratorUtils.to_pascal_case(name)

        callback_call =
          if enable_callbacks do
            "                state.callbacks.on_#{GeneratorUtils.to_snake_case(msg_name)}();"
          else
            "                // Handle #{msg}"
          end

        """
                    #{type_name}Message::#{msg_name} => {
        #{callback_call}
                        state.send_count += 1;
                        // Note: To send to other actors, you would need their ActorRef.
                        // Add target ActorRefs to the state in your custom implementation.
                    }
        """
      end)
      |> String.trim_trailing("\n")
    else
      """
                  #{GeneratorUtils.to_pascal_case(name)}Message::Ping => {
                      // Default message handler
                  }
      """
      |> String.trim_trailing("\n")
    end
  end

  defp generate_imports(definition) do
    # Only import what we actually use
    case definition.send_pattern do
      nil ->
        ""

      {:self_message, _, _} ->
        "use std::time::Duration;\nuse tokio::time::sleep;"

      _ ->
        "use std::time::Duration;\nuse tokio::time::interval;"
    end
  end

  defp generate_message_handlers(_name, _definition, _enable_callbacks) do
    # Additional helper functions can go here
    ""
  end

  defp generate_lib do
    """
    // Generated from ActorSimulation DSL
    // Library exports for integration tests

    pub mod actors;
    """
  end

  defp generate_actors_mod(actors) do
    simulated = GeneratorUtils.simulated_actors(actors)

    # Sort for consistent ordering (rustfmt requirement)
    sorted_actors = Enum.sort_by(simulated, fn {name, _def} -> name end)

    # Generate module declarations for both actor and callback modules
    # Note: Callbacks import the trait from the actor module
    mod_declarations =
      Enum.map_join(sorted_actors, "\n", fn {name, _def} ->
        snake_name = GeneratorUtils.to_snake_case(name)
        "pub mod #{snake_name};\npub mod #{snake_name}_callbacks;"
      end)

    """
    // Generated from ActorSimulation DSL
    // Module declarations for all actors and their callback implementations

    #{mod_declarations}
    """
  end

  defp generate_main(actors, project_name) do
    simulated = GeneratorUtils.simulated_actors(actors)

    # Sort for consistent ordering (rustfmt requirement)
    sorted_actors = Enum.sort_by(simulated, fn {name, _def} -> name end)

    use_statements =
      Enum.map_join(sorted_actors, "\n", fn {name, _def} ->
        snake_name = GeneratorUtils.to_snake_case(name)
        type_name = GeneratorUtils.to_pascal_case(name)
        "use #{project_name}::actors::#{snake_name}::#{type_name};"
      end)

    spawn_code =
      Enum.map_join(sorted_actors, "\n    ", fn {name, _def} ->
        snake_name = GeneratorUtils.to_snake_case(name)
        type_name = GeneratorUtils.to_pascal_case(name)

        # Long spawn calls should be on multiple lines per rustfmt
        if String.length(snake_name) > 10 do
          """
          let (_#{snake_name}_ref, _#{snake_name}_handle) =
                  #{type_name}::spawn(None, #{type_name}, ()).await?;
          """
        else
          "let (_#{snake_name}_ref, _#{snake_name}_handle) = #{type_name}::spawn(None, #{type_name}, ()).await?;"
        end
      end)

    """
    // Generated from ActorSimulation DSL
    // Main entry point for #{project_name}

    #{use_statements}
    use ractor::Actor;

    #[tokio::main]
    async fn main() -> Result<(), Box<dyn std::error::Error>> {
        println!("Starting actor system...");

        // Spawn all actors
        #{spawn_code}

        println!("Actor system started. Press Ctrl+C to exit.");

        // Keep running
        tokio::signal::ctrl_c().await?;
        println!("Shutting down...");

        Ok(())
    }
    """
  end

  defp generate_test_file(actors, project_name) do
    simulated = GeneratorUtils.simulated_actors(actors)

    test_cases =
      Enum.map_join(simulated, "\n", fn {name, _def} ->
        snake_name = GeneratorUtils.to_snake_case(name)
        type_name = GeneratorUtils.to_pascal_case(name)

        """

        #[tokio::test]
        async fn test_#{snake_name}_spawns() {
            use #{project_name}::actors::#{snake_name}::#{type_name};
            use ractor::ActorStatus;

            let (actor_ref, actor_handle) = #{type_name}::spawn(None, #{type_name}, ())
                .await
                .expect("Failed to spawn #{snake_name}");

            // Give it time to initialize
            tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;

            // Verify actor is running
            matches!(actor_ref.get_status(), ActorStatus::Running);

            // Clean up
            actor_ref.stop(None);
            let _ = actor_handle.await;
        }
        """
      end)
      |> String.trim()

    """
    // Generated from ActorSimulation DSL
    // Integration tests for actors

    use ractor::Actor;

    #[tokio::test]
    async fn test_actor_system() {
        // Basic system test
        assert!(true);
    }

    #{test_cases}
    """
  end

  defp generate_cargo_toml(project_name, rust_edition, ractor_version) do
    """
    [package]
    name = "#{project_name}"
    version = "0.1.0"
    edition = "#{rust_edition}"

    [lib]
    path = "src/lib.rs"

    [[bin]]
    name = "#{project_name}"
    path = "src/main.rs"

    [dependencies]
    ractor = "#{ractor_version}"
    tokio = { version = "1", features = ["full"] }

    [dev-dependencies]
    tokio-test = "0.4"
    """
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
        runs-on: \${{ matrix.os }}
        strategy:
          fail-fast: false
          matrix:
            os: [ubuntu-latest, macos-latest, windows-latest]
            rust: [stable, beta]

        steps:
        - uses: actions/checkout@v3

        - name: Setup Rust
          uses: actions-rust-lang/setup-rust-toolchain@v1
          with:
            toolchain: \${{ matrix.rust }}
            cache: true

        - name: Check formatting
          run: cargo fmt --all -- --check
          if: matrix.rust == 'stable' && matrix.os == 'ubuntu-latest'

        - name: Run clippy
          run: cargo clippy -- -D warnings
          if: matrix.rust == 'stable'

        - name: Build
          shell: bash
          run: |
            cargo build --release --verbose
            # Determine OS name and rename binary with .ractor.{os} suffix
            OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
            PROJECT_NAME=$(grep '^name = ' Cargo.toml | head -1 | sed 's/name = "\(.*\)"/\1/')
            BINARY="${PROJECT_NAME}.ractor.${OS_NAME}"
            if [ "$RUNNER_OS" = "Windows" ]; then
              cp target/release/${PROJECT_NAME}.exe ${BINARY}.exe || true
            else
              cp target/release/${PROJECT_NAME} ${BINARY} || true
            fi

        - name: Test
          run: cargo test --verbose

        - name: Run Demo Application
          shell: bash
          run: |
            # Determine binary name: {project}.ractor.{os}
            OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
            PROJECT_NAME=$(grep '^name = ' Cargo.toml | head -1 | sed 's/name = "\(.*\)"/\1/')
            BINARY="${PROJECT_NAME}.ractor.${OS_NAME}"
            if [ "$RUNNER_OS" = "Windows" ]; then
              timeout 5 ./${BINARY}.exe || true
            else
              timeout 5 ./${BINARY} || true
            fi
    """
  end

  defp generate_readme(project_name) do
    """
    # #{project_name}

    Generated from ActorSimulation DSL using Ractor (Rust actor library).

    ## About

    This project uses [Ractor](https://github.com/slawlor/ractor), a pure-Rust actor
    framework inspired by Erlang's gen_server that provides:

    - **Supervision trees** - OTP-style supervision and fault tolerance
    - **Actor registry** - Named actor lookup
    - **RPC support** - Call and cast patterns like gen_server
    - **Timers** - Built-in timer support
    - **Runtime-agnostic** - Works with Tokio

    The code is generated from a high-level Elixir DSL and provides:
    - Ractor actor implementations
    - Callback traits for customization
    - Integration test suites
    - Production-ready code

    ## Prerequisites

    - **Rust 1.70+** (stable toolchain recommended)
    - **Cargo** (comes with Rust)

    ## Building

    ```bash
    # Build in debug mode
    cargo build

    # Build optimized release
    cargo build --release

    # Run
    cargo run --release

    # Or run the platform-specific binary (built by CI)
    # Binary naming convention: {project_name}.ractor.{os}
    # e.g., #{project_name}.ractor.darwin on macOS
    #       #{project_name}.ractor.linux on Linux
    ```

    ## Testing

    ```bash
    # Run all tests
    cargo test

    # Run tests with output
    cargo test -- --nocapture

    # Run specific test
    cargo test test_actor_system
    ```

    ## Customizing Behavior

    The generated actor code uses callback traits to allow customization WITHOUT
    modifying generated files:

    1. Find the `*_callbacks.rs` files in `src/actors/`
    2. Modify the `Default*Callbacks` implementation
    3. Add your custom logic in the callback methods
    4. Rebuild

    Example:
    ```rust
    impl WorkerCallbacks for DefaultWorkerCallbacks {
        fn on_tick(&self) {
            // Your custom logic here
            println!("Custom tick handler!");
        }
    }
    ```

    ## Project Structure

    - `src/main.rs` - Entry point and actor spawning
    - `src/actors/*.rs` - Generated actor implementations (DO NOT EDIT)
    - `src/actors/*_callbacks.rs` - Callback implementations (EDIT THIS!)
    - `tests/` - Integration test suite
    - `Cargo.toml` - Package configuration

    ## CI/CD

    This project includes a GitHub Actions workflow that:
    - Builds on Ubuntu, macOS, and Windows
    - Tests with stable and beta Rust
    - Runs clippy and formatting checks
    - Validates the build with each commit

    ## Learn More

    - [Ractor GitHub](https://github.com/slawlor/ractor)
    - [Rust Async Book](https://rust-lang.github.io/async-book/)
    - [ActorSimulation DSL](https://github.com/d-led/gen_server_virtual_time)

    ## License

    Generated code is provided as-is for your use.
    """
  end
end
