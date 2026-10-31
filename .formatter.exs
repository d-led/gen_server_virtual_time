# Used by "mix format" at the repository root: it formats the maintainer tooling
# and the tooling tests here, and every package's own sources.
[
  inputs: [
    "{mix,.formatter}.exs",
    "dev/**/*.ex",
    "test/**/*.{ex,exs}",
    "packages/*/mix.exs",
    "packages/*/{lib,dev}/**/*.{ex,exs}",
    "packages/*/test/**/*.exs",
    "packages/*/test/support/**/*.ex"
  ]
]
