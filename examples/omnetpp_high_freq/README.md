# HighFreqNetwork

Generated from ActorSimulation DSL using OMNeT++.

High-frequency simulation example demonstrating OMNeT++'s capability to handle high-rate message passing efficiently. This example simulates:

- **1ms message intervals** (~1000 messages per second)
- **3 seconds** of simulated time
- **Output suppression** for maximum performance

**Performance:** 3s simulated in ~5.5ms real time (~545x speedup).

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

# Binary will be named: HighFreqNetwork.omnetpp.{darwin|linux|exe}
```

## Running

```bash
cd build

# Run simulation (command-line interface)
./HighFreqNetwork.omnetpp.darwin -u Cmdenv -c General -n ..

# Or use the GUI (if OMNeT++ IDE is installed)
./HighFreqNetwork.omnetpp.darwin -u Qtenv -c General -n ..
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

## Expected Results

When running this simulation, you should see:

```
** Event #6001   t=3   Elapsed: 0.004558s (0m 00s)  100% completed  (100% total)
     Messages:  created: 3001   present: 1   in FES: 1
```

This shows:
- 6001 events processed (including initialization)
- 3001 messages created and processed
- 3 seconds of simulated time at ~1000 messages/second
- ~5.5ms wallclock time
- **No console output** (suppressed for performance)

## High-Frequency Configuration

This example uses the `high_frequency: true` option in the ActorSimulation DSL:

- Generates 1ms delays instead of the original patterns
- Suppresses EV logging for maximum performance
- Optimized for OMNeT++'s strengths in high-throughput simulation

## OMNeT++ Resources

- [Documentation](https://doc.omnetpp.org/)
- [Tutorials](https://docs.omnetpp.org/tutorials/)
- [Community](https://omnetpp.org/community)
