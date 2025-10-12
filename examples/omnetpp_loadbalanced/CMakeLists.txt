cmake_minimum_required(VERSION 3.15)
project(LoadBalancedSystem)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Detect OS for binary naming: {example}.omnetpp.{os}
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
  set(OS_SUFFIX "darwin")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(OS_SUFFIX "linux")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(OS_SUFFIX "exe")
else()
  set(OS_SUFFIX "bin")
endif()

# Find OMNeT++
find_package(OMNeT++ REQUIRED)

# Source files
set(SOURCES
    LoadBalancer.cc
    Server1.cc
    Server2.cc
    Server3.cc
    Database.cc
)

# Create executable
add_executable(LoadBalancedSystem ${SOURCES})

# Set output binary name: {example}.omnetpp.{os}
set_target_properties(LoadBalancedSystem PROPERTIES
  OUTPUT_NAME "LoadBalancedSystem.omnetpp.${OS_SUFFIX}"
)

# Link OMNeT++ libraries
target_link_libraries(LoadBalancedSystem
    ${OMNETPP_LIBRARIES}
)

target_include_directories(LoadBalancedSystem PRIVATE
    ${OMNETPP_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)
