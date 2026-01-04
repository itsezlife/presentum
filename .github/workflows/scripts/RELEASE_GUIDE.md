# Release Guide

This guide helps you create git tags and GitHub releases from CHANGELOG.md.

## Quick Release (Recommended)

For the latest version in CHANGELOG.md:

```bash
./scripts/create_release.sh
```

For a specific version:

```bash
./scripts/create_release.sh 0.3.6
```

## Manual Process

### 1. Create Git Tag

```bash
# Extract changelog for version (e.g., 0.3.6)
# Copy the content from CHANGELOG.md for that version

# Create annotated tag
git tag -a v0.3.6 -m "Release 0.3.6

- **Feat**: Added debouncing to composition outlets
- **Example**: Improved transition smoothness
..."

# Push tag (triggers deploy workflow)
git push origin v0.3.6
```

### 2. Create GitHub Release

#### Using GitHub CLI (gh):

```bash
# Install gh CLI if needed: https://cli.github.com/
gh release create v0.3.6 \
  --title "v0.3.6" \
  --notes "$(./scripts/create_release.sh 0.3.6 --extract-only)"
```

#### Using GitHub Web UI:

1. Go to https://github.com/itsezlife/presentum/releases/new
2. Tag: `v0.3.6`
3. Title: `v0.3.6`
4. Description: Copy the changelog content from CHANGELOG.md for that version
5. Click "Publish release"

## Automated Deployment

When you push a tag matching `[0-9]+.[0-9]+.[0-9]+*`, the GitHub Actions workflow will:

1. Run tests
2. Publish to pub.dev automatically

## Creating Tags for Multiple Versions

If you need to create tags for all versions in CHANGELOG.md:

```bash
# Extract all versions
grep "^## " CHANGELOG.md | sed 's/^## //' | while read version; do
  echo "Would create tag: v$version"
  # Uncomment to actually create:
  # git tag -a "v$version" -m "Release $version"
done
```

## Best Practices

1. **Always update CHANGELOG.md first** before creating a release
2. **Verify pubspec.yaml version** matches the release version
3. **Test locally** before creating the tag
4. **Push tag** to trigger automatic deployment
5. **Verify deployment** at https://pub.dev/packages/presentum

## Troubleshooting

### Tag already exists

```bash
# Delete local tag
git tag -d v0.3.6

# Delete remote tag (if pushed)
git push origin --delete v0.3.6

# Recreate
./scripts/create_release.sh 0.3.6
```

### Need to update release notes

```bash
# Update the release via GitHub CLI
gh release edit v0.3.6 --notes "Updated release notes"
```
