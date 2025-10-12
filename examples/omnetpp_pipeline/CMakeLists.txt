cmake_minimum_required(VERSION 3.15)
project(PipelineNetwork)

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
    Source.cc
    Stage1.cc
    Stage2.cc
    Stage3.cc
    Sink.cc
)

# Create executable
add_executable(PipelineNetwork ${SOURCES})

# Set output binary name: {example}.omnetpp.{os}
set_target_properties(PipelineNetwork PROPERTIES
  OUTPUT_NAME "PipelineNetwork.omnetpp.${OS_SUFFIX}"
)

# Link OMNeT++ libraries
target_link_libraries(PipelineNetwork
    ${OMNETPP_LIBRARIES}
)

target_include_directories(PipelineNetwork PRIVATE
    ${OMNETPP_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)
