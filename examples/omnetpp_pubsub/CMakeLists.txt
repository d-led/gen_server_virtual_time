cmake_minimum_required(VERSION 3.15)
project(PubSubNetwork)

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
    Publisher.cc
    Subscriber1.cc
    Subscriber2.cc
    Subscriber3.cc
)

# Create executable
add_executable(PubSubNetwork ${SOURCES})

# Set output binary name: {example}.omnetpp.{os}
set_target_properties(PubSubNetwork PROPERTIES
  OUTPUT_NAME "PubSubNetwork.omnetpp.${OS_SUFFIX}"
)

# Link OMNeT++ libraries
target_link_libraries(PubSubNetwork
    ${OMNETPP_LIBRARIES}
)

target_include_directories(PubSubNetwork PRIVATE
    ${OMNETPP_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)
