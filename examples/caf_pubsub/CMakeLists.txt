cmake_minimum_required(VERSION 3.15)
project(PubSubActors CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

# Test executable
add_executable(PubSubActors_test test_actors.cpp)
target_link_libraries(PubSubActors_test 
  PRIVATE
    CAF::core
    CAF::io
    Catch2::Catch2WithMain
)

# Enable testing
enable_testing()
add_test(NAME PubSubActors_test COMMAND PubSubActors_test)
