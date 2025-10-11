cmake_minimum_required(VERSION 3.15)
project(PubSubNetwork)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

# Link OMNeT++ libraries
target_link_libraries(PubSubNetwork 
    ${OMNETPP_LIBRARIES}
)

target_include_directories(PubSubNetwork PRIVATE
    ${OMNETPP_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)
