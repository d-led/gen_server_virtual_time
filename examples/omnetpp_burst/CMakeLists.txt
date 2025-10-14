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

# Find OMNeT++ using the CMake module
# First, try the modern find_package approach
find_package(OmnetPP QUIET)

if(NOT OmnetPP_FOUND)
  # Fallback: manually find OMNeT++ using environment variable
  if(NOT DEFINED ENV{OMNETPP_ROOT})
    message(FATAL_ERROR "OMNETPP_ROOT environment variable is not set. Please source OMNeT++ setenv script.")
  endif()

  set(OMNETPP_ROOT $ENV{OMNETPP_ROOT})
  list(APPEND CMAKE_MODULE_PATH "${OMNETPP_ROOT}/misc/cmake")
  
  # Try again with the module path
  find_package(OmnetPP QUIET)
  
  if(NOT OmnetPP_FOUND)
    # Last resort: manual library finding
    set(OMNETPP_INCLUDE_DIRS ${OMNETPP_ROOT}/include)
    set(OMNETPP_LIB_DIR ${OMNETPP_ROOT}/lib)

    find_library(OMNETPP_CMDENV_LIB oppcmdenv PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
    find_library(OMNETPP_SIM_LIB oppsim PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
    find_library(OMNETPP_COMMON_LIB oppcommon PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)

    # Libraries must be in this order: cmdenv provides main(), then sim, then common
    set(OMNETPP_LIBRARIES
        ${OMNETPP_CMDENV_LIB}
        ${OMNETPP_SIM_LIB}
        ${OMNETPP_COMMON_LIB}
        dl
        pthread
    )
  endif()
endif()

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
if(TARGET OmnetPP::main)
  # Use modern CMake targets if available
  target_link_libraries(BurstNetwork PRIVATE
      OmnetPP::main
      OmnetPP::envir
      OmnetPP::sim
  )
elseif(TARGET OmnetPP::omnetpp)
  target_link_libraries(BurstNetwork PRIVATE OmnetPP::omnetpp)
else()
  # Fallback to manually found libraries
  target_link_libraries(BurstNetwork PRIVATE
      ${OMNETPP_LIBRARIES}
  )
  target_include_directories(BurstNetwork PRIVATE
      ${OMNETPP_INCLUDE_DIRS}
      ${CMAKE_CURRENT_SOURCE_DIR}
  )
endif()
