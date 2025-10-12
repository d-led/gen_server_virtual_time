# Trunk-Based Development Workflow

This project uses **trunk-based development** - a streamlined approach perfect
for libraries.

## Why Trunk-Based Development?

✅ **Simple** - Single main branch, no complex branching  
✅ **Fast** - Quick merge to main, immediate CI feedback  
✅ **Safe** - Comprehensive CI validation before merge  
✅ **XP-aligned** - Continuous integration, small changes  
✅ **Library-friendly** - Tag-based releases, semantic versioning

## Workflow

### 1. Development

```bash
# Start from main
git checkout main
git pull origin main

# Create feature branch (short-lived)
git checkout -b add-feature-x

# Make small, focused changes
git add .
git commit -m "Add feature X"

# Push for PR
git push origin add-feature-x
```

### 2. Pull Request

- Create PR to `main`
- CI runs automatically:
  - ✅ All tests (63 tests)
  - ✅ Linter checks
  - ✅ Coverage report
  - ✅ OMNeT++ generation validation
  - ✅ Documentation builds
- Address any CI failures
- Merge when green

### 3. Release

```bash
# After merge to main, create release tag
git checkout main
git pull origin main

# Tag release (semantic versioning)
git tag -a v0.2.0 -m "Release 0.2.0: Add feature X"
git push origin v0.2.0

# CI automatically:
# - Runs full test suite
# - Publishes to Hex.pm
# - Updates documentation
# - Creates GitHub release
```

## Branch Strategy

| Branch       | Purpose               | Lifetime      |
| ------------ | --------------------- | ------------- |
| `main`       | Production-ready code | Permanent     |
| `feature/*`  | New features          | Hours to days |
| `fix/*`      | Bug fixes             | Hours         |
| `refactor/*` | Code improvements     | Hours to days |

**No develop branch!** All work merges directly to main after CI validation.

## CI Protection

Main branch is protected by:

1. **Required CI checks**
   - All tests must pass
   - No linter warnings
   - Coverage maintained
   - OMNeT++ validation passes

2. **Pull request required**
   - No direct pushes to main
   - Code review recommended
   - CI must be green

3. **Small, frequent merges**
   - Feature branches live hours/days, not weeks
   - Merge often to avoid conflicts
   - Rebase on main frequently

## Release Process

### Semantic Versioning

- **v0.x.y** - Pre-1.0 development
- **v1.0.0** - First stable release
- **v1.1.0** - New features (minor)
- **v1.1.1** - Bug fixes (patch)
- **v2.0.0** - Breaking changes (major)

### Tagging

```bash
# Development releases
git tag v0.2.0-alpha.1
git tag v0.2.0-beta.1
git tag v0.2.0-rc.1

# Stable releases
git tag v0.2.0
git tag v1.0.0
```

### Hex.pm Publishing

Triggered automatically on tag push:

```bash
# Create and push tag
git tag v0.2.0 -m "Release 0.2.0"
git push origin v0.2.0

# CI runs:
# 1. Full test suite
# 2. mix hex.publish (if tests pass)
# 3. Documentation update
# 4. GitHub release creation
```

## Best Practices

### ✅ Do

- Keep feature branches short-lived (< 3 days)
- Merge to main frequently
- Use descriptive commit messages
- Run tests locally before pushing
- Rebase on main to stay current
- Create small, focused PRs
- Tag releases with semantic versions

### ❌ Don't

- Create long-lived feature branches
- Hold PRs for "batch" merging
- Push directly to main
- Merge without CI passing
- Create intermediate branches (no develop/staging)
- Skip tests or linter checks

## Example Workflows

### Adding a Feature

```bash
# 1. Start from main
git checkout main && git pull

# 2. Create feature branch
git checkout -b add-omnetpp-channels

# 3. Develop (with tests!)
# ... write code ...
mix test

# 4. Commit often
git add .
git commit -m "Add channel delay support"

# 5. Push and create PR
git push origin add-omnetpp-channels
# Create PR on GitHub

# 6. After CI passes and review, merge
# PR merges to main

# 7. Clean up
git checkout main
git pull
git branch -d add-omnetpp-channels
```

### Fixing a Bug

```bash
# 1. Create fix branch
git checkout -b fix-memory-leak

# 2. Fix and test
# ... fix code ...
mix test

# 3. Quick merge
git push origin fix-memory-leak
# Create PR, merge when green

# 4. If urgent, can merge immediately when CI passes
```

### Releasing

```bash
# 1. Ensure main is stable
git checkout main
git pull
mix test --cover

# 2. Update version in mix.exs
# Edit mix.exs: version: "0.2.0"
git add mix.exs
git commit -m "Bump version to 0.2.0"
git push origin main

# 3. Tag and push
git tag v0.2.0 -m "Release 0.2.0: OMNeT++ generator"
git push origin v0.2.0

# 4. CI automatically publishes to Hex.pm
# Monitor: https://github.com/yourrepo/actions
```

## CI Feedback Loop

```
Write Code → Commit → Push → CI Runs → Get Feedback
     ↑                                         ↓
     └──────────── Fix Issues ←────────────────┘
```

**Average CI time:** 2-3 minutes  
**Typical PR lifetime:** 2-24 hours  
**Main always deployable:** Yes

## Why This Works for Libraries

### Libraries vs Applications

**Applications** might use:

- develop branch
- staging environments
- release branches
- longer QA cycles

**Libraries** benefit from:

- ✅ Single source of truth (main)
- ✅ Tag-based releases
- ✅ Semantic versioning
- ✅ Fast iteration
- ✅ Clear release history

### Consumer Confidence

Users can:

- Trust main branch (always CI-validated)
- Use specific tags (v0.2.0)
- Track changes via git tags
- See release notes on GitHub
- Install from Hex.pm with confidence

## Automation

All automated via GitHub Actions:

```yaml
# On push to main
- Run full test suite
- Check linter
- Generate coverage
- Validate OMNeT++ generation
- Build documentation

# On tag push (v*)
- Run full test suite
- Publish to Hex.pm
- Deploy documentation
- Create GitHub release
- Notify package managers
```

## Migration from Branch-Based

If you were using develop:

```bash
# 1. Merge develop to main
git checkout main
git merge develop
git push origin main

# 2. Delete develop branch
git branch -d develop
git push origin --delete develop

# 3. Update CI workflows (already done!)
# 4. Update documentation (already done!)

# 5. Inform team
# "We're now using trunk-based development"
```

## References

- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- [Google's Development Philosophy](https://abseil.io/resources/swe-book/html/ch16.html)
- [Facebook's Development Model](https://engineering.fb.com/2017/08/31/web/rapid-release-at-massive-scale/)
- [Semantic Versioning](https://semver.org/)
- [Continuous Delivery](https://continuousdelivery.com/)

## Summary

**Trunk-based development** is perfect for this library because:

1. ✅ Single main branch - simple and clear
2. ✅ Tag-based releases - semantic versioning
3. ✅ Fast feedback - CI on every push
4. ✅ Small changes - easy to review
5. ✅ Always deployable - main is stable
6. ✅ XP-aligned - continuous integration

**No develop branch needed!** Just main + short-lived feature branches + tags
for releases.
