# CAF (C++ Actor Framework) Generator

Generate production-ready CAF actor code with callback interfaces for clean
customization.

## Quick Start

```elixir
simulation = ActorSimulation.new()
  |> ActorSimulation.add_actor(:worker,
      send_pattern: {:rate, 50, :task},
      targets: [:processor])
  |> ActorSimulation.add_actor(:processor)

{:ok, files} = ActorSimulation.CAFGenerator.generate(simulation,
  project_name: "MyActors",
  enable_callbacks: true)

ActorSimulation.CAFGenerator.write_to_directory(files, "caf_out/")
```

## Key Feature: Callback Interfaces

The CAF generator creates **callback interfaces** so you can customize behavior
WITHOUT touching generated code:

```cpp
// worker_callbacks_impl.cpp (EDIT THIS!)
void worker_callbacks::on_task() {
  // Add your business logic here!
  std::cout << "Custom processing!" << std::endl;
  process_data();
  log_metrics();
}
```

## Generated Files

- **Actor files** (`*_actor.hpp/cpp`) - CAF actor implementations (DO NOT EDIT)
- **Callback interfaces** (`*_callbacks.hpp`) - Trait definitions (DO NOT EDIT)
- **Callback implementations** (`*_callbacks_impl.cpp`) - **YOUR CODE HERE!**
- **Tests** (`test_actors.cpp`) - Catch2 unit tests
- **Build files** (`CMakeLists.txt`, `conanfile.txt`) - CMake + Conan
- **CI pipeline** (`.github/workflows/ci.yml`) - GitHub Actions

## Features

✅ Event-based actors with CAF  
✅ Callback interfaces for customization  
✅ Catch2 automated tests  
✅ JUnit XML test reports  
✅ CI/CD pipeline included  
✅ Multi-platform (Linux, macOS)

## Examples

See [`examples/caf_pubsub/`](../examples/caf_pubsub/) for a complete generated
project.

Try the single-file script:
[`examples/single_file_caf.exs`](../examples/single_file_caf.exs)

## Building Generated Code

```bash
cd caf_output/
mkdir build && cd build

# Install dependencies
conan install .. --build=missing

# Build
cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake
cmake --build .

# Run
./MyActors

# Test
ctest --output-on-failure
./MyActors_test
```

## Learn More

- [CAF Homepage](https://actor-framework.org/)
- [CAF Documentation](https://actor-framework.readthedocs.io/)
- [Catch2 Testing](https://github.com/catchorg/Catch2)
- [Generator Comparison](generators.md#comparison)
