#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Quick script to test OMNeT++ generated code
# Usage: ./scripts/test_omnetpp_demo.sh [example_name]

EXAMPLE=${1:-omnetpp_pubsub}
EXAMPLE_DIR="examples/${EXAMPLE}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Testing OMNeT++ Example: ${EXAMPLE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d "$EXAMPLE_DIR" ]; then
  echo "❌ Error: Directory $EXAMPLE_DIR not found"
  echo ""
  echo "Available examples:"
  ls -1 examples/omnetpp_* 2>/dev/null | sed 's|examples/||' || echo "  (none found)"
  exit 1
fi

cd "$EXAMPLE_DIR"

echo "📁 Working directory: $(pwd)"
echo ""

# Check prerequisites
if ! command -v cmake &> /dev/null; then
  echo "❌ Error: cmake not found"
  echo "Install: brew install cmake (macOS) or apt-get install cmake (Linux)"
  exit 1
fi

# Check if OMNeT++ is installed
if ! command -v opp_run &> /dev/null; then
  echo "❌ Error: OMNeT++ not found (opp_run command not available)"
  echo ""
  echo "Install OMNeT++:"
  echo "  Visit: https://omnetpp.org/download/"
  echo "  Follow the installation guide for your OS"
  echo ""
  echo "After installation, make sure to source the setenv script:"
  echo "  source <omnetpp-dir>/setenv"
  exit 1
fi

echo "🔨 Building OMNeT++ project..."
mkdir -p build
cd build

echo "  Configuring with CMake..."
if ! cmake ..; then
  echo "❌ CMake configuration failed"
  exit 1
fi

echo "  Building..."
if cmake --build . ; then
  echo "✅ Build successful"
  echo ""
  
  # Determine binary name: {project}.omnetpp.{os}
  OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
  # Extract project name from CMakeLists.txt
  cd ..
  PROJECT_NAME=$(grep -o 'project([^)]*)' CMakeLists.txt | head -1 | sed 's/project(\([^ ]*\).*/\1/')
  cd build
  BINARY="${PROJECT_NAME}.omnetpp.${OS_NAME}"
  
  echo "🚀 Running ${EXAMPLE} simulation..."
  echo "   Binary: ${BINARY}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Run the simulation with the configuration from omnetpp.ini
  # OMNeT++ simulations typically run to completion based on the config
  if [ -f "../omnetpp.ini" ]; then
    ./"${BINARY}" -u Cmdenv -c General -n ..
  else
    ./"${BINARY}"
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Simulation completed successfully!"
else
  echo "❌ Build failed"
  exit 1
fi

