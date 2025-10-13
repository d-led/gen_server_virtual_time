#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Quick script to test CAF generated code
# Usage: ./scripts/test_caf_demo.sh [example_name]

EXAMPLE=${1:-caf_pubsub}
EXAMPLE_DIR="examples/${EXAMPLE}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎭 Testing CAF Example: ${EXAMPLE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d "$EXAMPLE_DIR" ]; then
  echo "❌ Error: Directory $EXAMPLE_DIR not found"
  echo ""
  echo "Available examples:"
  ls -1 examples/caf_* 2>/dev/null | sed 's|examples/||' || echo "  (none found)"
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

if ! command -v conan &> /dev/null; then
  echo "❌ Error: conan not found"
  echo "Install: pip install conan"
  exit 1
fi

echo "🔨 Building CAF project..."
mkdir -p build
cd build

echo "  Installing dependencies with Conan (this may take a while)..."
echo "  Command: conan install .. --build=missing -s build_type=Release"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ! conan install .. --build=missing -s build_type=Release; then
  echo ""
  echo "❌ Conan install failed"
  echo "  Try: conan profile detect --force"
  exit 1
fi
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "  Configuring with CMake..."
if ! cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake; then
  echo "❌ CMake configuration failed"
  exit 1
fi

echo "  Building..."
if cmake --build . ; then
  echo "✅ Build successful"
  echo ""
  
  # Run tests with ctest (matching CI behavior)
  echo "🧪 Running tests with ctest..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if ctest -C Release --output-on-failure; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ All tests passed!"
  else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ Tests failed"
    exit 1
  fi
  echo ""
  
  # Determine binary name: {project}.caf.{os}
  OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
  # Extract project name from CMakeLists.txt
  cd ..
  PROJECT_NAME=$(grep -o 'project([^)]*)' CMakeLists.txt | head -1 | sed 's/project(\([^ ]*\).*/\1/')
  cd build
  BINARY="${PROJECT_NAME}.caf.${OS_NAME}"
  
  # Determine demo runtime: 1s for burst examples (lots of output), 3s for others
  if [[ "$EXAMPLE" == *"burst"* ]]; then
    DEMO_TIME=1
  else
    DEMO_TIME=3
  fi
  
  echo "🚀 Running ${EXAMPLE} for ${DEMO_TIME} second(s)..."
  echo "   Binary: ${BINARY}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Run in background and kill after timeout (works on both macOS and Linux)
  ./"${BINARY}" &
  PID=$!
  sleep $DEMO_TIME
  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Demo ran successfully! (stopped after ${DEMO_TIME}s)"
else
  echo "❌ Build failed"
  exit 1
fi

