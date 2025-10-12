#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Quick script to test Phony (Go) generated code
# Usage: ./scripts/test_phony_demo.sh [example_name]

EXAMPLE=${1:-phony_pubsub}
EXAMPLE_DIR="examples/${EXAMPLE}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐹 Testing Phony Example: ${EXAMPLE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -d "$EXAMPLE_DIR" ]; then
  echo "❌ Error: Directory $EXAMPLE_DIR not found"
  echo ""
  echo "Available examples:"
  ls -1 examples/phony_* 2>/dev/null | sed 's|examples/||' || echo "  (none found)"
  exit 1
fi

cd "$EXAMPLE_DIR"

echo "📁 Working directory: $(pwd)"
echo ""

# Check if Go is installed
if ! command -v go &> /dev/null; then
  echo "❌ Error: go not found"
  echo ""
  echo "Install Go:"
  echo "  brew install go (macOS)"
  echo "  apt-get install golang (Linux)"
  echo "  Or visit: https://go.dev/doc/install"
  exit 1
fi

echo "🔨 Building Phony/Go code..."
if make build; then
  echo "✅ Build successful"
  echo ""
  
  # Determine binary name: {project}.phony.{os}
  OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
  # Extract project name from go.mod if it exists, otherwise derive from directory
  if [ -f "go.mod" ]; then
    PROJECT_NAME=$(grep -o 'module [^ ]*' go.mod | head -1 | awk '{print $2}' | xargs basename)
  else
    PROJECT_NAME=$(basename "$EXAMPLE_DIR")
  fi
  BINARY="${PROJECT_NAME}.phony.${OS_NAME}"
  
  echo "🚀 Running ${EXAMPLE} for 3 seconds..."
  echo "   Binary: ${BINARY}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Run in background and kill after 3 seconds (works on both macOS and Linux)
  ./"${BINARY}" &
  PID=$!
  sleep 3
  kill $PID 2>/dev/null || true
  wait $PID 2>/dev/null || true
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Demo ran successfully! (stopped after 3s)"
  echo ""
  echo "💡 To run manually: cd $EXAMPLE_DIR && ./${BINARY}"
else
  echo "❌ Build failed"
  exit 1
fi

