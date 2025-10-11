cmake_minimum_required(VERSION 3.15)
project(LoadBalancedSystem)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

# Link OMNeT++ libraries
target_link_libraries(LoadBalancedSystem 
    ${OMNETPP_LIBRARIES}
)

target_include_directories(LoadBalancedSystem PRIVATE
    ${OMNETPP_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}
)
