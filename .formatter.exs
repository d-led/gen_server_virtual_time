# Used by "mix format"
[
  # test/fixtures holds deliberately malformed input, so test/ is listed by
  # extension rather than by directory.
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,dev}/**/*.{ex,exs}",
    "test/**/*.exs",
    "test/support/**/*.ex"
  ]
]
