# Exclude diagram generation tests by default to avoid generating HTML files
# Run them explicitly with: mix test --include diagram_generation
ExUnit.start(exclude: [:diagram_generation])

# Configure JUnit formatter for CI
if System.get_env("CI") do
  ExUnit.configure(
    formatters: [JUnitFormatter, ExUnit.CLIFormatter],
    slowest: 10
  )
end
