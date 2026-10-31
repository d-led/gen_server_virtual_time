#!/bin/bash
# Tag the current repository state with the version from mix.exs
# Usage:
#   ./scripts/tag_and_push_version.sh

set -e

MIX_FILE="mix.exs"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: Not in a git repository"
  exit 1
fi

# Check if the repository is in a clean state
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Repository is not in a clean state"
  echo ""
  echo "Please commit or stash your changes before tagging:"
  git status
  exit 1
fi

# Get the version every package shares
VERSION=$(tr -d '[:space:]' < VERSION)

if [ -z "$VERSION" ]; then
  echo "Error: Could not read the version from VERSION"
  exit 1
fi

# The three packages are published from this one tag, so they have to agree
elixir scripts/release.exs check || exit 1

TAG="v$VERSION"

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Error: Tag $TAG already exists"
  echo ""
  echo "If you want to move the tag to the current commit, use:"
  echo "  git tag -d $TAG"
  echo "  git tag $TAG"
  echo "  git push origin :refs/tags/$TAG"
  echo "  git push origin $TAG"
  exit 1
fi

echo "Current version: $VERSION"
echo "Creating tag: $TAG"
echo ""

# Create the tag
git tag "$TAG"

echo "✅ Tag $TAG created successfully"
echo ""

# Push tag to origin
echo "Pushing tag to origin..."
git push origin "$TAG"

echo ""
echo "✅ Tag $TAG pushed to origin successfully"
echo ""

