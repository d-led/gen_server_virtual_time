#!/bin/bash
# Version bumping script inspired by Elixir's release process
# Usage:
#   ./scripts/bump_version.sh patch         # 0.2.0 -> 0.2.1
#   ./scripts/bump_version.sh minor         # 0.2.0 -> 0.3.0
#   ./scripts/bump_version.sh major         # 0.2.0 -> 1.0.0
#   ./scripts/bump_version.sh rc            # 0.2.0 -> 0.2.1-rc.0 or 0.2.0-rc.0 -> 0.2.0-rc.1
#   ./scripts/bump_version.sh release       # 0.2.0-rc.0 -> 0.2.0

set -e

BUMP_TYPE=${1:-patch}
MIX_FILE="mix.exs"
CHANGELOG="CHANGELOG.md"

# Get current version from mix.exs
CURRENT_VERSION=$(grep '@version "' $MIX_FILE | head -1 | sed 's/.*"\(.*\)".*/\1/')

echo "Current version: $CURRENT_VERSION"

# Parse version components
if [[ $CURRENT_VERSION =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-rc\.([0-9]+))?$ ]]; then
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"
  RC_NUM="${BASH_REMATCH[5]}"
else
  echo "Error: Could not parse version $CURRENT_VERSION"
  exit 1
fi

# Calculate new version
case $BUMP_TYPE in
  major)
    NEW_VERSION="$((MAJOR + 1)).0.0"
    ;;
  minor)
    NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
    ;;
  patch)
    NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
    ;;
  rc)
    if [ -z "$RC_NUM" ]; then
      # No RC yet, create RC.0 for next patch version
      NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))-rc.0"
    else
      # Bump RC number
      NEW_VERSION="$MAJOR.$MINOR.$PATCH-rc.$((RC_NUM + 1))"
    fi
    ;;
  release)
    if [ -z "$RC_NUM" ]; then
      echo "Error: Not a release candidate version"
      exit 1
    fi
    # Remove RC suffix
    NEW_VERSION="$MAJOR.$MINOR.$PATCH"
    ;;
  *)
    echo "Error: Unknown bump type: $BUMP_TYPE"
    echo "Usage: $0 {major|minor|patch|rc|release}"
    exit 1
    ;;
esac

echo "New version: $NEW_VERSION"

# Update mix.exs
sed -i.bak "s/@version \"$CURRENT_VERSION\"/@version \"$NEW_VERSION\"/" $MIX_FILE
rm -f $MIX_FILE.bak

# Update CHANGELOG.md header
TODAY=$(date +%Y-%m-%d)
if grep -q "^## \[Unreleased\]" $CHANGELOG; then
  # Add new version header after Unreleased
  sed -i.bak "/^## \[Unreleased\]/a\\
\\
## [$NEW_VERSION] - $TODAY
" $CHANGELOG
  rm -f $CHANGELOG.bak
else
  echo "Warning: No [Unreleased] section found in CHANGELOG.md"
fi

echo ""
echo "✅ Version bumped from $CURRENT_VERSION to $NEW_VERSION"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Update CHANGELOG.md with release notes"
echo "  3. Commit: git add -A && git commit -m \"Release v$NEW_VERSION\""
echo "  4. Tag: git tag v$NEW_VERSION"
echo "  5. Push: git push && git push --tags"
echo ""
if [[ $NEW_VERSION =~ -rc\. ]]; then
  echo "📦 This is a pre-release (RC). It will be marked as 'prerelease' on GitHub."
else
  echo "📦 This is a stable release. It will be published to Hex.pm as stable."
fi
