# Versioning & Release Workflow

This document describes the versioning and release process for
GenServerVirtualTime, following Elixir project conventions.

## Version Scheme

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., `1.2.3`)
- **MAJOR.MINOR.PATCH-rc.N** (e.g., `1.2.3-rc.0`) for release candidates

Examples from Elixir itself:

- Stable: `v1.18.4`, `v1.18.3`, `v1.18.2`
- Release Candidates: `v1.19.0-rc.0`, `v1.19.0-rc.1`, `v1.19.0-rc.2`

## Current Version

Current version is stored in `mix.exs`:

```elixir
@version "0.2.0"
```

## Bump Version Script

Use `scripts/bump_version.sh` to manage versions:

### Regular Version Bumps

```bash
# Patch version: 0.2.0 → 0.2.1
./scripts/bump_version.sh patch

# Minor version: 0.2.0 → 0.3.0
./scripts/bump_version.sh minor

# Major version: 0.2.0 → 1.0.0
./scripts/bump_version.sh major
```

### Release Candidate Workflow

**1. Create first RC:**

```bash
# From stable 0.2.0 → 0.2.1-rc.0
./scripts/bump_version.sh rc
```

**2. Iterate on RC:**

```bash
# From 0.2.1-rc.0 → 0.2.1-rc.1
./scripts/bump_version.sh rc

# From 0.2.1-rc.1 → 0.2.1-rc.2
./scripts/bump_version.sh rc
```

**3. Release stable from RC:**

```bash
# From 0.2.1-rc.2 → 0.2.1 (stable)
./scripts/bump_version.sh release
```

**Alternative: Skip RC and go to next version:**

```bash
# From 0.2.1-rc.0 → 0.3.0 (abandon RC, jump to minor)
./scripts/bump_version.sh minor
```

## Complete Release Process

### 1. Prepare Release

```bash
# Create RC or bump version
./scripts/bump_version.sh rc  # or: patch, minor, major

# Review changes
git diff

# Update CHANGELOG.md
# - Move unreleased items under new version
# - Add release notes
# - Mention breaking changes if any
```

### 2. Commit and Tag

```bash
# Commit changes
git add -A
git commit -m "Release v0.2.1-rc.0"

# Create tag
git tag v0.2.1-rc.0

# Push
git push && git push --tags
```

### 3. Automated Publishing

When you push a tag matching `v*.*.*`, the GitHub Actions workflow
automatically:

1. ✅ Runs all tests
2. ✅ Builds documentation
3. ✅ Publishes to [Hex.pm](https://hex.pm/packages/gen_server_virtual_time)
4. ✅ Creates GitHub Release with auto-generated notes
5. ✅ Marks pre-releases appropriately (RC, beta, alpha)

**Pre-release tags** (with `-rc.`, `-beta.`, `-alpha.`):

- Published to Hex.pm as pre-release
- Marked as "Pre-release" on GitHub
- Can be installed with: `{:gen_server_virtual_time, "~> 0.2.1-rc.0"}`

**Stable tags** (no suffix):

- Published to Hex.pm as stable
- Full GitHub Release
- Default installation: `{:gen_server_virtual_time, "~> 0.2.0"}`

## Hex.pm Version Management

### Can you delete versions?

**From Hex.pm:**

- ⚠️ **Packages can be retired but NOT deleted** after 1 hour
- Use `mix hex.retire` to mark a version as retired
- Retired versions show a warning but remain installable

**From HexDocs:**

- ✅ Documentation versions **cannot be deleted** once published
- Old versions remain accessible at
  `https://hexdocs.pm/gen_server_virtual_time/0.2.0`

**Best Practices:**

- Don't publish broken RC versions if possible
- Test thoroughly before tagging
- Use RC versions for testing, stable for production
- If an RC is broken, skip to the next RC number

### Retiring a version

If you need to retire a problematic version:

```bash
# Retire a specific version
mix hex.retire gen_server_virtual_time 0.2.1-rc.0 --reason security

# Un-retire
mix hex.retire gen_server_virtual_time 0.2.1-rc.0 --unretire
```

Retirement reasons:

- `security` - Security issue
- `deprecated` - Deprecated in favor of newer version
- `invalid` - Published by mistake
- `other` - Other reason (provide message)

## Version Support Policy

- **Latest stable**: Full support, bug fixes, new features
- **Previous minor**: Security fixes only
- **Older versions**: No support (users should upgrade)

## Breaking Changes

When introducing breaking changes:

1. Bump **MAJOR** version (e.g., `0.2.0` → `1.0.0`)
2. Document breaking changes in CHANGELOG under "Breaking Changes" section
3. Provide migration guide if needed
4. Consider deprecation warnings in previous version first

## CI/CD Workflows

### Publish Workflow

**Trigger:** Push tag matching `v*.*.*`, `v*.*.*-rc.*`, etc.

**File:** `.github/workflows/publish.yml`

**Steps:**

1. Checkout code
2. Setup Elixir/OTP
3. Install dependencies
4. Run tests
5. Build docs
6. Publish to Hex.pm (with `HEX_API_KEY` secret)
7. Create GitHub Release

### Testing Before Release

Before tagging, ensure:

```bash
# All tests pass
mix test

# No warnings
mix compile --warnings-as-errors

# Formatting is correct
mix format --check-formatted

# Credo is clean
mix credo --strict

# Dialyzer is happy
mix dialyzer
```

Or use the pre-commit task:

```bash
mix precommit
```

## Example Release Workflow

**Scenario: Release 0.3.0 with RC testing**

```bash
# 1. Create first RC
./scripts/bump_version.sh rc
# Version: 0.2.0 → 0.3.0-rc.0

# 2. Update CHANGELOG.md
# Add release notes under [0.3.0-rc.0]

# 3. Commit and tag
git add -A
git commit -m "Release v0.3.0-rc.0"
git tag v0.3.0-rc.0
git push && git push --tags

# 4. Wait for CI, test the RC in production/staging

# 5. If issues found, fix and create RC.1
./scripts/bump_version.sh rc
# Version: 0.3.0-rc.0 → 0.3.0-rc.1
git add -A
git commit -m "Release v0.3.0-rc.1"
git tag v0.3.0-rc.1
git push && git push --tags

# 6. When RC is stable, release
./scripts/bump_version.sh release
# Version: 0.3.0-rc.1 → 0.3.0

# 7. Final commit and tag
git add -A
git commit -m "Release v0.3.0"
git tag v0.3.0
git push && git push --tags
```

## Troubleshooting

### Version mismatch error

If Hex complains about version mismatch:

```bash
# Check mix.exs version matches tag
grep '@version' mix.exs
# Should show: @version "0.2.1"

# Ensure tag matches
git describe --tags
# Should show: v0.2.1
```

### CI fails on publish

Check:

- `HEX_API_KEY` secret is set in GitHub
- Tests pass locally: `mix test`
- Version in `mix.exs` matches the tag

### Want to test publish workflow locally

Use `mix hex.build` to test package building:

```bash
mix hex.build
# Creates gen_server_virtual_time-0.2.0.tar
```

## References

- [Semantic Versioning](https://semver.org/)
- [Hex.pm Publishing Guide](https://hex.pm/docs/publish)
- [Elixir Release Process](https://github.com/elixir-lang/elixir/tags)
- [Keep a Changelog](https://keepachangelog.com/)
