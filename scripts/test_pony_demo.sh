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
if ponyc .; then
  echo "✅ Compilation successful"
  echo ""
  echo "🚀 Running ${EXAMPLE} for 3 seconds..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Run in background and kill after 3 seconds
  timeout 3s ./"$(basename "$EXAMPLE_DIR")" || true
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Demo ran successfully! (stopped after 3s)"
  echo ""
  echo "💡 To run manually: cd $EXAMPLE_DIR && ./$(basename "$EXAMPLE_DIR")"
else
  echo "❌ Compilation failed"
  exit 1
fi

