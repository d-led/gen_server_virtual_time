cmake_minimum_required(VERSION 3.15)
project(LoadBalancedActors CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find CAF
find_package(CAF REQUIRED COMPONENTS core io)

# Find Catch2 for testing
find_package(Catch2 3 REQUIRED)

# Source files
set(SOURCES
  main.cpp
  load_balancer_actor.cpp
  load_balancer_callbacks_impl.cpp
  server1_actor.cpp
  server1_callbacks_impl.cpp
  server2_actor.cpp
  server2_callbacks_impl.cpp
  server3_actor.cpp
  server3_callbacks_impl.cpp
  database_actor.cpp
  database_callbacks_impl.cpp
)

# Create executable
add_executable(LoadBalancedActors ${SOURCES})

# Link CAF libraries
target_link_libraries(LoadBalancedActors 
  PRIVATE
    CAF::core
    CAF::io
)

# Enable warnings
if(MSVC)
  target_compile_options(LoadBalancedActors PRIVATE /W4)
else()
  target_compile_options(LoadBalancedActors PRIVATE -Wall -Wextra -pedantic)
endif()

# Test executable
add_executable(LoadBalancedActors_test test_actors.cpp)
target_link_libraries(LoadBalancedActors_test 
  PRIVATE
    CAF::core
    CAF::io
    Catch2::Catch2WithMain
)

# Enable testing
enable_testing()
add_test(NAME LoadBalancedActors_test COMMAND LoadBalancedActors_test)

# Generate JUnit XML report for CI
add_test(
  NAME LoadBalancedActors_test_junit
  COMMAND LoadBalancedActors_test --reporter junit --out test-results.xml
)
