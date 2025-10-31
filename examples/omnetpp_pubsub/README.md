# PubSubNetwork

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

# Binary will be named: PubSubNetwork.omnetpp.{darwin|linux|exe}
```

## Running

```bash
cd build

# Run simulation (command-line interface)
./PubSubNetwork.omnetpp.darwin -u Cmdenv -c General -n ..

# Or use the GUI (if OMNeT++ IDE is installed)
./PubSubNetwork.omnetpp.darwin -u Qtenv -c General -n ..
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
