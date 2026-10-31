# The root project is the repository workspace: its tests cover the maintainer
# tooling in `dev/` (the template-version upgrade planner). The packages in
# `packages/` have their own suites — run `./scripts/test.sh` for all of them.
ExUnit.start()

if System.get_env("CI") do
  ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter], slowest: 10)
end
