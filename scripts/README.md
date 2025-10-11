# Helper Scripts

This directory contains scripts for generating and validating OMNeT++ code from the ActorSimulation DSL.

## Scripts

### `generate_omnetpp_examples.exs`

Generates all OMNeT++ example projects.

**Usage:**
```bash
mix run scripts/generate_omnetpp_examples.exs
```

**What it does:**
- Generates 4 complete OMNeT++ projects:
  - `omnetpp_pubsub` - Publish-subscribe system
  - `omnetpp_pipeline` - Message pipeline
  - `omnetpp_burst` - Bursty traffic pattern
  - `omnetpp_loadbalanced` - Load-balanced system
- Creates all necessary files (NED, C++, CMake, etc.)
- Reports generation status and file counts
- Exits with code 0 on success, 1 on failure

**Output:**
```
╔═══════════════════════════════════════════════════════════╗
║  Generating OMNeT++ Example Projects                      ║
╚═══════════════════════════════════════════════════════════╝

📚 Generating: pubsub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Generated 12 files in examples/omnetpp_pubsub/
   - PubSubNetwork.ned (Network topology)
   - 4 C++ source files
   - CMakeLists.txt, conanfile.txt, omnetpp.ini
...
```

### `validate_omnetpp_output.exs`

Validates generated OMNeT++ code for correctness and completeness.

**Usage:**
```bash
mix run scripts/validate_omnetpp_output.exs
```

**What it checks:**
- ✅ Required files exist (NED, CMake, Conan, INI)
- ✅ C++ files have proper structure:
  - Include guards in headers
  - `cSimpleModule` inheritance
  - Required virtual methods
  - `Define_Module` macro in sources
  - All required method implementations
- ✅ NED files have valid syntax:
  - Simple module definitions
  - Network definition
  - Submodules and connections
- ✅ CMakeLists.txt has required commands
- ✅ omnetpp.ini has proper configuration
- ✅ No timestamps in generated code (for clean version control)

**Output:**
```
╔═══════════════════════════════════════════════════════════╗
║  Validating OMNeT++ Generated Code                        ║
╚═══════════════════════════════════════════════════════════╝

📋 Validating: omnetpp_pubsub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Found: NED topology file
✅ Found: CMake configuration
✅ C++ headers: 4
✅ C++ sources: 4
✅ NED file structure valid
✅ CMakeLists.txt valid
✅ omnetpp.ini valid
✅ No timestamps found (good for version control)
✅ omnetpp_pubsub: All checks passed
...
```

## CI Integration

These scripts are used in GitHub Actions to validate OMNeT++ code generation:

### Workflow: `omnetpp_generation.yml`

**Triggers:**
- Push to `main` branch (trunk-based development)
- Pull requests to `main`
- Changes to actor simulation code or generation scripts

**Jobs:**

1. **test-generation** - Generates and validates code
   - Tests on multiple Elixir (1.17, 1.18) and OTP (26, 27) versions
   - Runs generation script
   - Validates output
   - Checks for timestamps
   - Validates C++ and NED syntax
   - Uploads artifacts

2. **verify-consistency** - Ensures consistency
   - Compares generated code across different versions
   - Verifies identical output regardless of Elixir/OTP version

**Validation Checks:**

```yaml
- File count verification
- C++ syntax validation
- NED structure validation
- CMake configuration check
- Timestamp detection
- Memory management verification
```

## Local Development

### Generate Examples

```bash
# Generate all examples
mix run scripts/generate_omnetpp_examples.exs

# View generated files
ls -la examples/omnetpp_pubsub/
```

### Validate Output

```bash
# Validate all generated projects
mix run scripts/validate_omnetpp_output.exs

# Validate specific project
cd examples/omnetpp_pubsub
cat CMakeLists.txt
cat PubSubNetwork.ned
```

### Run Both

```bash
# Generate and validate in one go
mix run scripts/generate_omnetpp_examples.exs && \
mix run scripts/validate_omnetpp_output.exs
```

## Exit Codes

Both scripts use exit codes for CI integration:

- **0** - Success, all checks passed
- **1** - Failure, errors found

This allows them to be used in CI pipelines:

```bash
if mix run scripts/generate_omnetpp_examples.exs; then
  echo "Generation successful"
else
  echo "Generation failed"
  exit 1
fi
```

## Extending

### Adding New Examples

Edit `generate_omnetpp_examples.exs`:

```elixir
defp create_new_example_simulation do
  ActorSimulation.new()
  |> ActorSimulation.add_actor(:actor1, ...)
  |> ActorSimulation.add_actor(:actor2, ...)
end
```

Add to the examples list:

```elixir
examples = [
  # ... existing examples ...
  {:new_example, &create_new_example_simulation/0, "NewExampleNetwork", 10}
]
```

### Adding New Validations

Edit `validate_omnetpp_output.exs` and add checks in the `validate_project/1` function:

```elixir
# Custom validation
if custom_check(content) do
  IO.puts "✅ Custom check passed"
else
  IO.puts "❌ Custom check failed"
  errors = errors ++ ["Custom check failed"]
end
```

## Troubleshooting

### Generation Fails

```bash
# Check if ActorSimulation.OMNeTPPGenerator module exists
mix run -e "IO.inspect(ActorSimulation.OMNeTPPGenerator.module_info())"

# Recompile
mix clean && mix compile
```

### Validation Fails

```bash
# Check generated files exist
ls examples/omnetpp_pubsub/

# View validation errors in detail
mix run scripts/validate_omnetpp_output.exs 2>&1 | tee validation.log
```

### CI Failures

Check the GitHub Actions logs:
1. Go to repository → Actions tab
2. Click on the failed workflow run
3. Expand the failed step
4. Download artifacts for detailed analysis

## Best Practices

1. **Run both scripts** before committing changes to the generator
2. **Check exit codes** in scripts and CI
3. **Review artifacts** when CI fails
4. **Keep scripts fast** - they run on every push
5. **Update validations** when adding new generator features

## Related Documentation

- [OMNETPP_GENERATOR.md](../OMNETPP_GENERATOR.md) - Generator technical documentation
- [OMNETPP_COMPLETE.md](../OMNETPP_COMPLETE.md) - Implementation summary
- [README.md](../README.md) - Main project documentation
- [examples/omnetpp_demo.exs](../examples/omnetpp_demo.exs) - Interactive demo script

