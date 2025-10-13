cmake_minimum_required(VERSION 3.15)
project(BurstNetwork)

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
    BurstGenerator.cc
    Processor.cc
)

# Create executable
add_executable(BurstNetwork ${SOURCES})

# Set output binary name: {example}.omnetpp.{os}
set_target_properties(BurstNetwork PROPERTIES
  OUTPUT_NAME "BurstNetwork.omnetpp.${OS_SUFFIX}"
)

# Link OMNeT++ libraries
target_link_libraries(BurstNetwork
    ${OMNETPP_LIBRARIES}
)

target_include_directories(BurstNetwork PRIVATE
    ${OMNETPP_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)
