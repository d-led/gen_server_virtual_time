#!/usr/bin/env bash
# Test script for Ractor (Rust) examples
# Usage: ./scripts/test_ractor_demo.sh <example_name>

set -e

EXAMPLE_NAME="$1"

if [ -z "$EXAMPLE_NAME" ]; then
  echo "Usage: $0 <example_name>"
  echo "Examples: ractor_pubsub, ractor_pipeline, ractor_burst, ractor_loadbalanced"
  exit 1
fi

EXAMPLE_DIR="examples/${EXAMPLE_NAME}"

if [ ! -d "$EXAMPLE_DIR" ]; then
  echo "Error: Example directory $EXAMPLE_DIR does not exist"
  exit 1
fi

echo "================================================"
echo "Testing Ractor example: $EXAMPLE_NAME"
echo "================================================"

cd "$EXAMPLE_DIR"

echo ""
echo "→ Fetching dependencies..."
cargo fetch

echo ""
echo "→ Building project..."
cargo build --verbose

echo ""
echo "→ Running tests..."
cargo test --verbose

echo ""
echo "→ Building release..."
cargo build --release --verbose

echo ""
echo "→ Running demo (with 5s timeout)..."
timeout 5 cargo run --release || exit_code=$?

if [ $exit_code -eq 124 ] || [ $exit_code -eq 143 ]; then
  echo "✓ Demo ran successfully and was terminated after timeout"
elif [ -z "$exit_code" ]; then
  echo "✓ Demo ran successfully and exited cleanly"
else
  echo "✗ Demo failed with exit code $exit_code"
  exit $exit_code
fi

echo ""
echo "================================================"
echo "✅ $EXAMPLE_NAME validation completed successfully"
echo "================================================"

