ExUnit.start()

# Configure JUnit formatter for CI
if System.get_env("CI") do
  ExUnit.configure(
    formatters: [JUnitFormatter, ExUnit.CLIFormatter],
    slowest: 10
  )
end
