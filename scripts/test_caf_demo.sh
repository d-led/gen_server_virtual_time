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

echo "  Installing dependencies with Conan..."
if ! conan install .. --build=missing 2>&1 | tail -3; then
  echo "❌ Conan install failed"
  exit 1
fi

echo "  Configuring with CMake..."
if ! cmake .. -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake; then
  echo "❌ CMake configuration failed"
  exit 1
fi

echo "  Building..."
if cmake --build . ; then
  echo "✅ Build successful"
  echo ""
  echo "🚀 Running ${EXAMPLE}..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ./$(basename "$EXAMPLE_DIR" | sed 's/_//')
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Demo completed successfully!"
else
  echo "❌ Build failed"
  exit 1
fi

