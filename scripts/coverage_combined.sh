#!/bin/bash
# Combined coverage report from all test types (fast, slow, diagram generation)

set -e

echo "🧪 Running combined coverage analysis..."
echo ""

# Clean old coverage data
rm -f cover/*.coverdata 2>/dev/null || true

# Run fast tests (default)
echo "📊 [1/3] Running fast tests..."
MIX_ENV=test mix coveralls --export-coverage fast

# Run slow tests
echo "⏳ [2/3] Running slow tests..."
MIX_ENV=test mix coveralls --only slow --export-coverage slow

# Run diagram generation tests
echo "📈 [3/3] Running diagram generation tests..."
MIX_ENV=test mix coveralls --only diagram_generation --export-coverage diagram

# Merge coverage data
echo ""
echo "🔀 Merging coverage data..."
MIX_ENV=test mix test.coverage

# Generate HTML report
echo ""
echo "📄 Generating HTML report..."
MIX_ENV=test mix coveralls.html --import-cover cover

echo ""
echo "✅ Combined coverage report generated!"
echo "📂 Open: cover/excoveralls.html"
echo ""

