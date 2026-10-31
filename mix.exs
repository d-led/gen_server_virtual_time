defmodule GenServerVirtualTime.Workspace.MixProject do
  @moduledoc """
  The repository workspace, not a package.

  It exists so that the checked-in `scripts/`, `benchmarks/`, `examples/` and the
  maintainer tooling in `dev/` can run against the three packages with one `mix`
  invocation (and so `mix test` at the root covers the tooling tests). Each
  package in `packages/` is a project of its own: run `mix test` inside it, or
  `./scripts/test.sh` from here for all of them.
  """

  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :gen_server_virtual_time_workspace,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :inets, :ssl, :public_key]]
  end

  # `dev/` holds the maintainer tooling: the precommit gate, the coverage task
  # and `mix templates.upgrade`, which talks to package registries over TLS and
  # regenerates the checked-in examples, so it only makes sense at the root.
  defp elixirc_paths(:test), do: ["dev"]
  defp elixirc_paths(:dev), do: ["dev"]
  defp elixirc_paths(_), do: []

  defp deps do
    [
      {:gen_server_virtual_time, "~> #{@version}", path: "packages/gen_server_virtual_time"},
      {:actor_simulation, "~> #{@version}", path: "packages/actor_simulation"},
      {:actor_simulation_codegen, "~> #{@version}", path: "packages/actor_simulation_codegen"},

      # `mix templates.upgrade` and the scripts it runs
      {:jason, "~> 1.4"},

      # Benchmarks
      {:benchee, "~> 1.5", only: [:dev, :benchmarks], runtime: false},
      {:benchee_html, "~> 1.0", only: [:dev, :benchmarks], runtime: false},

      # Test reporting for the tooling tests
      {:junit_formatter, "~> 3.4", only: :test, runtime: false}
    ]
  end
end
