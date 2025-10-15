# Pipeline Fixes - Summary

## Issues Identified from GitHub Actions

### 1. ❌ Documentation Build Failure

**Error**:
`warning: documentation references file "docs/ractor_generator.md" but it does not exist`

**Root Cause**: File exists in git, but not listed in ExDoc configuration in
`mix.exs`

**Fix**: Added `docs/ractor_generator.md` to:

- `extras:` list in mix.exs
- `"Code Generators"` group in mix.exs

**Verification**:

```bash
$ mix docs
View "html" docs at "doc/index.html"
View "epub" docs at "doc/GenServerVirtualTime.epub"
✅ NO WARNINGS
```

### 2. ❌ Coverage Export Failure

**Error**: `FAILED: Expected minimum coverage of 70%, got 7.8%` (slow tests
export)

**Root Cause**: Individual test suite exports (fast/slow/diagram) have low
coverage when run in isolation. Only the combined coverage should be checked
against the 70% threshold.

**Fix**: Added `--no-fail-on-minimum` flag to coverage export steps in
`.github/workflows/ci.yml`:

- `mix coveralls --export-coverage fast --no-fail-on-minimum`
- `mix coveralls --only slow --export-coverage slow --no-fail-on-minimum`
- `mix coveralls --only diagram_generation --export-coverage diagram --no-fail-on-minimum`

**Note**: The merge step (`mix coveralls.github --import-cover cover`) will
still enforce the 70% threshold on combined coverage.

### 3. ❌ Credo Warning

**Error**: `Function body is nested too deep (max depth is 3, was 4)` in
`lib/mix/tasks/precommit.ex`

**Root Cause**: Duplicated nested if/case logic in coverage reporting

**Fix**: Extracted functions:

- `print_coverage_summary/0` - prints coverage percentage
- `print_coverage_with_file_link/0` - prints coverage with file link

**Verification**:

```bash
$ mix credo --strict
607 mods/funs, found no issues.
✅ CLEAN
```

### 4. ❌ Dialyzer Warning

**Error**: `The pattern variable _ can never match the type` in coverage check

**Fix**: Removed unreachable pattern match clause

**Verification**:

```bash
$ mix dialyzer
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
done (passed successfully)
✅ CLEAN
```

## Files Changed

1. `.github/workflows/ci.yml` - Added `--no-fail-on-minimum` to coverage exports
2. `mix.exs` - Added ractor_generator.md to ExDoc extras
3. `lib/mix/tasks/precommit.ex` - Extracted nested functions, removed
   unreachable pattern

## Local Verification

```bash
✅ mix compile --warnings-as-errors: PASS
✅ mix test: 337/337 PASS
✅ mix credo --strict: 0 issues
✅ mix dialyzer: 0 warnings
✅ mix docs: 0 warnings
✅ cargo test (all 4 Rust examples): 20/20 PASS
```

## Expected CI Results After Fix

- ✅ Fast tests export: Won't fail on partial coverage
- ✅ Slow tests export: Won't fail on 7.8% coverage
- ✅ Diagram tests export: Won't fail on partial coverage
- ✅ Merge coverage: Will report combined ~72% coverage ✅
- ✅ Documentation build: Will succeed with no warnings
- ✅ Credo: Will pass with 0 issues
- ✅ Dialyzer: Will pass with 0 warnings

---

**Status**: Ready to commit and push ✅ **All pipelines should turn GREEN** 🟢
