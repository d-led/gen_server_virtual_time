# Publishing Guide

This document describes how to publish `gen_server_virtual_time` to Hex.pm and
HexDocs.pm, including automated workflows and maintenance procedures.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Publishing Process](#publishing-process)
- [Automated Workflows](#automated-workflows)
- [Maintenance Tasks](#maintenance-tasks)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Accounts

1. **Hex.pm Account**
   - Sign up at https://hex.pm/signup
   - Generate an API key: https://hex.pm/settings/keys
   - Store the key securely (you'll need it for GitHub Actions)

2. **GitHub Account**
   - Repository must be hosted on GitHub for automated workflows
   - Admin access required to configure secrets

### Required Tools

- Elixir 1.14+ and OTP 25+
- Git with configured user name and email
- Internet connection for publishing

### Local Environment Setup

1. **Authenticate with Hex:**

   ```bash
   mix hex.user auth
   ```

2. **Install dependencies:**

   ```bash
   mix deps.get
   ```

3. **Verify project builds:**
   ```bash
   mix compile
   mix test
   mix docs
   ```

## Initial Setup

### 1. Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings → Secrets and
variables → Actions):

- `HEX_API_KEY`: Your Hex.pm API key

### 2. Verify mix.exs Configuration

The `mix.exs` file must include proper package metadata:

```elixir
defp package do
  [
    name: "gen_server_virtual_time",
    files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
    maintainers: ["Your Name"],
    licenses: ["MIT"],
    links: %{
      "GitHub" => @source_url,
      "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
    }
  ]
end
```

### 3. Verify Required Files

Ensure these files exist and are up-to-date:

- `README.md` - Project documentation
- `LICENSE` - MIT License
- `CHANGELOG.md` - Version history
- `.formatter.exs` - Code formatting rules

## Publishing Process

### Option 1: Automated Publishing (Recommended)

This is the recommended approach for production releases.

1. **Prepare the release:**

   ```bash
   # Run pre-release checks
   ./scripts/prepare_release.sh
   ```

2. **Bump the version:**

   ```bash
   # For a patch release (0.1.0 → 0.1.1)
   ./scripts/bump_version.sh patch

   # For a minor release (0.1.0 → 0.2.0)
   ./scripts/bump_version.sh minor

   # For a major release (0.1.0 → 1.0.0)
   ./scripts/bump_version.sh major
   ```

   This script will:
   - Update version in `mix.exs`
   - Update `CHANGELOG.md` with the new version and date
   - Update version in `README.md` installation instructions
   - Create a git commit with the version bump
   - Create a git tag (e.g., `v0.1.1`)

3. **Review the changes:**

   ```bash
   git show HEAD
   ```

4. **Update CHANGELOG.md:**

   Edit `CHANGELOG.md` and add release notes under the new version section:

   ```markdown
   ## [0.1.1] - 2025-10-11

   ### Added

   - New feature X
   - New feature Y

   ### Fixed

   - Bug fix A
   - Bug fix B
   ```

5. **Commit CHANGELOG updates (if any):**

   ```bash
   git add CHANGELOG.md
   git commit --amend --no-edit
   ```

6. **Push the changes:**

   ```bash
   git push origin main
   ```

7. **Push the tag:**

   ```bash
   git push origin v0.1.1  # Replace with your version
   ```

8. **Automated Publishing:**

   Once the tag is pushed, GitHub Actions will automatically:
   - Run all tests
   - Build documentation
   - Publish to Hex.pm
   - Publish docs to HexDocs.pm
   - Create a GitHub Release

   Monitor progress at:
   `https://github.com/your-username/gen_server_virtual_time/actions`

### Option 2: Manual Publishing

For testing or emergency releases:

1. **Ensure everything is committed:**

   ```bash
   git status
   ```

2. **Run pre-release checks:**

   ```bash
   ./scripts/prepare_release.sh
   ```

3. **Publish to Hex:**

   ```bash
   mix hex.publish
   ```

4. **Review the package contents:**
   - Check files to be included
   - Verify version number
   - Review description and metadata

5. **Confirm publishing:**
   - Type `y` and press Enter

6. **Create and push git tag:**
   ```bash
   git tag -a v0.1.0 -m "Release version 0.1.0"
   git push origin v0.1.0
   ```

## Automated Workflows

### CI Workflow (`.github/workflows/ci.yml`)

Runs on every push to `main` and on all pull requests (trunk-based development).

**Jobs:**

- **Test**: Runs tests on multiple Elixir/OTP versions
- **Quality**: Runs Credo and Dialyzer for code quality
- **Docs**: Builds documentation to ensure no errors

**Matrix Testing:**

- Latest stable (Elixir 1.18 / OTP 27)
- Minimum supported (Elixir 1.14 / OTP 25)

### Publish Workflow (`.github/workflows/publish.yml`)

Triggers only when a version tag (e.g., `v1.0.0`) is pushed.

**Steps:**

1. Checkout code
2. Setup Elixir environment
3. Install dependencies
4. Run tests (safety check)
5. Build documentation
6. Publish to Hex.pm (automatically publishes docs to HexDocs)
7. Create GitHub Release with changelog

### Caching Strategy

Both workflows use caching to speed up builds:

- Dependencies (`deps/`)
- Build artifacts (`_build/`)
- Dialyzer PLT files (`priv/plts/`)

Cache keys are based on OS, Elixir version, OTP version, and `mix.lock` hash.

## Maintenance Tasks

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.X.0): New features, backward compatible
- **PATCH** (0.0.X): Bug fixes, backward compatible

### Updating Dependencies

1. **Check for updates:**

   ```bash
   mix hex.outdated
   ```

2. **Update dependencies:**

   ```bash
   mix deps.update --all
   ```

3. **Test thoroughly:**

   ```bash
   mix test
   ```

4. **Commit the changes:**
   ```bash
   git add mix.lock
   git commit -m "Update dependencies"
   ```

### Maintaining CHANGELOG.md

Keep `CHANGELOG.md` updated with all notable changes:

1. **Add entries to [Unreleased]:**
   - Document changes as you make them
   - Use categories: Added, Changed, Deprecated, Removed, Fixed, Security

2. **Release checklist:**
   - Move [Unreleased] entries to the new version section
   - Add the release date
   - Update version comparison links at the bottom

### Code Quality Checks

Run these locally before pushing:

```bash
# Format code
mix format

# Check formatting
mix format --check-formatted

# Run tests
mix test

# Run Credo
mix credo --strict

# Run Dialyzer
mix dialyzer

# Generate documentation
mix docs
```

### Common CI Pitfalls and Prevention

To avoid CI failures, be aware of these common issues:

#### 1. Missing Dependencies

**Issue:** Documentation or other tools fail due to missing dependencies.

**Example:**
`CAStore.file_path/0 is undefined (module CAStore is not available)`

**Prevention:**

- Always run `mix docs` locally before pushing
- If you add a dependency, ensure it's properly listed in `mix.exs`
- Check if tools like ExDoc require additional dependencies (e.g., `castore`)

**Fixed by:**

```elixir
# In mix.exs deps/0
{:castore, "~> 1.0", only: :dev, runtime: false}
```

#### 2. Unused Function Parameters

**Issue:** Credo warnings about default parameters that are never used without
the default.

**Example:**
`default values for the optional arguments in function/3 are never used`

**Prevention:**

- Review all function definitions with default parameters
- If all callers provide the argument, remove the default
- Run `mix compile --warnings-as-errors` to catch these early

**Example:**

```elixir
# Bad - default never used
defp my_function(arg1, arg2, arg3 \\ "default") do
  # All callers always provide arg3
end

# Good - no unnecessary default
defp my_function(arg1, arg2, arg3) do
  # ...
end
```

#### 3. Code Complexity Warnings

**Issue:** Credo reports functions exceeding complexity or nesting limits.

**Example:** `Function is too complex (cyclomatic complexity is 17, max is 9)`

**Prevention:**

- Run `mix credo --strict` regularly during development
- Break complex functions into smaller ones when possible
- If complexity is justified, adjust `.credo.exs` thresholds:

```elixir
# In .credo.exs
{Credo.Check.Refactor.CyclomaticComplexity, [max_complexity: 18]},
{Credo.Check.Refactor.Nesting, [max_nesting: 3]}
```

#### 4. Formatting Issues

**Issue:** CI fails on `mix format --check-formatted`

**Prevention:**

- Always run `mix format` before committing
- Set up editor integration for auto-formatting
- Use the pre-commit hook (see below)

#### 5. Alphabetical Ordering

**Issue:** Credo reports aliases not in alphabetical order

**Example:**
`The alias ActorSimulation.Definition is not alphabetically ordered`

**Prevention:**

```elixir
# Bad
alias ActorSimulation.{Definition, Actor, Stats}

# Good
alias ActorSimulation.{Actor, Definition, Stats}
```

#### Quick Pre-Push Checklist

Before pushing to avoid CI failures:

```bash
# Run all CI checks locally
mix format                      # Fix formatting
mix compile --warnings-as-errors # Catch warnings
mix test                        # Run tests
mix credo --strict              # Check code quality
mix docs                        # Build docs
mix dialyzer                    # Type checking (slower)
```

Or use the prepare script:

```bash
./scripts/prepare_release.sh
```

### Pre-commit Hooks (Optional)

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
set -e

echo "Running pre-commit checks..."

# Check formatting
mix format --check-formatted

# Run tests
mix test --trace

echo "✓ All checks passed"
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

## Troubleshooting

### Publishing Fails: "Package name already taken"

The package name is already registered. Either:

1. You need to be added as a maintainer
2. Choose a different package name in `mix.exs`

### Publishing Fails: "Authentication failed"

Check your Hex API key:

```bash
mix hex.user auth
# Or set HEX_API_KEY environment variable
```

### Documentation Not Appearing on HexDocs

1. Documentation is published automatically with `mix hex.publish`
2. Check if docs built successfully: `mix docs`
3. Wait a few minutes for HexDocs to process
4. Check HexDocs build status at https://hexdocs.pm/gen_server_virtual_time

### GitHub Actions Workflow Fails

1. **Check workflow logs:**
   - Go to GitHub repository → Actions
   - Click on the failed workflow
   - Review error messages

2. **Common issues:**
   - `HEX_API_KEY` secret not set
   - Test failures
   - Dependency issues
   - Network problems

3. **Re-run workflow:**
   - Click "Re-run jobs" button
   - Or delete and recreate the tag:
     ```bash
     git tag -d v0.1.0
     git push origin :refs/tags/v0.1.0
     git tag -a v0.1.0 -m "Release version 0.1.0"
     git push origin v0.1.0
     ```

### Version Conflicts

If `mix.exs` version doesn't match the git tag:

1. **Fix the version in mix.exs:**

   ```bash
   # Edit mix.exs manually or use:
   ./scripts/bump_version.sh patch --dry-run  # To see what would change
   ```

2. **Delete the incorrect tag:**

   ```bash
   git tag -d v0.1.0
   git push origin :refs/tags/v0.1.0
   ```

3. **Create the correct tag:**
   ```bash
   git tag -a v0.1.0 -m "Release version 0.1.0"
   git push origin v0.1.0
   ```

### Build Fails on Specific Elixir/OTP Version

1. **Test locally with the failing version:**

   ```bash
   asdf install elixir 1.14.0-otp-25
   asdf local elixir 1.14.0-otp-25
   mix deps.get
   mix test
   ```

2. **Fix compatibility issues**

3. **Update minimum version requirements in mix.exs if needed**

## Best Practices

### Before Each Release

1. ✅ Run `./scripts/prepare_release.sh`
2. ✅ Update CHANGELOG.md with release notes
3. ✅ Review diff: `git diff origin/main`
4. ✅ Check CI is passing on main branch
5. ✅ Verify documentation looks good: `mix docs && open doc/index.html`

### After Each Release

1. ✅ Verify package on Hex.pm: https://hex.pm/packages/gen_server_virtual_time
2. ✅ Verify docs on HexDocs: https://hexdocs.pm/gen_server_virtual_time
3. ✅ Check GitHub Release was created
4. ✅ Test installation in a new project:
   ```bash
   mix new test_project
   cd test_project
   # Add {:gen_server_virtual_time, "~> 0.1"} to mix.exs
   mix deps.get
   ```

### Security Considerations

1. **Never commit secrets:**
   - Keep `HEX_API_KEY` in GitHub Secrets only
   - Don't share API keys in logs or code

2. **Protect main branch:**
   - Enable branch protection rules
   - Require pull request reviews
   - Require CI to pass before merging

3. **Review dependencies regularly:**
   - Check for security advisories: `mix hex.audit`
   - Keep dependencies updated

## Quick Reference

### Version Bump Commands

```bash
# Dry run (see what would change)
./scripts/bump_version.sh patch --dry-run

# Patch: 0.1.0 → 0.1.1
./scripts/bump_version.sh patch

# Minor: 0.1.0 → 0.2.0
./scripts/bump_version.sh minor

# Major: 0.1.0 → 1.0.0
./scripts/bump_version.sh major
```

### One-Line Release

```bash
./scripts/prepare_release.sh && \
./scripts/bump_version.sh patch && \
git push origin main && \
git push origin --tags
```

### Check Package Status

```bash
# View package on Hex.pm
open https://hex.pm/packages/gen_server_virtual_time

# View documentation
open https://hexdocs.pm/gen_server_virtual_time

# Check GitHub Actions
open https://github.com/your-username/gen_server_virtual_time/actions
```

## Additional Resources

- [Hex.pm Publishing Documentation](https://hex.pm/docs/publish)
- [HexDocs Documentation](https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html)
- [ExDoc Documentation](https://hexdocs.pm/ex_doc/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Support

If you encounter issues not covered in this guide:

1. Check existing
   [GitHub Issues](https://github.com/your-username/gen_server_virtual_time/issues)
2. Search [Hex.pm Documentation](https://hex.pm/docs)
3. Ask in [Elixir Forum](https://elixirforum.com/)
4. Create a new issue with details about your problem
