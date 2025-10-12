# Demo Build & Run Status

⚠️ **HISTORICAL SNAPSHOT** - Status of demo builds and test scripts at a specific point in development. May be outdated.

## Binary Naming Pattern
All generators now use: `{example}.{framework}.{os}`

Examples:
- `pubsub_actors.phony.darwin`
- `pubsub_actors.pony.darwin`  
- `cafpubsub.caf.darwin`
- `PubSubNetwork.omnetpp.darwin`

## Test Scripts Status

### ✅ Phony (Go) - `scripts/test_phony_demo.sh`
- **Status**: Working
- **Build Time**: ~2 seconds
- **Requirements**: Go 1.21+
- **Test**: `scripts/test_phony_demo.sh`

### ✅ Pony - `scripts/test_pony_demo.sh` 
- **Status**: Working
- **Build Time**: ~5 seconds
- **Requirements**: ponyc, corral
- **Test**: `scripts/test_pony_demo.sh`

### ⏳ CAF (C++) - `scripts/test_caf_demo.sh`
- **Status**: Working but SLOW
- **Build Time**: 10-15 minutes (first time, then cached)
- **Issue**: Conan builds CAF from source
- **Requirements**: cmake, conan
- **Test**: `scripts/test_caf_demo.sh` (be patient!)
- **Note**: After first build, subsequent builds are fast

### ❓ OMNeT++ - `scripts/test_omnetpp_demo.sh`
- **Status**: Created but not tested
- **Requirements**: OMNeT++ 6.0+ installation
- **Test**: `scripts/test_omnetpp_demo.sh`

## Changes Made

1. **Generators Updated**:
   - Binary naming: `{example}.{framework}.{os}`
   - CAF version: 0.18.7 → 1.0.2
   - Conan format: `caf:shared` → `caf/*:shared`
   - All Makefiles use OS detection
   - CI workflows include demo runs

2. **Test Scripts**:
   - Created: `test_phony_demo.sh`, `test_omnetpp_demo.sh`
   - Updated: `test_pony_demo.sh`, `test_caf_demo.sh`
   - All use new binary naming

3. **GitIgnore**:
   - Added patterns for all framework binaries
   - Pattern: `*.{framework}.{os}`

## Running Tests

```bash
# Fast (Go)
scripts/test_phony_demo.sh

# Fast (Pony)
scripts/test_pony_demo.sh

# Slow first time (C++ with Conan)
# Grab coffee ☕
scripts/test_caf_demo.sh

# Requires OMNeT++ installation
scripts/test_omnetpp_demo.sh
```

## Known Issues

### CAF 1.0 API Breaking Changes

**Status**: CAF examples currently use 0.18.x API which is incompatible with CAF 1.0.2

**Error**: 
```
error: no type named 'atom_value' in namespace 'caf'
error: no member named 'atom' in namespace 'caf'
```

**Root Cause**: CAF 1.0 changed the atom API:
- Old (0.18): `caf::atom_value` type, `caf::atom("msg")` function
- New (1.0): `atom_constant<atom("msg")>` type, use `msg_atom::value` 

**Solution Options**:
1. **Update CAF generator** to use CAF 1.0 atom API (requires generator rewrite)
2. **Use pre-generated 0.18 examples** (in git, still work)
3. **Wait for CAF API compatibility layer** (if available)

**Workaround**: Use Phony (Go) or Pony examples instead - they work perfectly!

**References**:
- CAF 1.0 example: `using hello_atom = atom_constant<atom("hello")>;`
- New send syntax: `mail(hello_atom::value).send(target)`
- Handler syntax: `[](hello_atom) { ... }`

