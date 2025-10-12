cmake_minimum_required(VERSION 3.15)
project(BurstActors CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find CAF
find_package(CAF REQUIRED COMPONENTS core io)

# Find Catch2 for testing
find_package(Catch2 3 REQUIRED)

# Source files
set(SOURCES
  main.cpp
  processor_actor.cpp
  processor_callbacks_impl.cpp
  burst_generator_actor.cpp
  burst_generator_callbacks_impl.cpp
)

# Create executable
add_executable(BurstActors ${SOURCES})

# Link CAF libraries
target_link_libraries(BurstActors
  PRIVATE
    CAF::core
    CAF::io
)

# Enable warnings
if(MSVC)
  target_compile_options(BurstActors PRIVATE /W4)
else()
  target_compile_options(BurstActors PRIVATE -Wall -Wextra -pedantic)
endif()

# Test executable
add_executable(BurstActors_test test_actors.cpp)
target_link_libraries(BurstActors_test
  PRIVATE
    CAF::core
    CAF::io
    Catch2::Catch2WithMain
)

# Enable testing
enable_testing()
add_test(NAME BurstActors_test COMMAND BurstActors_test)

# Generate JUnit XML report for CI
add_test(
  NAME BurstActors_test_junit
  COMMAND BurstActors_test --reporter junit --out test-results.xml
)
