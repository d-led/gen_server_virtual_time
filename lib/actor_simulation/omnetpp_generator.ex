defmodule ActorSimulation.OMNeTPPGenerator do
  @moduledoc """
  Generates OMNeT++ C++ simulation code from ActorSimulation DSL.

  This module translates ActorSimulation definitions into complete, buildable
  OMNeT++ projects with:
  - NED network topology files
  - C++ simple module implementations
  - CMake build configuration
  - Conan package management
  - Simulation configuration (INI files)

  ## Example

      simulation = ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
            send_pattern: {:periodic, 100, :msg},
            targets: [:receiver])
        |> ActorSimulation.add_actor(:receiver)

      {:ok, files} = OMNeTPPGenerator.generate(simulation,
        network_name: "SimpleNetwork",
        sim_time_limit: 10)

      OMNeTPPGenerator.write_to_directory(files, "omnetpp_output/")
  """

  @doc """
  Generates complete OMNeT++ project files from an ActorSimulation.

  ## Options

  - `:network_name` (required) - Name of the OMNeT++ network
  - `:sim_time_limit` (default: 10.0) - Simulation duration in seconds

  ## Returns

  `{:ok, files}` where files is a list of `{filename, content}` tuples
  """
  def generate(simulation, opts \\ []) do
    network_name = Keyword.fetch!(opts, :network_name)
    sim_time_limit = Keyword.get(opts, :sim_time_limit, 10.0)

    actors = simulation.actors

    files =
      []
      |> add_ned_file(actors, network_name)
      |> add_cpp_files(actors)
      |> add_cmake_file(actors, network_name)
      |> add_conan_file()
      |> add_ini_file(network_name, sim_time_limit)
      |> add_ci_pipeline(network_name)
      |> add_readme(network_name)

    {:ok, files}
  end

  @doc """
  Writes generated files to a directory.

  Creates the directory if it doesn't exist.
  """
  def write_to_directory(files, output_dir) do
    ActorSimulation.GeneratorUtils.write_to_directory(files, output_dir)
  end

  # Private functions

  defp add_ned_file(files, actors, network_name) do
    content = generate_ned(actors, network_name)
    [{network_name <> ".ned", content} | files]
  end

  defp add_cpp_files(files, actors) do
    Enum.reduce(actors, files, fn {name, actor_info}, acc ->
      case actor_info.type do
        :simulated ->
          class_name = camelize(name)
          header = generate_cpp_header(name, actor_info.definition)
          source = generate_cpp_source(name, actor_info.definition)
          [{class_name <> ".cc", source}, {class_name <> ".h", header} | acc]

        :real_process ->
          # Skip real processes for OMNeT++ generation
          acc
      end
    end)
  end

  defp add_cmake_file(files, actors, network_name) do
    content = generate_cmake(actors, network_name)
    [{"CMakeLists.txt", content} | files]
  end

  defp add_conan_file(files) do
    content = generate_conan()
    [{"conanfile.txt", content} | files]
  end

  defp add_ini_file(files, network_name, sim_time_limit) do
    content = generate_ini(network_name, sim_time_limit)
    [{"omnetpp.ini", content} | files]
  end

  defp generate_ned(actors, network_name) do
    simulated_actors =
      actors
      |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
      |> Enum.map(fn {name, info} -> {name, info.definition} end)

    simple_modules =
      Enum.map(simulated_actors, fn {name, definition} ->
        generate_simple_module(name, definition)
      end)

    network = generate_network_module(simulated_actors, network_name)

    """
    // Generated from ActorSimulation DSL

    #{Enum.join(simple_modules, "\n\n")}

    #{network}
    """
  end

  defp generate_simple_module(name, definition) do
    class_name = camelize(name)
    target_count = length(definition.targets)

    gates =
      if target_count > 0 do
        """
            gates:
                input in;
                output out[#{target_count}];
        """
      else
        """
            gates:
                input in;
        """
      end

    """
    simple #{class_name} {
    #{gates}}
    """
  end

  defp generate_network_module(actors, network_name) do
    submodules =
      Enum.map(actors, fn {name, _definition} ->
        class_name = camelize(name)
        "        #{name}: #{class_name};"
      end)

    connections = generate_connections(actors)

    """
    network #{network_name} {
        submodules:
    #{Enum.join(submodules, "\n")}
        connections:
    #{Enum.join(connections, "\n")}
    }
    """
  end

  defp generate_connections(actors) do
    actors
    |> Enum.flat_map(fn {from_name, definition} ->
      definition.targets
      |> Enum.with_index()
      |> Enum.map(fn {to_name, index} ->
        "        #{from_name}.out[#{index}] --> #{to_name}.in;"
      end)
    end)
  end

  defp generate_cpp_header(name, _definition) do
    class_name = camelize(name)
    guard = String.upcase(class_name) <> "_H"

    """
    // Generated from ActorSimulation DSL
    // Actor: #{name}

    #ifndef #{guard}
    #define #{guard}

    #include <omnetpp.h>

    using namespace omnetpp;

    class #{class_name} : public cSimpleModule {
      private:
        cMessage *selfMsg;
        int sendCount;

      protected:
        virtual void initialize() override;
        virtual void handleMessage(cMessage *msg) override;
        virtual void finish() override;
    };

    #endif
    """
  end

  defp generate_cpp_source(name, definition) do
    class_name = camelize(name)
    initialize_body = generate_initialize(definition)
    handle_message_body = generate_handle_message(definition)

    """
    // Generated from ActorSimulation DSL
    // Actor: #{name}

    #include "#{class_name}.h"

    Define_Module(#{class_name});

    void #{class_name}::initialize() {
        sendCount = 0;
        selfMsg = nullptr;
    #{initialize_body}}

    void #{class_name}::handleMessage(cMessage *msg) {
        if (msg->isSelfMessage()) {
    #{handle_message_body}
        } else {
            // Handle received message
            EV << "Received message: " << msg->getName() << "\\n";
            delete msg;
        }
    }

    void #{class_name}::finish() {
        EV << "#{class_name} sent " << sendCount << " messages\\n";
        if (selfMsg != nullptr) {
            cancelAndDelete(selfMsg);
            selfMsg = nullptr;
        }
    }
    """
  end

  defp generate_initialize(definition) do
    case definition.send_pattern do
      nil ->
        "    // No send pattern defined\n"

      {:self_message, delay_ms, _message} ->
        delay_sec = delay_ms / 1000.0

        """
            // One-shot self-message after delay
            selfMsg = new cMessage("selfMsg");
            scheduleAt(simTime() + #{delay_sec}, selfMsg);
        """

      pattern ->
        interval = pattern_to_interval(pattern)

        """
            selfMsg = new cMessage("selfMsg");
            scheduleAt(simTime() + #{interval}, selfMsg);
        """
    end
  end

  defp generate_handle_message(definition) do
    case definition.send_pattern do
      nil ->
        "        // No send pattern\n"

      {:self_message, _delay_ms, message} ->
        target_count = length(definition.targets)
        msg_name = message_name(message)

        """
                // One-shot self-message - send to targets but don't reschedule
                EV << getName() << ": Processing #{msg_name} message\\n";
                for (int i = 0; i < #{target_count}; i++) {
                    cMessage *outMsg = new cMessage("msg");
                    send(outMsg, "out", i);
                    sendCount++;
                }
                EV << getName() << ": Sent " << #{target_count} << " messages\\n";
                // Do not reschedule (one-shot)
        """

      {:burst, _count, _interval, message} ->
        target_count = length(definition.targets)
        interval = pattern_to_interval(definition.send_pattern)
        msg_name = message_name(message)

        """
                // Send messages
                EV << getName() << ": Processing #{msg_name} message\\n";
                for (int i = 0; i < #{target_count}; i++) {
                    cMessage *outMsg = new cMessage("msg");
                    send(outMsg, "out", i);
                    sendCount++;
                }
                EV << getName() << ": Sent " << #{target_count} << " messages\\n";

                // Reschedule
                scheduleAt(simTime() + #{interval}, msg);
        """

      _other ->
        target_count = length(definition.targets)
        interval = pattern_to_interval(definition.send_pattern)

        """
                // Send messages
                EV << getName() << ": Processing message\\n";
                for (int i = 0; i < #{target_count}; i++) {
                    cMessage *outMsg = new cMessage("msg");
                    send(outMsg, "out", i);
                    sendCount++;
                }
                EV << getName() << ": Sent " << #{target_count} << " messages\\n";

                // Reschedule
                scheduleAt(simTime() + #{interval}, msg);
        """
    end
  end

  defp pattern_to_interval({:periodic, interval_ms, _message}) do
    interval_ms / 1000.0
  end

  defp pattern_to_interval({:rate, per_second, _message}) do
    1.0 / per_second
  end

  defp pattern_to_interval({:burst, _count, interval_ms, _message}) do
    interval_ms / 1000.0
  end

  defp pattern_to_interval({:self_message, delay_ms, _message}) do
    delay_ms / 1000.0
  end

  defp generate_cmake(actors, network_name) do
    simulated_actors =
      actors
      |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
      |> Enum.map(fn {name, _info} -> name end)

    sources =
      simulated_actors
      |> Enum.map_join("\n", fn name -> "    #{camelize(name)}.cc" end)

    """
    cmake_minimum_required(VERSION 3.15)
    project(#{network_name})

    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    # Detect OS for binary naming: {example}.omnetpp.{os}
    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      set(OS_SUFFIX "darwin")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      set(OS_SUFFIX "linux")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
      set(OS_SUFFIX "exe")
    else()
      set(OS_SUFFIX "bin")
    endif()

    # Find OMNeT++
    find_package(OMNeT++ REQUIRED)

    # Source files
    set(SOURCES
    #{sources}
    )

    # Create executable
    add_executable(#{network_name} ${SOURCES})

    # Set output binary name: {example}.omnetpp.{os}
    set_target_properties(#{network_name} PROPERTIES
      OUTPUT_NAME "#{network_name}.omnetpp.${OS_SUFFIX}"
    )

    # Link OMNeT++ libraries
    target_link_libraries(#{network_name}
        ${OMNETPP_LIBRARIES}
    )

    target_include_directories(#{network_name} PRIVATE
        ${OMNETPP_INCLUDE_DIRS}
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
    """
  end

  defp generate_conan do
    """
    [requires]
    # Add dependencies here

    [generators]
    CMakeDeps
    CMakeToolchain
    """
  end

  defp generate_ini(network_name, sim_time_limit) do
    """
    [General]
    network = #{network_name}
    sim-time-limit = #{sim_time_limit}s

    # Logging
    cmdenv-express-mode = true
    cmdenv-autoflush = true
    cmdenv-status-frequency = 1s

    # Random seed
    seed-set = 0
    """
  end

  defp add_ci_pipeline(files, network_name) do
    content = generate_ci_pipeline(network_name)
    [{".github/workflows/ci.yml", content} | files]
  end

  defp add_readme(files, network_name) do
    content = generate_readme(network_name)
    [{"README.md", content} | files]
  end

  defp generate_ci_pipeline(_network_name) do
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

        - name: Install CMake
          run: |
            if [ "$RUNNER_OS" == "Linux" ]; then
              sudo apt-get update
              sudo apt-get install -y cmake
            elif [ "$RUNNER_OS" == "macOS" ]; then
              brew install cmake
            fi
          shell: bash

        - name: Install OMNeT++
          run: |
            # Note: This is a placeholder. In practice, OMNeT++ installation
            # requires more setup. Consider using a pre-built Docker image
            # or caching the installation.
            echo "OMNeT++ would be installed here"
            echo "For CI, consider using omnetpp/omnetpp-circle Docker image"
          shell: bash

        - name: Configure
          run: |
            mkdir -p build
            cd build
            cmake ..

        - name: Build
          run: |
            cd build
            cmake --build .

        - name: Run Demo Simulation
          run: |
            cd build
            # Determine binary name: {project}.omnetpp.{os}
            OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
            PROJECT_NAME=$(grep -o 'project([^)]*)' ../CMakeLists.txt | head -1 | sed 's/project(\\([^ ]*\\).*/\\1/')
            BINARY="${PROJECT_NAME}.omnetpp.${OS_NAME}"
            # Run simulation with config from omnetpp.ini
            if [ -f "../omnetpp.ini" ]; then
              ./"${BINARY}" -u Cmdenv -c General -n ..
            fi
    """
  end

  defp generate_readme(network_name) do
    """
    # #{network_name}

    Generated from ActorSimulation DSL using OMNeT++.

    ## About

    This project uses [OMNeT++](https://omnetpp.org/), a discrete event simulation
    framework that provides:

    - **Network topology definition** (NED files)
    - **Event-driven simulation** engine
    - **Message passing** between modules
    - **Statistics collection** and analysis
    - **Graphical and command-line** interfaces

    The code is generated from a high-level Elixir DSL and provides:
    - OMNeT++ simple modules (C++ implementations)
    - Network topology (NED files)
    - Configuration files (omnetpp.ini)
    - CMake build system

    ## Prerequisites

    - **OMNeT++ 6.0+** - [Install OMNeT++](https://omnetpp.org/download/)
    - **CMake 3.15+**
    - **C++17 compatible compiler**

    ## Building

    ```bash
    # Create build directory
    mkdir build
    cd build

    # Configure
    cmake ..

    # Build
    cmake --build .

    # Binary will be named: #{network_name}.omnetpp.{darwin|linux|exe}
    ```

    ## Running

    ```bash
    cd build

    # Run simulation (command-line interface)
    ./#{network_name}.omnetpp.darwin -u Cmdenv -c General -n ..

    # Or use the GUI (if OMNeT++ IDE is installed)
    ./#{network_name}.omnetpp.darwin -u Qtenv -c General -n ..
    ```

    ## Project Structure

    - `*.cc`, `*.h` - Generated C++ simple modules
    - `*.ned` - Network topology definition
    - `omnetpp.ini` - Simulation configuration
    - `CMakeLists.txt` - Build configuration

    ## CI/CD

    A GitHub Actions workflow is included that:
    - Builds on Ubuntu and macOS
    - Runs the simulation demo
    - Can be extended for result validation

    ## OMNeT++ Resources

    - [Documentation](https://doc.omnetpp.org/)
    - [Tutorials](https://docs.omnetpp.org/tutorials/)
    - [Community](https://omnetpp.org/community)
    """
  end

  defp message_name(msg) when is_atom(msg) do
    Atom.to_string(msg)
  end

  defp message_name(msg) when is_binary(msg), do: msg

  defp message_name(msg) do
    inspect(msg) |> String.replace(~r/[^a-z0-9_]/, "_")
  end

  defp camelize(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> camelize()
  end

  defp camelize(string) when is_binary(string) do
    string
    |> String.split("_")
    |> Enum.map_join("", &String.capitalize/1)
  end
end
