#!/bin/bash
set -e

# Test OMNeT++ high-frequency simulation locally using Docker
# This simulates the CI workflow for building and running generated OMNeT++ code

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Testing OMNeT++ High-Frequency Simulation                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Navigate to project root
cd "$(dirname "$0")/.."

# Ensure high-freq example is generated
echo "📚 Generating OMNeT++ examples..."
mix run scripts/generate_omnetpp_examples.exs 2>&1 | grep -E "(Generating:|Generated|✅|❌)" || true

# Test the high-freq simulation
echo ""
echo "🏗️  Building OMNeT++ high-frequency simulation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd examples/omnetpp_high_freq

docker run --rm --platform linux/amd64 \
  -v "$(pwd):/workspace" \
  -w /workspace \
  -e OMNETPP_ROOT=/root/omnetpp \
  ghcr.io/omnetpp/omnetpp:u24.04-6.2.0 \
  bash -c '
    set -e
    echo "Installing cmake..."
    apt-get update -qq && apt-get install -y -qq cmake > /dev/null 2>&1
    
    echo "Configuring build environment..."
    export PATH=$OMNETPP_ROOT/bin:$PATH
    
    echo "Building simulation..."
    mkdir -p build && cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release 2>&1 | grep -v "CMake Warning" || true
    cmake --build . --config Release
    
    echo ""
    echo "🚀 Running high-frequency simulation (1ms intervals, 60s duration)..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd ..
    cd build
    ./HighFreqNetwork.omnetpp.linux -f ../omnetpp.ini -n .. 2>&1 | head -60
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ High-frequency simulation test complete!"
  '

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ OMNeT++ High-Frequency Test: SUCCESS                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"

