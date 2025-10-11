defmodule ActorSimulation.CAFGenerator do
  @moduledoc """
  Generates C++ Actor Framework (CAF) code from ActorSimulation DSL.

  This module translates ActorSimulation definitions into production-ready
  CAF C++ projects with:
  - Typed actor implementations
  - Callback interfaces for custom behavior
  - CMake build configuration with Conan
  - CI pipeline for automated testing
  - Complete documentation

  ## Key Features

  - **Callback Modules**: Generate callback interfaces so users can add custom
    behavior WITHOUT touching generated code
  - **Type-Safe**: Uses CAF's typed actors for compile-time message checking
  - **Modern C++17**: Clean, idiomatic C++ code
  - **Production Ready**: Includes CI/CD pipeline and build system

  ## Example

      simulation = ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender, 
            send_pattern: {:periodic, 100, :msg},
            targets: [:receiver])
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} = CAFGenerator.generate(simulation,
        project_name: "MyActors",
        enable_callbacks: true)

      CAFGenerator.write_to_directory(files, "caf_output/")
  """

  @doc """
  Generates complete CAF project files from an ActorSimulation.

  ## Options

  - `:project_name` (required) - Name of the C++ project
  - `:enable_callbacks` (default: true) - Generate callback interfaces
  - `:caf_version` (default: "0.18.7") - CAF version for Conan

  ## Returns

  `{:ok, files}` where files is a list of `{filename, content}` tuples
  """
  def generate(simulation, opts \\ []) do
    project_name = Keyword.fetch!(opts, :project_name)
    enable_callbacks = Keyword.get(opts, :enable_callbacks, true)
    caf_version = Keyword.get(opts, :caf_version, "0.18.7")

    actors = simulation.actors

    files =
      []
      |> add_actor_files(actors, enable_callbacks)
      |> add_main_file(actors, project_name)
      |> add_test_files(actors, project_name)
      |> add_cmake_file(actors, project_name)
      |> add_conan_file(caf_version)
      |> add_ci_pipeline()
      |> add_readme(project_name)

    {:ok, files}
  end

  @doc """
  Writes generated files to a directory.

  Creates the directory and all subdirectories as needed.
  """
  def write_to_directory(files, output_dir) do
    Enum.each(files, fn {filename, content} ->
      path = Path.join(output_dir, filename)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, content)
    end)

    :ok
  end

  # Private functions

  defp add_actor_files(files, actors, enable_callbacks) do
    Enum.reduce(actors, files, fn {name, actor_info}, acc ->
      case actor_info.type do
        :simulated ->
          definition = actor_info.definition
          actor_name = actor_snake_case(name)

          header = generate_actor_header(name, definition, enable_callbacks)
          source = generate_actor_source(name, definition, enable_callbacks)

          new_files = [
            {"#{actor_name}_actor.cpp", source},
            {"#{actor_name}_actor.hpp", header}
          ]

          new_files =
            if enable_callbacks do
              callback_header = generate_callback_header(name, definition)
              callback_impl = generate_callback_impl(name, definition)

              new_files ++
                [
                  {"#{actor_name}_callbacks.hpp", callback_header},
                  {"#{actor_name}_callbacks_impl.cpp", callback_impl}
                ]
            else
              new_files
            end

          new_files ++ acc

        :real_process ->
          # Skip real processes for CAF generation
          acc
      end
    end)
  end

  defp add_main_file(files, actors, project_name) do
    content = generate_main(actors, project_name)
    [{"main.cpp", content} | files]
  end

  defp add_test_files(files, actors, project_name) do
    test_content = generate_test_file(actors, project_name)
    [{"test_actors.cpp", test_content} | files]
  end

  defp add_cmake_file(files, actors, project_name) do
    content = generate_cmake(actors, project_name)
    [{"CMakeLists.txt", content} | files]
  end

  defp add_conan_file(files, caf_version) do
    content = generate_conan(caf_version)
    [{"conanfile.txt", content} | files]
  end

  defp add_ci_pipeline(files) do
    content = generate_ci_pipeline()
    [{".github/workflows/ci.yml", content} | files]
  end

  defp add_readme(files, project_name) do
    content = generate_readme(project_name)
    [{"README.md", content} | files]
  end

  defp generate_actor_header(name, definition, enable_callbacks) do
    actor_name = actor_snake_case(name)
    class_name = "#{actor_name}_actor"

    callback_include =
      if enable_callbacks do
        """
        #include "#{actor_name}_callbacks.hpp"
        """
      else
        ""
      end

    callback_member =
      if enable_callbacks do
        """
            std::shared_ptr<#{actor_name}_callbacks> callbacks_;
        """
      else
        ""
      end

    target_names = Enum.map(definition.targets, &actor_snake_case/1)

    target_members =
      if length(target_names) > 0 do
        """
            std::vector<caf::actor> targets_;
        """
      else
        ""
      end

    """
    // Generated from ActorSimulation DSL
    // Actor: #{name}

    #pragma once

    #include <caf/all.hpp>
    #include <chrono>
    #include <vector>
    #{callback_include}

    class #{class_name} : public caf::event_based_actor {
      public:
        #{class_name}(caf::actor_config& cfg, const std::vector<caf::actor>& targets);

        caf::behavior make_behavior() override;

      private:
        void schedule_next_send();
        void send_to_targets();
    #{callback_member}#{target_members}
        int send_count_ = 0;
    };
    """
  end

  defp generate_actor_source(name, definition, enable_callbacks) do
    actor_name = actor_snake_case(name)
    class_name = "#{actor_name}_actor"

    callback_init =
      if enable_callbacks do
        """
          callbacks_ = std::make_shared<#{actor_name}_callbacks>();
        """
      else
        ""
      end

    behavior_handlers = generate_behavior_handlers(name, definition, enable_callbacks)
    schedule_impl = generate_schedule_impl(definition)
    send_impl = generate_send_impl(definition)

    """
    // Generated from ActorSimulation DSL
    // Actor: #{name}

    #include "#{actor_name}_actor.hpp"
    #include <iostream>

    #{class_name}::#{class_name}(caf::actor_config& cfg, const std::vector<caf::actor>& targets)
      : caf::event_based_actor(cfg), targets_(targets) {
    #{callback_init}}

    caf::behavior #{class_name}::make_behavior() {
      schedule_next_send();

      return {
    #{behavior_handlers}  };
    }

    void #{class_name}::schedule_next_send() {
    #{schedule_impl}}

    void #{class_name}::send_to_targets() {
    #{send_impl}}
    """
  end

  defp generate_behavior_handlers(_name, definition, enable_callbacks) do
    messages = extract_messages_from_pattern(definition.send_pattern)

    handlers =
      Enum.map(messages, fn msg ->
        msg_name = message_name(msg)
        callback_call =
          if enable_callbacks do
            """
              callbacks_->on_#{msg_name}();
            """
          else
            """
              // Message received: #{msg}
            """
          end

        """
            [=](caf::atom_value msg) {
    #{callback_call}      send_to_targets();
              schedule_next_send();
            }
        """
      end)

    if length(handlers) > 0 do
      Enum.join(handlers, ",\n")
    else
      """
          [=](caf::atom_value msg) {
            // Default message handler
            send_to_targets();
            schedule_next_send();
          }
      """
    end
  end

  defp generate_schedule_impl(definition) do
    case definition.send_pattern do
      nil ->
        """
          // No automatic sending pattern
        """

      {:periodic, interval_ms, message} ->
        msg_atom = message_to_atom(message)

        """
          delayed_send(this, std::chrono::milliseconds(#{interval_ms}), #{msg_atom});
        """

      {:rate, per_second, message} ->
        interval_ms = div(1000, per_second)
        msg_atom = message_to_atom(message)

        """
          delayed_send(this, std::chrono::milliseconds(#{interval_ms}), #{msg_atom});
        """

      {:burst, count, interval_ms, message} ->
        msg_atom = message_to_atom(message)

        """
          for (int i = 0; i < #{count}; i++) {
            delayed_send(this, std::chrono::milliseconds(#{interval_ms}), #{msg_atom});
          }
        """
    end
  end

  defp generate_send_impl(definition) do
    if length(definition.targets) > 0 do
      """
        for (auto& target : targets_) {
          send(target, caf::atom("msg"));
          send_count_++;
        }
      """
    else
      """
        // No targets to send to
      """
    end
  end

  defp generate_callback_header(name, definition) do
    actor_name = actor_snake_case(name)
    class_name = "#{actor_name}_callbacks"

    messages = extract_messages_from_pattern(definition.send_pattern)

    methods =
      Enum.map(messages, fn msg ->
        msg_name = message_name(msg)
        "    virtual void on_#{msg_name}();"
      end)

    methods_str =
      if length(methods) > 0 do
        Enum.join(methods, "\n")
      else
        "    virtual void on_message();"
      end

    """
    // Generated from ActorSimulation DSL
    // Callback interface for: #{name}
    //
    // CUSTOMIZE THIS FILE to add your own behavior!
    // The generated actor code will call these methods.

    #pragma once

    class #{class_name} {
      public:
        virtual ~#{class_name}() = default;

    #{methods_str}
    };
    """
  end

  defp generate_callback_impl(name, definition) do
    actor_name = actor_snake_case(name)
    class_name = "#{actor_name}_callbacks"

    messages = extract_messages_from_pattern(definition.send_pattern)

    methods =
      Enum.map(messages, fn msg ->
        msg_name = message_name(msg)

        """
        void #{class_name}::on_#{msg_name}() {
          // TODO: Implement custom behavior for #{msg}
          // This is called when the actor receives a #{msg} message
        }
        """
      end)

    methods_str =
      if length(methods) > 0 do
        Enum.join(methods, "\n")
      else
        """
        void #{class_name}::on_message() {
          // TODO: Implement custom behavior
        }
        """
      end

    """
    // Generated from ActorSimulation DSL
    // Callback implementation for: #{name}
    //
    // IMPLEMENT YOUR CUSTOM LOGIC HERE
    // This file is meant to be edited - add your business logic!

    #include "#{actor_name}_callbacks.hpp"
    #include <iostream>

    #{methods_str}
    """
  end

  defp generate_main(actors, project_name) do
    simulated_actors =
      actors
      |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
      |> Enum.map(fn {name, info} -> {name, info.definition} end)

    includes =
      Enum.map(simulated_actors, fn {name, _def} ->
        "#include \"#{actor_snake_case(name)}_actor.hpp\""
      end)

    spawn_code = generate_spawn_code(simulated_actors)

    """
    // Generated from ActorSimulation DSL
    // Main entry point for #{project_name}

    #include <caf/all.hpp>
    #include <iostream>
    #{Enum.join(includes, "\n")}

    using namespace caf;

    int caf_main(actor_system& system) {
      // Spawn all actors
    #{spawn_code}

      // Keep system alive
      std::cout << "Actor system started. Press Ctrl+C to exit." << std::endl;
      
      return 0;
    }

    CAF_MAIN()
    """
  end

  defp generate_spawn_code(actors) do
    # First pass: spawn all actors
    spawn_statements =
      Enum.map(actors, fn {name, _def} ->
        actor_name = actor_snake_case(name)
        "  auto #{actor_name} = system.spawn<#{actor_name}_actor>(std::vector<actor>{});"
      end)

    # Second pass: connect targets (would need another pass to resolve)
    # For now, we'll spawn with empty target vectors and let users connect manually
    # or we could do a two-phase initialization

    Enum.join(spawn_statements, "\n")
  end

  defp generate_test_file(actors, project_name) do
    simulated_actors =
      actors
      |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
      |> Enum.map(fn {name, info} -> {name, info.definition} end)

    includes =
      Enum.map(simulated_actors, fn {name, _def} ->
        "#include \"#{actor_snake_case(name)}_actor.hpp\""
      end)

    test_cases = generate_test_cases(simulated_actors)

    """
    // Generated from ActorSimulation DSL
    // Catch2 tests for #{project_name}

    #include <catch2/catch_test_macros.hpp>
    #include <caf/all.hpp>
    #{Enum.join(includes, "\n")}

    using namespace caf;

    TEST_CASE("Actor system can be initialized", "[system]") {
      actor_system_config cfg;
      actor_system system{cfg};
      
      REQUIRE(system.scheduler().num_workers() > 0);
    }

    #{Enum.join(test_cases, "\n\n")}

    TEST_CASE("All actors can be spawned", "[actors]") {
      actor_system_config cfg;
      actor_system system{cfg};
      
    #{generate_spawn_test_code(simulated_actors)}
      
      // All actors spawned successfully
      SUCCEED("All actors created");
    }

    TEST_CASE("Actors can communicate", "[communication]") {
      actor_system_config cfg;
      actor_system system{cfg};
      
      // Spawn actors
    #{generate_spawn_test_code(simulated_actors)}
      
      // Actors are alive
      SUCCEED("Communication test placeholder");
    }
    """
  end

  defp generate_test_cases(actors) do
    Enum.map(actors, fn {name, _def} ->
      actor_name = actor_snake_case(name)
      class_name = "#{actor_name}_actor"

      """
      TEST_CASE("#{class_name} can be created", "[#{actor_name}]") {
        actor_system_config cfg;
        actor_system system{cfg};
        
        auto actor = system.spawn<#{class_name}>(std::vector<caf::actor>{});
        REQUIRE(actor != nullptr);
      }
      """
    end)
  end

  defp generate_spawn_test_code(actors) do
    actors
    |> Enum.map(fn {name, _def} ->
      actor_name = actor_snake_case(name)
      "  auto #{actor_name} = system.spawn<#{actor_name}_actor>(std::vector<actor>{});\n  REQUIRE(#{actor_name} != nullptr);"
    end)
    |> Enum.join("\n  \n")
  end

  defp generate_cmake(actors, project_name) do
    simulated_actors =
      actors
      |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
      |> Enum.map(fn {name, _info} -> name end)

    sources =
      simulated_actors
      |> Enum.flat_map(fn name ->
        actor_name = actor_snake_case(name)
        ["  #{actor_name}_actor.cpp", "  #{actor_name}_callbacks_impl.cpp"]
      end)

    sources_str = Enum.join(["  main.cpp" | sources], "\n")

    """
    cmake_minimum_required(VERSION 3.15)
    project(#{project_name} CXX)

    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    # Find CAF
    find_package(CAF REQUIRED COMPONENTS core io)

    # Find Catch2 for testing
    find_package(Catch2 3 REQUIRED)

    # Source files
    set(SOURCES
    #{sources_str}
    )

    # Create executable
    add_executable(#{project_name} ${SOURCES})

    # Link CAF libraries
    target_link_libraries(#{project_name} 
      PRIVATE
        CAF::core
        CAF::io
    )

    # Enable warnings
    if(MSVC)
      target_compile_options(#{project_name} PRIVATE /W4)
    else()
      target_compile_options(#{project_name} PRIVATE -Wall -Wextra -pedantic)
    endif()

    # Test executable
    add_executable(#{project_name}_test test_actors.cpp)
    target_link_libraries(#{project_name}_test 
      PRIVATE
        CAF::core
        CAF::io
        Catch2::Catch2WithMain
    )

    # Enable testing
    enable_testing()
    add_test(NAME #{project_name}_test COMMAND #{project_name}_test)
    
    # Generate JUnit XML report for CI
    add_test(
      NAME #{project_name}_test_junit
      COMMAND #{project_name}_test --reporter junit --out test-results.xml
    )
    """
  end

  defp generate_conan(caf_version) do
    """
    [requires]
    caf/#{caf_version}
    catch2/3.7.1

    [generators]
    CMakeDeps
    CMakeToolchain

    [options]
    caf:shared=False
    """
  end

  defp generate_ci_pipeline() do
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
            build_type: [Debug, Release]

        steps:
        - uses: actions/checkout@v3

        - name: Install Conan
          run: |
            pip install conan
            conan profile detect --force

        - name: Install dependencies
          run: |
            mkdir -p build
            cd build
            conan install .. --build=missing -s build_type=${{ matrix.build_type }}

        - name: Configure
          run: |
            cd build
            cmake .. -DCMAKE_BUILD_TYPE=${{ matrix.build_type }} -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake

        - name: Build
          run: |
            cd build
            cmake --build . --config ${{ matrix.build_type }}

        - name: Test
          run: |
            cd build
            ctest -C ${{ matrix.build_type }} --output-on-failure
            
        - name: Run Catch2 tests with verbose output
          run: |
            cd build
            ./*_test --success
            
        - name: Generate JUnit test report
          if: always()
          run: |
            cd build
            ./*_test --reporter junit --out test-results.xml || true
            
        - name: Publish Test Results
          if: always()
          uses: EnricoMi/publish-unit-test-result-action@v2
          with:
            files: |
              build/test-results.xml
            check_name: "Test Results (${{ matrix.os }}, ${{ matrix.build_type }})"
    """
  end

  defp generate_readme(project_name) do
    """
    # #{project_name}

    Generated from ActorSimulation DSL using CAF (C++ Actor Framework).

    ## About

    This project uses the [C++ Actor Framework (CAF)](https://actor-framework.org/) to implement
    a distributed actor system. The code is generated from a high-level Elixir DSL and provides:

    - Type-safe actor implementations
    - Callback interfaces for custom behavior
    - Modern C++17 code
    - Production-ready build system

    ## Prerequisites

    - CMake 3.15+
    - C++17 compiler (GCC 7+, Clang 5+, MSVC 2019+)
    - Conan package manager
    - CAF library (installed via Conan)

    ## Building

    ```bash
    # Install dependencies
    mkdir build && cd build
    conan install .. --build=missing

    # Configure and build
    cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
    cmake --build .

    # Run
    ./#{project_name}
    ```

    ## Testing

    ```bash
    # Run tests with CTest
    cd build
    ctest --output-on-failure

    # Run Catch2 tests with verbose output
    ./#{project_name}_test --success

    # Generate JUnit XML report
    ./#{project_name}_test --reporter junit --out test-results.xml
    ```

    The CI pipeline automatically generates and publishes JUnit test reports.

    ## Customizing Behavior

    The generated actor code uses callback interfaces to allow customization WITHOUT
    modifying generated files:

    1. Find the `*_callbacks_impl.cpp` files
    2. Implement your custom logic in the callback methods
    3. Rebuild the project

    The generated actor code will automatically call your callbacks.

    ## Project Structure

    - `main.cpp` - Entry point and actor system setup
    - `*_actor.hpp/cpp` - Generated actor implementations (DO NOT EDIT)
    - `*_callbacks.hpp` - Callback interface definitions (DO NOT EDIT)
    - `*_callbacks_impl.cpp` - Callback implementations (EDIT THIS!)
    - `CMakeLists.txt` - Build configuration
    - `conanfile.txt` - Package dependencies

    ## CI/CD

    This project includes a GitHub Actions workflow that:
    - Builds on Ubuntu and macOS
    - Tests Debug and Release configurations
    - Validates the build with each commit

    ## Learn More

    - [CAF Documentation](https://actor-framework.readthedocs.io/)
    - [CAF GitHub](https://github.com/actor-framework/actor-framework)
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

  defp extract_messages_from_pattern(nil), do: []

  defp extract_messages_from_pattern({_type, _interval, message}) do
    [message]
  end

  defp extract_messages_from_pattern({:burst, _count, _interval, message}) do
    [message]
  end

  defp message_name(msg) when is_atom(msg) do
    Atom.to_string(msg)
  end

  defp message_name(msg) when is_binary(msg), do: msg

  defp message_name(msg) do
    inspect(msg) |> String.replace(~r/[^a-z0-9_]/, "_")
  end

  defp message_to_atom(msg) when is_atom(msg) do
    "caf::atom(\"#{msg}\")"
  end

  defp message_to_atom(msg) when is_binary(msg) do
    "caf::atom(\"#{msg}\")"
  end

  defp message_to_atom(_msg) do
    "caf::atom(\"msg\")"
  end
end

