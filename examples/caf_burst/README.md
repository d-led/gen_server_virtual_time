# BurstActors

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
./BurstActors
```

## Testing

```bash
# Run tests with CTest
cd build
ctest --output-on-failure

# Run Catch2 tests with verbose output
./BurstActors_test --success

# Generate JUnit XML report
./BurstActors_test --reporter junit --out test-results.xml
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
