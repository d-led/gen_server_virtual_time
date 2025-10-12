# OMNeT++ Code Generator

Generate production-ready OMNeT++ C++ simulation code from ActorSimulation DSL.

## Quick Start

```elixir
simulation = ActorSimulation.new()
  |> ActorSimulation.add_actor(:sender,
      send_pattern: {:periodic, 100, :msg},
      targets: [:receiver])
  |> ActorSimulation.add_actor(:receiver)

{:ok, files} = ActorSimulation.OMNeTPPGenerator.generate(simulation,
  network_name: "SimpleNetwork",
  sim_time_limit: 10)

ActorSimulation.OMNeTPPGenerator.write_to_directory(files, "omnetpp_out/")
```

## Generated Files

- **NED files** (`.ned`) - Network topology in OMNeT++ NED language
- **C++ headers** (`.h`) - Simple module class declarations
- **C++ sources** (`.cc`) - Simple module implementations
- **CMakeLists.txt** - CMake build configuration
- **conanfile.txt** - Package dependencies
- **omnetpp.ini** - Simulation parameters

## Features

✅ All send patterns (periodic, rate, burst)  
✅ Point-to-point connections  
✅ Multiple targets  
✅ CMake + Conan build system  
✅ Complete documentation

## Examples

See [`examples/omnetpp_pubsub/`](../examples/omnetpp_pubsub/) for a complete generated project.

Try the single-file script: [`examples/single_file_omnetpp.exs`](../examples/single_file_omnetpp.exs)

## Building Generated Code

```bash
cd omnetpp_output/
mkdir build && cd build
cmake ..
make
./NetworkName -u Cmdenv
```

## Learn More

- [OMNeT++ Homepage](https://omnetpp.org/)
- [OMNeT++ Documentation](https://doc.omnetpp.org/)
- [Generator Comparison](generators.md#comparison)

