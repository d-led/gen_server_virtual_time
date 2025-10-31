#!/bin/bash
set -e

# Test OMNeT++ high-frequency simulation using act
# This requires ~/.actrc with: --container-architecture=linux/amd64

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Testing OMNeT++ High-Frequency Simulation with Act          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Navigate to project root
cd "$(dirname "$0")/.."

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo "❌ Error: 'act' is not installed"
    echo "Install it with: brew install act"
    exit 1
fi

# Check if ~/.actrc exists with correct configuration
if [ ! -f ~/.actrc ]; then
    echo "⚠️  Warning: ~/.actrc not found"
    echo "Creating ~/.actrc with: --container-architecture=linux/amd64"
    echo "--container-architecture=linux/amd64" > ~/.actrc
fi

if ! grep -q "linux/amd64" ~/.actrc; then
    echo "⚠️  Warning: ~/.actrc doesn't contain linux/amd64"
    echo "Adding --container-architecture=linux/amd64 to ~/.actrc"
    echo "--container-architecture=linux/amd64" >> ~/.actrc
fi

# Ensure high-freq example is generated
echo "📚 Generating OMNeT++ examples..."
mix run scripts/generate_omnetpp_examples.exs 2>&1 | grep -E "(Generating:|Generated|✅|❌)" || true

echo ""
echo "🚀 Running OMNeT++ high-frequency simulation with Act..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Note: act doesn't work well with the full CI workflow due to setup-beam issues
# So we simulate just the Docker build part that works

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
    echo "🚀 Running high-frequency simulation (1ms intervals, 3s duration)..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd ..
    cd build
    ./HighFreqNetwork.omnetpp.linux -f ../omnetpp.ini -n .. 2>&1
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  '

cd ../..

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ OMNeT++ High-Frequency Simulation Test: SUCCESS          ║"
echo "╚══════════════════════════════════════════════════════════════╝"

