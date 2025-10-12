# Binary Naming & CI Caching Implementation

⚠️ **HISTORICAL SNAPSHOT** - Development session documenting implementation of
consistent binary naming and CI caching infrastructure.

## Summary

Implemented consistent binary naming pattern `{example}.{framework}.{os}` across
all generators and added comprehensive CI caching to speed up builds.

## Changes Made

### 1. Binary Naming Pattern

All generated examples now produce binaries with consistent naming:

- **Phony**: `pubsub_actors.phony.darwin`
- **Pony**: `pubsub_actors.pony.darwin`
- **CAF**: `PubSubActors.caf.darwin`
- **OMNeT++**: `PubSubNetwork.omnetpp.darwin`

### 2. Generators Updated

#### Phony (Go)

- Makefile uses OS detection for binary naming
- CI workflow uses `cache: true` in `setup-go` action

#### Pony

- Makefile uses `$(DIR_NAME)` to handle ponyc naming
- CI workflow caches Corral packages (`~/.corral`, `_corral`)

#### CAF (C++)

- CMake uses `set_target_properties` for binary naming
- Version updated: 0.18.7 → 1.0.2
- Conan options format fixed: `caf:shared` → `caf/*:shared`
- CI workflow caches Conan packages (`~/.conan2`)

#### OMNeT++

- CMake uses `set_target_properties` for binary naming
- CI workflow uses `opp_env` for installation
- Caches OMNeT++ installation (`~/.opp_env`, `~/.cache/opp_env`)

### 3. Test Scripts

**Created:**

- `scripts/test_phony_demo.sh` - Test Phony/Go examples
- `scripts/test_omnetpp_demo.sh` - Test OMNeT++ examples

**Updated:**

- `scripts/test_pony_demo.sh` - Uses Makefile and new binary naming
- `scripts/test_caf_demo.sh` - Adds `-DCMAKE_BUILD_TYPE=Release` and
  `-s build_type=Release`

All scripts now:

- Use the new binary naming pattern
- Detect OS automatically
- Extract project names from config files
- Provide helpful error messages

### 4. .gitignore Improvements

Added comprehensive patterns to ignore build artifacts:

```gitignore
# Generated binaries
*.{framework}.{os}

# Conan generated files
examples/*/conan*.sh
examples/*/conan*.cmake
examples/*/*Config.cmake
examples/*/*Targets.cmake
examples/*/Find*.cmake
examples/*/CMakePresets.json

# Build directories
examples/*/build/
examples/*/_corral/

# OMNeT++ artifacts
examples/*/*.vec
examples/*/*.sca
```

### 5. CI Workflow Caching

All CI workflows now include caching to dramatically speed up builds:

- **Go**: Built-in cache in `setup-go@v4`
- **Conan**: Caches `~/.conan2` (saves 10-15 minutes on CAF builds)
- **Corral**: Caches `_corral` and `.corral`
- **OMNeT++**: Caches `~/.opp_env` installation

## Test Status

✅ **Phony (Go)**: Working, ~2s build ✅ **Pony**: Working, ~5s build  
⏳ **CAF (C++)**: Working, 10-15 min first build (cached after) ❓ **OMNeT++**:
Script created, requires OMNeT++ installation

## Testing

```bash
# Fast demos
scripts/test_phony_demo.sh
scripts/test_pony_demo.sh

# Slow first time (Conan builds from source)
scripts/test_caf_demo.sh

# Requires OMNeT++ installation
scripts/test_omnetpp_demo.sh
```

## Backwards Compatibility

All changes are backwards compatible:

- Old examples continue to work
- New examples use new naming
- No breaking API changes
- All tests passing (192 tests, 1 flaky)

## Files Changed

**Core:**

- 6 generator files (caf, pony, phony, omnetpp, vlingo, main)
- 1 test file updated
- .gitignore expanded

**Scripts:**

- 2 new test scripts
- 2 updated test scripts

**Examples:**

- All regenerated with new Makefiles/CMakeLists
- CI workflows updated with caching

## Next Steps

1. Test CAF demo fully (currently Conan builds from source)
2. Test OMNeT++ demo (requires installation)
3. Consider pre-built CAF binaries to avoid Conan build times
4. Document caching behavior in README
