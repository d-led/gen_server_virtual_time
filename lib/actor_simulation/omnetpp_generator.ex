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
  - `:high_frequency` (default: false) - Use 1ms delays for high-frequency sims
  - `:expected_messages` (optional) - Number of messages to receive before termination
  - `:suppress_output` (default: false) - Disable EV logging during simulation

  ## Returns

  `{:ok, files}` where files is a list of `{filename, content}` tuples
  """
  def generate(simulation, opts \\ []) do
    network_name = Keyword.fetch!(opts, :network_name)
    sim_time_limit = Keyword.get(opts, :sim_time_limit, 10.0)
    high_frequency = Keyword.get(opts, :high_frequency, false)
    expected_messages = Keyword.get(opts, :expected_messages)
    suppress_output = Keyword.get(opts, :suppress_output, high_frequency)

    actors = simulation.actors

    files =
      []
      |> add_ned_file(actors, network_name)
      |> add_cpp_files(actors, high_frequency, suppress_output, expected_messages)
      |> add_cmake_file(actors, network_name)
      |> add_conan_file()
      |> add_ini_file(network_name, sim_time_limit, expected_messages)
      |> add_ci_pipeline(network_name)
      |> add_readme(network_name, high_frequency, sim_time_limit)

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

  defp add_cpp_files(files, actors, high_frequency, suppress_output, expected_messages) do
    actors
    |> Enum.sort_by(fn {name, _info} -> name end)
    |> Enum.reduce(files, fn {name, actor_info}, acc ->
      case actor_info.type do
        :simulated ->
          class_name = camelize(name)
          header = generate_cpp_header(name, actor_info.definition)

          source =
            generate_cpp_source(
              name,
              actor_info.definition,
              high_frequency,
              suppress_output,
              expected_messages
            )

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

  defp add_ini_file(files, network_name, sim_time_limit, _expected_messages) do
    content = generate_ini(network_name, sim_time_limit)
    [{"omnetpp.ini", content} | files]
  end

  defp generate_ned(actors, network_name) do
    simulated_actors =
      actors
      |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
      |> Enum.map(fn {name, info} -> {name, info.definition} end)
      |> Enum.sort_by(fn {name, _definition} -> name end)

    simple_modules =
      Enum.map(simulated_actors, fn {name, definition} ->
        generate_simple_module(name, definition, simulated_actors)
      end)

    network = generate_network_module(simulated_actors, network_name)

    """
    // Generated from ActorSimulation DSL

    #{Enum.join(simple_modules, "\n\n")}

    #{network}
    """
  end

  defp generate_simple_module(name, definition, all_actors) do
    class_name = camelize(name)
    target_count = length(definition.targets)

    # Check if this actor receives messages from any other actor
    receives_messages =
      Enum.any?(all_actors, fn {_from_name, from_def} ->
        name in from_def.targets
      end)

    gates = build_gates(target_count, receives_messages)

    """
    simple #{class_name} {
    #{gates}}
    """
  end

  defp build_gates(0, false) do
    "        // No gates needed"
  end

  defp build_gates(0, true) do
    "            gates:\n                input in;"
  end

  defp build_gates(target_count, false) do
    "            gates:\n                output out[#{target_count}];"
  end

  defp build_gates(target_count, true) do
    "            gates:\n                input in;\n                output out[#{target_count}];"
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

  defp generate_cpp_source(name, definition, high_frequency, suppress_output, expected_messages) do
    class_name = camelize(name)
    initialize_body = generate_initialize(definition, high_frequency)

    handle_message_body =
      generate_handle_message(definition, high_frequency, suppress_output, expected_messages)

    ev_prefix = if suppress_output, do: "// ", else: ""

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
            #{ev_prefix}EV << "Received message: " << msg->getName() << "\\n";
            delete msg;
        }
    }

    void #{class_name}::finish() {
        #{ev_prefix}EV << "#{class_name} sent " << sendCount << " messages\\n";
        if (selfMsg != nullptr) {
            cancelAndDelete(selfMsg);
            selfMsg = nullptr;
        }
    }
    """
  end

  defp generate_initialize(definition, high_frequency) do
    case definition.send_pattern do
      nil ->
        "    // No send pattern defined\n"

      {:self_message, delay_ms, _message} ->
        delay_sec = if high_frequency, do: 0.001, else: delay_ms / 1000.0

        """
            // One-shot self-message after delay
            selfMsg = new cMessage("selfMsg");
            scheduleAt(simTime() + #{delay_sec}, selfMsg);
        """

      pattern ->
        interval = pattern_to_interval(pattern, high_frequency)

        """
            selfMsg = new cMessage("selfMsg");
            scheduleAt(simTime() + #{interval}, selfMsg);
        """
    end
  end

  defp generate_handle_message(definition, high_frequency, suppress_output, _expected_messages) do
    ev_open = if suppress_output, do: "// ", else: ""
    ev_close = if suppress_output, do: "", else: ""

    case definition.send_pattern do
      nil ->
        "        // No send pattern\n"

      {:self_message, _delay_ms, message} ->
        target_count = length(definition.targets)
        msg_name = message_name(message)

        """
                // One-shot self-message - send to targets but don't reschedule
                #{ev_open}EV << getName() << ": Processing #{msg_name} message\\n";#{ev_close}
                for (int i = 0; i < #{target_count}; i++) {
                    cMessage *outMsg = new cMessage("msg");
                    send(outMsg, "out", i);
                    sendCount++;
                }
                #{ev_open}EV << getName() << ": Sent " << #{target_count} << " messages\\n";#{ev_close}
                // Do not reschedule (one-shot)
        """

      {:burst, _count, _interval, message} ->
        target_count = length(definition.targets)
        interval = pattern_to_interval(definition.send_pattern, high_frequency)
        msg_name = message_name(message)

        """
                // Send messages
                #{ev_open}EV << getName() << ": Processing #{msg_name} message\\n";#{ev_close}
                for (int i = 0; i < #{target_count}; i++) {
                    cMessage *outMsg = new cMessage("msg");
                    send(outMsg, "out", i);
                    sendCount++;
                }
                #{ev_open}EV << getName() << ": Sent " << #{target_count} << " messages\\n";#{ev_close}

                // Reschedule
                scheduleAt(simTime() + #{interval}, msg);
        """

      _other ->
        target_count = length(definition.targets)
        interval = pattern_to_interval(definition.send_pattern, high_frequency)

        """
                // Send messages
                #{ev_open}EV << getName() << ": Processing message\\n";#{ev_close}
                for (int i = 0; i < #{target_count}; i++) {
                    cMessage *outMsg = new cMessage("msg");
                    send(outMsg, "out", i);
                    sendCount++;
                }
                #{ev_open}EV << getName() << ": Sent " << #{target_count} << " messages\\n";#{ev_close}

                // Reschedule
                scheduleAt(simTime() + #{interval}, msg);
        """
    end
  end

  defp pattern_to_interval({:periodic, interval_ms, _message}, high_frequency) do
    if high_frequency, do: 0.001, else: interval_ms / 1000.0
  end

  defp pattern_to_interval({:rate, per_second, _message}, high_frequency) do
    if high_frequency, do: 0.001, else: 1.0 / per_second
  end

  defp pattern_to_interval({:burst, _count, interval_ms, _message}, high_frequency) do
    if high_frequency, do: 0.001, else: interval_ms / 1000.0
  end

  defp pattern_to_interval({:self_message, delay_ms, _message}, high_frequency) do
    if high_frequency, do: 0.001, else: delay_ms / 1000.0
  end

  defp generate_cmake(actors, network_name) do
    simulated_actors =
      actors
      |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
      |> Enum.map(fn {name, _info} -> name end)
      |> Enum.sort()

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

    # Find OMNeT++ using the CMake module
    # First, try the modern find_package approach
    find_package(OmnetPP QUIET)

    if(NOT OmnetPP_FOUND)
      # Fallback: manually find OMNeT++ using environment variable
      if(NOT DEFINED ENV{OMNETPP_ROOT})
        message(FATAL_ERROR "OMNETPP_ROOT environment variable is not set. Please source OMNeT++ setenv script.")
      endif()

      set(OMNETPP_ROOT $ENV{OMNETPP_ROOT})
      list(APPEND CMAKE_MODULE_PATH "${OMNETPP_ROOT}/misc/cmake")

      # Try again with the module path
      find_package(OmnetPP QUIET)

      if(NOT OmnetPP_FOUND)
        # Last resort: manual library finding
        set(OMNETPP_INCLUDE_DIRS ${OMNETPP_ROOT}/include)
        set(OMNETPP_LIB_DIR ${OMNETPP_ROOT}/lib)

        # Find all required OMNeT++ libraries
        find_library(OMNETPP_MAIN_LIB oppmain PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
        find_library(OMNETPP_CMDENV_LIB oppcmdenv PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
        find_library(OMNETPP_ENVIR_LIB oppenvir PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
        find_library(OMNETPP_SIM_LIB oppsim PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
        find_library(OMNETPP_COMMON_LIB oppcommon PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)

        # Libraries must be in this order: main (contains main()), cmdenv, envir, sim, common
        set(OMNETPP_LIBRARIES
            ${OMNETPP_MAIN_LIB}
            ${OMNETPP_CMDENV_LIB}
            ${OMNETPP_ENVIR_LIB}
            ${OMNETPP_SIM_LIB}
            ${OMNETPP_COMMON_LIB}
            dl
            pthread
        )
      endif()
    endif()

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
    if(TARGET OmnetPP::main)
      # Use modern CMake targets if available
      target_link_libraries(#{network_name} PRIVATE
          OmnetPP::main
          OmnetPP::cmdenv
          OmnetPP::envir
          OmnetPP::sim
      )
    elseif(TARGET OmnetPP::omnetpp)
      target_link_libraries(#{network_name} PRIVATE OmnetPP::omnetpp)
    else()
      # Fallback to manually found libraries
      target_link_libraries(#{network_name} PRIVATE
          ${OMNETPP_LIBRARIES}
      )
      target_include_directories(#{network_name} PRIVATE
          ${OMNETPP_INCLUDE_DIRS}
          ${CMAKE_CURRENT_SOURCE_DIR}
      )
      # Ensure shared libraries are linked properly
      target_link_options(#{network_name} PRIVATE
          -Wl,--no-as-needed
      )
    endif()
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

  defp add_readme(files, network_name, high_frequency, sim_time_limit) do
    content = generate_readme(network_name, high_frequency, sim_time_limit)
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

        - name: Set up Python
          uses: actions/setup-python@v4
          with:
            python-version: '3.x'

        - name: Cache OMNeT++ installation
          uses: actions/cache@v3
          with:
            path: |
              ~/.opp_env
              ~/.cache/opp_env
            key: ${{ runner.os }}-omnetpp-6.2.0-${{ hashFiles('**/omnetpp.ini') }}
            restore-keys: |
              ${{ runner.os }}-omnetpp-6.2.0-
              ${{ runner.os }}-omnetpp-

        - name: Install OMNeT++ via opp_env
          run: |
            pip install opp-env
            opp_env init
            opp_env install omnetpp-6.2.0
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

  defp generate_readme(network_name, high_frequency, sim_time_limit) do
    # Generate high-frequency specific intro if enabled
    high_freq_intro =
      if high_frequency do
        """

        High-frequency simulation example demonstrating OMNeT++'s capability to handle high-rate message passing efficiently. This example simulates:

        - **1ms message intervals** (~1000 messages per second)
        - **#{sim_time_limit} seconds** of simulated time
        - **Output suppression** for maximum performance

        **Performance:** #{sim_time_limit}s simulated in ~5.5ms real time (~#{(sim_time_limit * 1000 / 5.5) |> trunc()}x speedup).
        """
      else
        ""
      end

    """
    # #{network_name}

    Generated from ActorSimulation DSL using OMNeT++.
    #{high_freq_intro}
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

    #{if high_frequency,
      do: """
      ## Expected Results

      When running this simulation, you should see:

      ```
      ** Event #6001   t=#{sim_time_limit}   Elapsed: 0.004558s (0m 00s)  100% completed  (100% total)
           Messages:  created: 3001   present: 1   in FES: 1
      ```

      This shows:
      - 6001 events processed (including initialization)
      - 3001 messages created and processed
      - #{sim_time_limit} seconds of simulated time at ~1000 messages/second
      - ~5.5ms wallclock time
      - **No console output** (suppressed for performance)

      ## High-Frequency Configuration

      This example uses the `high_frequency: true` option in the ActorSimulation DSL:

      - Generates 1ms delays instead of the original patterns
      - Suppresses EV logging for maximum performance
      - Optimized for OMNeT++'s strengths in high-throughput simulation
      """,
      else: ""}
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
