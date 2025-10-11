#!/usr/bin/env bash

# Pre-release checks for gen_server_virtual_time
# Ensures everything is ready before publishing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Running pre-release checks...${NC}"
echo ""

# Check 1: Clean working directory
echo "1. Checking working directory..."
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}✗ Working directory is not clean${NC}"
    echo "  Commit or stash your changes first."
    exit 1
fi
echo -e "${GREEN}✓ Working directory is clean${NC}"

# Check 2: On main branch
echo "2. Checking current branch..."
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo -e "${YELLOW}⚠ Not on main branch (currently on: $CURRENT_BRANCH)${NC}"
    echo "  Consider switching to main for releases."
fi

# Check 3: Dependencies
echo "3. Fetching dependencies..."
cd "$PROJECT_ROOT"
mix deps.get > /dev/null 2>&1
echo -e "${GREEN}✓ Dependencies fetched${NC}"

# Check 4: Compilation
echo "4. Compiling project..."
if ! mix compile --warnings-as-errors > /dev/null 2>&1; then
    echo -e "${RED}✗ Compilation failed or has warnings${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Compilation successful${NC}"

# Check 5: Tests
echo "5. Running tests..."
if ! mix test > /dev/null 2>&1; then
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ All tests passed${NC}"

# Check 6: Code formatting
echo "6. Checking code formatting..."
if ! mix format --check-formatted > /dev/null 2>&1; then
    echo -e "${RED}✗ Code is not properly formatted${NC}"
    echo "  Run: mix format"
    exit 1
fi
echo -e "${GREEN}✓ Code is properly formatted${NC}"

# Check 7: Credo
echo "7. Running Credo..."
if ! mix credo --strict > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Credo found issues${NC}"
    echo "  Run: mix credo --strict"
    # Don't fail on credo issues, just warn
fi

# Check 8: Documentation
echo "8. Building documentation..."
if ! mix docs > /dev/null 2>&1; then
    echo -e "${RED}✗ Documentation build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Documentation built successfully${NC}"

# Check 9: Package files
echo "9. Checking package files..."
REQUIRED_FILES=("README.md" "LICENSE" "CHANGELOG.md" "mix.exs")
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
        echo -e "${RED}✗ Missing required file: $file${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✓ All required files present${NC}"

# Check 10: CHANGELOG has unreleased section
echo "10. Checking CHANGELOG..."
if ! grep -q "## \[Unreleased\]" "$PROJECT_ROOT/CHANGELOG.md"; then
    echo -e "${YELLOW}⚠ CHANGELOG.md doesn't have [Unreleased] section${NC}"
fi

# Extract current version
CURRENT_VERSION=$(grep '@version' "$PROJECT_ROOT/mix.exs" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
echo ""
echo -e "${GREEN}Current version: $CURRENT_VERSION${NC}"

# Check if version tag already exists
if git rev-parse "v$CURRENT_VERSION" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Tag v$CURRENT_VERSION already exists${NC}"
    echo "  You may need to bump the version first."
fi

echo ""
echo -e "${GREEN}✓ All checks passed!${NC}"
echo ""
echo "Ready to release. Next steps:"
echo "  1. Review CHANGELOG.md and add release notes if needed"
echo "  2. Run: ./scripts/bump_version.sh <major|minor|patch>"
echo "  3. Or manually tag: git tag -a v<VERSION> -m 'Release v<VERSION>'"
echo "  4. Push changes: git push origin main"
echo "  5. Push tag: git push origin v<VERSION>"

