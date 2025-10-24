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

    # Find all required OMNeT++ libraries
    find_library(OMNETPP_MAIN_LIB oppmain PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
    find_library(OMNETPP_CMDENV_LIB oppcmdenv PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
    find_library(OMNETPP_ENVIR_LIB oppenvir PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
    find_library(OMNETPP_SIM_LIB oppsim PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)
    find_library(OMNETPP_COMMON_LIB oppcommon PATHS ${OMNETPP_LIB_DIR} REQUIRED NO_DEFAULT_PATH)

    # Libraries must be in this order: main (contains main()), cmdenv, envir, sim, common
    set(OMNETPP_LIBRARIES
        ${OMNETPP_MAIN_LIB}
        ${OMNETPP_CMDENV_LIB}
        ${OMNETPP_ENVIR_LIB}
        ${OMNETPP_SIM_LIB}
        ${OMNETPP_COMMON_LIB}
        dl
        pthread
    )
  endif()
endif()

# Source files
set(SOURCES
    Database.cc
    LoadBalancer.cc
    Server1.cc
    Server2.cc
    Server3.cc
)

# Create executable
add_executable(LoadBalancedSystem ${SOURCES})

# Set output binary name: {example}.omnetpp.{os}
set_target_properties(LoadBalancedSystem PROPERTIES
  OUTPUT_NAME "LoadBalancedSystem.omnetpp.${OS_SUFFIX}"
)

# Link OMNeT++ libraries
if(TARGET OmnetPP::main)
  # Use modern CMake targets if available
  target_link_libraries(LoadBalancedSystem PRIVATE
      OmnetPP::main
      OmnetPP::cmdenv
      OmnetPP::envir
      OmnetPP::sim
  )
elseif(TARGET OmnetPP::omnetpp)
  target_link_libraries(LoadBalancedSystem PRIVATE OmnetPP::omnetpp)
else()
  # Fallback to manually found libraries
  target_link_libraries(LoadBalancedSystem PRIVATE
      ${OMNETPP_LIBRARIES}
  )
  target_include_directories(LoadBalancedSystem PRIVATE
      ${OMNETPP_INCLUDE_DIRS}
      ${CMAKE_CURRENT_SOURCE_DIR}
  )
  # Ensure shared libraries are linked properly
  target_link_options(LoadBalancedSystem PRIVATE
      -Wl,--no-as-needed
  )
endif()
