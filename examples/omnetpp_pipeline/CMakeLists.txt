cmake_minimum_required(VERSION 3.15)
project(PipelineNetwork)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

# Link OMNeT++ libraries
target_link_libraries(PipelineNetwork 
    ${OMNETPP_LIBRARIES}
)

target_include_directories(PipelineNetwork PRIVATE
    ${OMNETPP_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)
