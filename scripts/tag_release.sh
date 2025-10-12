#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Get current version from mix.exs
CURRENT_VERSION=$(grep '@version "' mix.exs | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [ -z "$CURRENT_VERSION" ]; then
  echo "❌ Error: Could not read version from mix.exs"
  exit 1
fi

TAG_NAME="v${CURRENT_VERSION}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Current version: ${CURRENT_VERSION}"
echo "🏷️  Will create tag: ${TAG_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if tag already exists locally
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
  echo "⚠️  Warning: Tag ${TAG_NAME} already exists locally"
  git show "$TAG_NAME" --no-patch --format="%h %s (%ci)"
  echo ""
fi

# Check if tag exists on remote
if git ls-remote --tags origin | grep -q "refs/tags/${TAG_NAME}$"; then
  echo "❌ Error: Tag ${TAG_NAME} already exists on remote"
  echo "   Use 'git tag -d ${TAG_NAME}' to delete locally if needed"
  exit 1
fi

# Show current git status
echo "📋 Git Status:"
if [ -n "$(git status --porcelain)" ]; then
  echo "⚠️  You have uncommitted changes:"
  git status --short
  echo ""
else
  echo "✅ Working directory is clean"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show recent commits
echo "📝 Recent commits:"
git log --oneline -5
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Confirm with user
read -p "⚠️  Tag ${TAG_NAME} and push to origin? Type 'yes' to confirm: " -r
echo ""

if [[ ! $REPLY =~ ^yes$ ]]; then
  echo "❌ Aborted. Tag was NOT created."
  exit 1
fi

# Create the tag
echo "🏷️  Creating tag ${TAG_NAME}..."
git tag "$TAG_NAME"

echo "✅ Tag created locally"
echo ""

# Push the tag
echo "🚀 Pushing tag to origin..."
git push origin "$TAG_NAME"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Success! Tag ${TAG_NAME} has been pushed to origin"
echo ""
echo "📦 GitHub Actions will now:"
if [[ $CURRENT_VERSION =~ -rc\.|beta\.|alpha\. ]]; then
  echo "   1. Run tests"
  echo "   2. Publish to Hex.pm as PRE-RELEASE"
  echo "   3. Create GitHub Pre-release"
else
  echo "   1. Run tests"
  echo "   2. Publish to Hex.pm as STABLE"
  echo "   3. Create GitHub Release"
fi
echo ""
echo "🔍 Track progress:"
echo "   https://github.com/d-led/gen_server_virtual_time/actions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

