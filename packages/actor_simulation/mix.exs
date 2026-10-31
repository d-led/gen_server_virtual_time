defmodule ActorSimulation.MixProject do
  use Mix.Project

  @version "1.0.1"
  @source_url "https://github.com/d-led/gen_server_virtual_time"

  def project do
    [
      app: :actor_simulation,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex.pm publishing
      description: description(),
      package: package(),

      # Documentation
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      name: "ActorSimulation",

      # Code quality and test reporting
      test_coverage: [tool: ExCoveralls, summary: [threshold: 70]],
      test_paths: ["test"],
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # The clock this simulation runs on
      sibling_dep(:gen_server_virtual_time, "~> #{@version}"),

      # Test reporting
      {:junit_formatter, "~> 3.4", only: :test, runtime: false},

      # Documentation
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},

      # Code quality
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Coverage
      {:excoveralls, "~> 0.18", only: :test, runtime: false},

      # Property-based testing
      {:stream_data, "~> 1.4", only: :test, runtime: false}
    ]
  end

  # Inside this repository the sibling package is right there and wins; in a
  # consumer's deps/ tree it is not, so the version requirement resolves from
  # Hex. Packaging runs with HEX_PUBLISH=1 and gets a spec without the :path
  # option at all — Hex refuses to build a package whose dependency is not a Hex
  # package, and it counts a `path: nil` as one.
  defp sibling_dep(app, requirement) do
    path = Path.expand("../#{app}", __DIR__)

    if System.get_env("HEX_PUBLISH") != "1" and File.dir?(Path.join(path, "lib")),
      do: {app, requirement, path: path},
      else: {app, requirement}
  end

  defp description do
    """
    A DSL for simulating actor systems in virtual time: send patterns,
    declarative handlers, statistics, sequence diagrams and flowchart reports,
    driven by gen_server_virtual_time's clock so a simulated hour takes
    milliseconds.
    """
  end

  defp package do
    [
      name: "actor_simulation",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE docs),
      maintainers: ["Dmitry Ledentsov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Clock and OTP wrappers" => "https://hexdocs.pm/gen_server_virtual_time"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      source_url_pattern:
        "#{@source_url}/blob/v#{@version}/packages/actor_simulation/%{path}#L%{line}",
      extras: [
        {"README.md", [title: "Overview"]},
        {"../../CHANGELOG.md", [title: "Changelog"]},
        {"LICENSE", [title: "License"]},
        {"docs/flowchart_reports.md", [title: "Flowchart Reports"]}
      ],
      groups_for_extras: [
        Project: ["README.md", "../../CHANGELOG.md", "LICENSE"],
        Reports: ["docs/flowchart_reports.md"]
      ]
    ]
  end
end
