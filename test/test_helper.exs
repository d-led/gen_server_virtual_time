# Exclude diagram generation tests by default to avoid generating HTML files
# Run them explicitly with: mix test --include diagram_generation
# Exclude slow tests by default (they can be run with: mix test --include slow)
ExUnit.start(exclude: [:diagram_generation, :slow])

# Configure JUnit formatter for CI
if System.get_env("CI") do
  ExUnit.configure(
    formatters: [JUnitFormatter, ExUnit.CLIFormatter],
    slowest: 10
  )
end
