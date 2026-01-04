#!/bin/bash

# Script to create git tags and GitHub releases from CHANGELOG.md
# Usage: ./scripts/create_release.sh [version]
# If version is not provided, uses the latest version from CHANGELOG.md

set -e

CHANGELOG="CHANGELOG.md"
REPO="itsezlife/presentum"

# Extract version from CHANGELOG.md
get_latest_version() {
  grep -m 1 "^## " "$CHANGELOG" | sed 's/^## //'
}

# Extract changelog content for a specific version
get_changelog_for_version() {
  local version=$1
  local in_section=false
  local content=""
  
  while IFS= read -r line; do
    if [[ "$line" == "## $version" ]]; then
      in_section=true
      continue
    fi
    
    if [[ "$in_section" == true ]]; then
      if [[ "$line" =~ ^##[[:space:]]+[0-9]+\.[0-9]+\.[0-9] ]]; then
        break
      fi
      content+="$line"$'\n'
    fi
  done < "$CHANGELOG"
  
  echo "$content"
}

# Create git tag
create_tag() {
  local version=$1
  local message=$2
  
  echo "Creating tag: $version"
  git tag -a "v$version" -m "$message"
  echo "✓ Tag created: v$version"
}

# Create GitHub release (requires gh CLI)
create_github_release() {
  local version=$1
  local changelog=$2
  
  if ! command -v gh &> /dev/null; then
    echo "⚠ GitHub CLI (gh) not found. Skipping GitHub release creation."
    echo "  Install it from: https://cli.github.com/"
    echo "  Or create release manually at: https://github.com/$REPO/releases/new"
    return
  fi
  
  echo "Creating GitHub release: v$version"
  echo "$changelog" | gh release create "v$version" \
    --title "v$version" \
    --notes-file - \
    --repo "$REPO"
  echo "✓ GitHub release created: v$version"
}

# Main execution
VERSION=${1:-$(get_latest_version)}

if [[ -z "$VERSION" ]]; then
  echo "Error: Could not determine version from CHANGELOG.md"
  exit 1
fi

echo "Creating release for version: $VERSION"
echo ""

# Extract changelog content
CHANGELOG_CONTENT=$(get_changelog_for_version "$VERSION")

if [[ -z "$CHANGELOG_CONTENT" ]]; then
  echo "Error: No changelog content found for version $VERSION"
  exit 1
fi

# Show what will be created
echo "Changelog content:"
echo "---"
echo "$CHANGELOG_CONTENT"
echo "---"
echo ""

# Confirm
read -p "Create tag and release for v$VERSION? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

# Create tag
create_tag "$VERSION" "Release $VERSION"

# Create GitHub release
create_github_release "$VERSION" "$CHANGELOG_CONTENT"

echo ""
echo "✓ Release process complete!"
echo ""
echo "Next steps:"
echo "  1. Push tags: git push origin --tags"
echo "  2. Verify release at: https://github.com/$REPO/releases"
echo "  3. The deploy workflow will automatically publish to pub.dev"

