cmake_minimum_required(VERSION 3.15)
project(BurstNetwork)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find OMNeT++
find_package(OMNeT++ REQUIRED)

# Source files
set(SOURCES
    Processor.cc
    BurstGenerator.cc
)

# Create executable
add_executable(BurstNetwork ${SOURCES})

# Link OMNeT++ libraries
target_link_libraries(BurstNetwork
    ${OMNETPP_LIBRARIES}
)

target_include_directories(BurstNetwork PRIVATE
    ${OMNETPP_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)
