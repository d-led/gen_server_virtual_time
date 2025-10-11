#!/usr/bin/env bash

# Version bump script for gen_server_virtual_time
# Usage: ./scripts/bump_version.sh <major|minor|patch> [--dry-run]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
BUMP_TYPE=$1
DRY_RUN=false

if [[ "$2" == "--dry-run" ]] || [[ "$2" == "-d" ]]; then
    DRY_RUN=true
fi

if [[ -z "$BUMP_TYPE" ]]; then
    echo -e "${RED}Error: Bump type is required${NC}"
    echo "Usage: $0 <major|minor|patch> [--dry-run]"
    exit 1
fi

if [[ "$BUMP_TYPE" != "major" ]] && [[ "$BUMP_TYPE" != "minor" ]] && [[ "$BUMP_TYPE" != "patch" ]]; then
    echo -e "${RED}Error: Invalid bump type. Must be major, minor, or patch${NC}"
    exit 1
fi

# Check if working directory is clean
if ! git diff-index --quiet HEAD -- && [[ "$DRY_RUN" == false ]]; then
    echo -e "${RED}Error: Working directory is not clean. Commit or stash your changes first.${NC}"
    exit 1
fi

# Extract current version from mix.exs
CURRENT_VERSION=$(grep '@version' "$PROJECT_ROOT/mix.exs" | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')

if [[ -z "$CURRENT_VERSION" ]]; then
    echo -e "${RED}Error: Could not extract current version from mix.exs${NC}"
    exit 1
fi

echo -e "${GREEN}Current version: $CURRENT_VERSION${NC}"

# Parse version numbers
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Bump version based on type
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo -e "${GREEN}New version: $NEW_VERSION${NC}"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Dry run mode - no changes will be made${NC}"
    echo "Would update version from $CURRENT_VERSION to $NEW_VERSION"
    exit 0
fi

# Update mix.exs
echo "Updating mix.exs..."
sed -i.bak "s/@version \"$CURRENT_VERSION\"/@version \"$NEW_VERSION\"/" "$PROJECT_ROOT/mix.exs"
rm "$PROJECT_ROOT/mix.exs.bak"

# Update CHANGELOG.md
TODAY=$(date +%Y-%m-%d)
echo "Updating CHANGELOG.md..."

# Replace [Unreleased] with the new version
sed -i.bak "s/## \[Unreleased\]/## [Unreleased]\n\n## [$NEW_VERSION] - $TODAY/" "$PROJECT_ROOT/CHANGELOG.md"

# Update version comparison links at the bottom
if grep -q "\[Unreleased\]:" "$PROJECT_ROOT/CHANGELOG.md"; then
    # Update the Unreleased link
    sed -i.bak "s|\[Unreleased\]:.*|\[Unreleased\]: https://github.com/dmitryledentsov/gen_server_virtual_time/compare/v$NEW_VERSION...HEAD|" "$PROJECT_ROOT/CHANGELOG.md"
    
    # Add the new version link
    sed -i.bak "/\[Unreleased\]:/a\\
[$NEW_VERSION]: https://github.com/dmitryledentsov/gen_server_virtual_time/compare/v$CURRENT_VERSION...v$NEW_VERSION
" "$PROJECT_ROOT/CHANGELOG.md"
else
    # Add initial version links if they don't exist
    echo "" >> "$PROJECT_ROOT/CHANGELOG.md"
    echo "[Unreleased]: https://github.com/dmitryledentsov/gen_server_virtual_time/compare/v$NEW_VERSION...HEAD" >> "$PROJECT_ROOT/CHANGELOG.md"
    echo "[$NEW_VERSION]: https://github.com/dmitryledentsov/gen_server_virtual_time/releases/tag/v$NEW_VERSION" >> "$PROJECT_ROOT/CHANGELOG.md"
fi

rm "$PROJECT_ROOT/CHANGELOG.md.bak"

# Update README.md installation instructions
if grep -q "gen_server_virtual_time.*~>" "$PROJECT_ROOT/README.md"; then
    echo "Updating README.md..."
    sed -i.bak "s/{:gen_server_virtual_time, \"~> [0-9.]*\"}/{:gen_server_virtual_time, \"~> $MAJOR.$MINOR\"}/" "$PROJECT_ROOT/README.md"
    rm "$PROJECT_ROOT/README.md.bak"
fi

# Git operations
echo "Committing changes..."
git add "$PROJECT_ROOT/mix.exs" "$PROJECT_ROOT/CHANGELOG.md"

if [[ -f "$PROJECT_ROOT/README.md.bak" ]]; then
    rm "$PROJECT_ROOT/README.md.bak"
fi

if grep -q "gen_server_virtual_time.*~>" "$PROJECT_ROOT/README.md"; then
    git add "$PROJECT_ROOT/README.md"
fi

git commit -m "Bump version to $NEW_VERSION"

echo "Creating tag v$NEW_VERSION..."
git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"

echo -e "${GREEN}✓ Version bumped successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git show"
echo "  2. Update CHANGELOG.md with release notes for v$NEW_VERSION"
echo "  3. Push the changes: git push origin main"
echo "  4. Push the tag: git push origin v$NEW_VERSION"
echo ""
echo -e "${YELLOW}Note: Pushing the tag will trigger automatic publishing to Hex.pm${NC}"

