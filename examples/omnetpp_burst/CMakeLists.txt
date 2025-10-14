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

# Find OMNeT++ - use environment variable if CMAKE_PREFIX_PATH is not set
if(NOT DEFINED ENV{OMNETPP_ROOT})
  message(FATAL_ERROR "OMNETPP_ROOT environment variable is not set. Please source OMNeT++ setenv script.")
endif()

set(OMNETPP_ROOT $ENV{OMNETPP_ROOT})
set(OMNETPP_INCLUDE_DIRS ${OMNETPP_ROOT}/include)
set(OMNETPP_LIB_DIR ${OMNETPP_ROOT}/lib)

# Find OMNeT++ libraries
find_library(OMNETPP_COMMON_LIB oppcommon PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
find_library(OMNETPP_CMDENV_LIB oppcmdenv PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
find_library(OMNETPP_SIM_LIB oppsim PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)

set(OMNETPP_LIBRARIES ${OMNETPP_SIM_LIB} ${OMNETPP_CMDENV_LIB} ${OMNETPP_COMMON_LIB})

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
