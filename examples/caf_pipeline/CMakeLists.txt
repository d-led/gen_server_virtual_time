cmake_minimum_required(VERSION 3.15)
project(PipelineActors CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Detect OS for binary naming: {example}.caf.{os}
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(OS_SUFFIX "darwin")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(OS_SUFFIX "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(OS_SUFFIX "exe")
else()
  set(OS_SUFFIX "bin")
endif()

# Find CAF
find_package(CAF REQUIRED COMPONENTS core io)

# Find Catch2 for testing
find_package(Catch2 3 REQUIRED)

# Source files
set(SOURCES
  main.cpp
  source_actor.cpp
  source_callbacks_impl.cpp
  stage1_actor.cpp
  stage1_callbacks_impl.cpp
  stage2_actor.cpp
  stage2_callbacks_impl.cpp
  stage3_actor.cpp
  stage3_callbacks_impl.cpp
  sink_actor.cpp
  sink_callbacks_impl.cpp
)

# Create executable
add_executable(PipelineActors ${SOURCES})

# Set output binary name: {example}.caf.{os}
set_target_properties(PipelineActors PROPERTIES
  OUTPUT_NAME "PipelineActors.caf.${OS_SUFFIX}"
)

# Link CAF libraries
target_link_libraries(PipelineActors
  PRIVATE
    CAF::core
    CAF::io
)

# Enable warnings
if(MSVC)
  target_compile_options(PipelineActors PRIVATE /W4)
else()
  target_compile_options(PipelineActors PRIVATE -Wall -Wextra -pedantic)
endif()

# Test executable (needs actor sources)
set(TEST_SOURCES
  test_actors.cpp
  source_actor.cpp
  source_callbacks_impl.cpp
  stage1_actor.cpp
  stage1_callbacks_impl.cpp
  stage2_actor.cpp
  stage2_callbacks_impl.cpp
  stage3_actor.cpp
  stage3_callbacks_impl.cpp
  sink_actor.cpp
  sink_callbacks_impl.cpp
)

add_executable(PipelineActors_test ${TEST_SOURCES})
target_link_libraries(PipelineActors_test
  PRIVATE
    CAF::core
    CAF::io
    Catch2::Catch2WithMain
)

# Enable testing
enable_testing()
add_test(NAME PipelineActors_test COMMAND PipelineActors_test)

# Generate JUnit XML report for CI
add_test(
  NAME PipelineActors_test_junit
  COMMAND PipelineActors_test --reporter junit --out test-results.xml
)
