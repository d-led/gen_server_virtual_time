# PubSubNetwork - OMNeT++ Simulation

Generated from ActorSimulation DSL using `ActorSimulation.OMNeTPPGenerator`.

## Overview

This is a complete OMNeT++ discrete-event simulation project that models a publish-subscribe messaging system:

- **Publisher** - Sends periodic events every 100ms to all subscribers
- **Subscriber1, Subscriber2, Subscriber3** - Receive events from publisher

## Project Structure

```
.
├── PubSubNetwork.ned      # Network topology (NED language)
├── Publisher.h/.cc        # Publisher simple module
├── Subscriber1.h/.cc      # Subscriber implementations
├── Subscriber2.h/.cc
├── Subscriber3.h/.cc
├── CMakeLists.txt         # CMake build configuration
├── conanfile.txt          # Package dependencies (Conan)
├── omnetpp.ini            # Simulation parameters
└── README.md              # This file
```

## Prerequisites

To build and run this simulation, you need:

1. **OMNeT++ 6.0+**
   - Download from [omnetpp.org](https://omnetpp.org/)
   - Follow the [Installation Guide](https://doc.omnetpp.org/omnetpp/InstallGuide.pdf)
   - Set up environment: `source ~/.bashrc` or `source setenv` in OMNeT++ directory

2. **CMake 3.15+**
   ```bash
   # macOS
   brew install cmake
   
   # Ubuntu/Debian
   sudo apt-get install cmake
   ```

3. **C++17 Compiler**
   - GCC 7+ or Clang 5+ (Linux/macOS)
   - MSVC 2017+ (Windows)

4. **Conan (optional)**
   ```bash
   pip install conan
   ```

## Building

### Option 1: Using CMake (Recommended)

```bash
# Create build directory
mkdir build && cd build

# Configure with CMake
cmake ..

# Build
make

# Or for parallel build
make -j4
```

### Option 2: Using OMNeT++ opp_makemake

```bash
# Generate Makefile
opp_makemake -f --deep

# Build
make
```

## Running

### Command-Line Interface (Cmdenv)

```bash
# From build directory
./PubSubNetwork -u Cmdenv

# Or from project root
cd build
./PubSubNetwork -u Cmdenv -c General
```

### Graphical Interface (Qtenv)

```bash
# Launch GUI
./PubSubNetwork

# Or explicitly specify
./PubSubNetwork -u Qtenv
```

### Expected Output

```
** Event #1  t=0  PubSubNetwork.publisher (Publisher, id=2)
Publisher sent 3 messages

** Event #2  t=0.1  PubSubNetwork.publisher (Publisher, id=2)
Publisher sent 6 messages

** Event #3  t=0.2  PubSubNetwork.publisher (Publisher, id=2)
Publisher sent 9 messages

...

** Event #100  t=10  PubSubNetwork.publisher (Publisher, id=2)
Publisher sent 300 messages

Simulation completed at t=10s
```

## Configuration

Edit `omnetpp.ini` to customize simulation parameters:

```ini
[General]
network = PubSubNetwork
sim-time-limit = 10s          # Change simulation duration

# Logging
**.cmdenv-express-mode = true
**.cmdenv-status-frequency = 1s

# Random number generation
seed-0-mt = 42                # Change for different random sequences
```

## Network Topology

The NED file (`PubSubNetwork.ned`) defines the network structure:

```ned
network PubSubNetwork {
    submodules:
        publisher: Publisher;
        subscriber1: Subscriber1;
        subscriber2: Subscriber2;
        subscriber3: Subscriber3;
    connections:
        publisher.out[0] --> subscriber1.in;
        publisher.out[1] --> subscriber2.in;
        publisher.out[2] --> subscriber3.in;
}
```

## Module Behavior

### Publisher

- Sends messages periodically (100ms interval)
- Broadcasts to all output gates
- Tracks total messages sent

### Subscribers

- Receive messages from publisher
- Log received messages
- No response or acknowledgment

## Customization

### Changing Message Rate

Edit `Publisher.cc`:

```cpp
// Change interval from 0.1s to 0.05s (50ms)
scheduleAt(simTime() + 0.05, selfMsg);
```

### Adding Statistics

Add to module classes:

```cpp
// In initialize()
@statistic[sentCount](title="Messages Sent"; record=vector,stats);

// In handleMessage()
emit(sentCountSignal, sendCount);
```

### Modifying Network

Edit `PubSubNetwork.ned` to add/remove subscribers:

```ned
network PubSubNetwork {
    submodules:
        publisher: Publisher;
        subscriber1: Subscriber1;
        subscriber2: Subscriber2;
        subscriber3: Subscriber3;
        subscriber4: Subscriber4;  // New subscriber
    connections:
        publisher.out[0] --> subscriber1.in;
        publisher.out[1] --> subscriber2.in;
        publisher.out[2] --> subscriber3.in;
        publisher.out[3] --> subscriber4.in;  // New connection
}
```

**Note:** You'll need to update `Publisher.h` to increase output gate count.

## Troubleshooting

### "OMNeT++ not found"

Make sure OMNeT++ environment is set:
```bash
source /path/to/omnetpp/setenv
echo $OMNETPP_ROOT  # Should print OMNeT++ path
```

### CMake can't find OMNeT++

Set OMNeT++ path explicitly:
```bash
cmake -DOMNETPP_ROOT=/path/to/omnetpp ..
```

### Compilation errors

Ensure you have C++17 support:
```bash
g++ --version  # Should be 7.0+
clang++ --version  # Should be 5.0+
```

## Learning Resources

- [OMNeT++ Tutorial](https://docs.omnetpp.org/tutorials/tictoc/)
- [NED Language Guide](https://doc.omnetpp.org/omnetpp/manual/#cha:ned-lang)
- [Simple Module API](https://doc.omnetpp.org/omnetpp/api/classomnetpp_1_1cSimpleModule.html)
- [Simulation Manual](https://doc.omnetpp.org/omnetpp/manual/)

## Regenerating

To regenerate this project from the Elixir DSL:

```elixir
# In your Elixir project
simulation = 
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:publisher,
      send_pattern: {:periodic, 100, :event},
      targets: [:subscriber1, :subscriber2, :subscriber3])
  |> ActorSimulation.add_actor(:subscriber1)
  |> ActorSimulation.add_actor(:subscriber2)
  |> ActorSimulation.add_actor(:subscriber3)

{:ok, files} = ActorSimulation.OMNeTPPGenerator.generate(simulation,
  network_name: "PubSubNetwork",
  sim_time_limit: 10)

ActorSimulation.OMNeTPPGenerator.write_to_directory(files, "omnetpp_pubsub/")
```

Or run the demo:
```bash
mix run examples/omnetpp_demo.exs
```

## License

Generated code is provided as-is for use with OMNeT++ under the Academic Public License.

## Support

For issues with:
- **Generated code** - Open issue in GenServerVirtualTime repo
- **OMNeT++** - See [OMNeT++ community](https://groups.google.com/g/omnetpp)
- **Build system** - Check CMake and compiler documentation

