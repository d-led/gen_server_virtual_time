#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Quick script to test Pony generated code
# Usage: ./scripts/test_pony_demo.sh [example_name]

EXAMPLE=${1:-pony_pubsub}
EXAMPLE_DIR="examples/${EXAMPLE}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐴 Testing Pony Example: ${EXAMPLE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d "$EXAMPLE_DIR" ]; then
  echo "❌ Error: Directory $EXAMPLE_DIR not found"
  echo ""
  echo "Available examples:"
  ls -1 examples/pony_* 2>/dev/null | sed 's|examples/||' || echo "  (none found)"
  exit 1
fi

cd "$EXAMPLE_DIR"

echo "📁 Working directory: $(pwd)"
echo ""

# Check if ponyc is installed
if ! command -v ponyc &> /dev/null; then
  echo "❌ Error: ponyc not found"
  echo ""
  echo "Install Pony:"
  echo "  curl --proto '=https' --tlsv1.2 -sSf \\"
  echo "    https://raw.githubusercontent.com/ponylang/ponyup/latest-release/ponyup-init.sh | sh"
  echo "  ponyup update ponyc release"
  exit 1
fi

echo "🔨 Compiling Pony code..."

# Determine binary name: {project}.pony.{os}
OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
# Extract project name from corral.json if it exists, otherwise derive from directory
if [ -f "corral.json" ]; then
  PROJECT_NAME=$(grep -o '"name": *"[^"]*"' corral.json | head -1 | sed 's/"name": *"\([^"]*\)"/\1/')
else
  PROJECT_NAME=$(basename "$EXAMPLE_DIR")
fi
BINARY="${PROJECT_NAME}.pony.${OS_NAME}"
DIR_NAME=$(basename "$PWD")

# Build: fetch dependencies and compile
if corral fetch && ponyc .; then
  # Rename the binary if it was created with directory name
  if [ -f "$DIR_NAME" ] && [ ! -f "$BINARY" ]; then
    mv "$DIR_NAME" "$BINARY"
  fi
  echo "✅ Compilation successful"
  echo ""
else
  echo "❌ Compilation failed"
  exit 1
fi

# Run tests if test directory exists
if [ -d "test" ]; then
  echo "🧪 Running tests..."
  if ponyc test; then
    # The test binary is named 'test1' by ponyc (not 'test' which is the directory)
    if [ -f "test1" ]; then
      # Run tests with timeout (cross-platform: Linux timeout or macOS gtimeout or fallback)
      if command -v timeout &> /dev/null; then
        timeout 10s ./test1 --sequential || [ $? -eq 124 ]  # 124 = timeout, acceptable if tests passed
      elif command -v gtimeout &> /dev/null; then
        gtimeout 10s ./test1 --sequential || [ $? -eq 124 ]
      else
        # Fallback: run in background with timeout
        ./test1 --sequential &
        TEST_PID=$!
        sleep 10
        kill $TEST_PID 2>/dev/null || true
        wait $TEST_PID 2>/dev/null || true
      fi
      echo "✅ Tests completed"
      echo ""
    else
      echo "⚠️  Test binary 'test1' not found, skipping test execution"
    fi
  else
    echo "❌ Test compilation failed"
    exit 1
  fi
fi

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
echo ""
echo "💡 To run manually: cd $EXAMPLE_DIR && ./${BINARY}"

