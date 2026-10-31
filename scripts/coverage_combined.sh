#!/bin/bash
# Combined coverage report for the clock package: its fast and slow tests merged
# into one report.
#
# The package is named here rather than assumed: coverage is per project, and the
# repository root is only a workspace. The diagram tests live in
# `actor_simulation`, so they are not part of this report.
set -e

cd "$(dirname "$0")/../packages/gen_server_virtual_time"

echo "🧪 Running combined coverage analysis..."
echo ""

# Clean old coverage data
rm -f cover/*.coverdata 2>/dev/null || true

# Run fast tests (default)
echo "📊 [1/2] Running fast tests..."
MIX_ENV=test mix coveralls --export-coverage fast

# Run slow tests
echo "⏳ [2/2] Running slow tests..."
MIX_ENV=test mix coveralls --only slow --export-coverage slow

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
echo "📂 Open: packages/gen_server_virtual_time/cover/excoveralls.html"
echo ""

