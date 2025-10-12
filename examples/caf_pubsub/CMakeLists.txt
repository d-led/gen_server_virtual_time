cmake_minimum_required(VERSION 3.15)
project(PubSubActors CXX)

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
  publisher_actor.cpp
  publisher_callbacks_impl.cpp
  subscriber1_actor.cpp
  subscriber1_callbacks_impl.cpp
  subscriber2_actor.cpp
  subscriber2_callbacks_impl.cpp
  subscriber3_actor.cpp
  subscriber3_callbacks_impl.cpp
)

# Create executable
add_executable(PubSubActors ${SOURCES})

# Set output binary name: {example}.caf.{os}
set_target_properties(PubSubActors PROPERTIES
  OUTPUT_NAME "PubSubActors.caf.${OS_SUFFIX}"
)

# Link CAF libraries
target_link_libraries(PubSubActors
  PRIVATE
    CAF::core
    CAF::io
)

# Enable warnings
if(MSVC)
  target_compile_options(PubSubActors PRIVATE /W4)
else()
  target_compile_options(PubSubActors PRIVATE -Wall -Wextra -pedantic)
endif()

# Test executable (needs actor sources)
set(TEST_SOURCES
  test_actors.cpp
  publisher_actor.cpp
  publisher_callbacks_impl.cpp
  subscriber1_actor.cpp
  subscriber1_callbacks_impl.cpp
  subscriber2_actor.cpp
  subscriber2_callbacks_impl.cpp
  subscriber3_actor.cpp
  subscriber3_callbacks_impl.cpp
)

add_executable(PubSubActors_test ${TEST_SOURCES})
target_link_libraries(PubSubActors_test
  PRIVATE
    CAF::core
    CAF::io
    Catch2::Catch2WithMain
)

# Enable testing
enable_testing()
add_test(NAME PubSubActors_test COMMAND PubSubActors_test)

# Generate JUnit XML report for CI
add_test(
  NAME PubSubActors_test_junit
  COMMAND PubSubActors_test --reporter junit --out test-results.xml
)
