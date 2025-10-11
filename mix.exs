defmodule GenServerVirtualTime.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/dmitryledentsov/gen_server_virtual_time"

  def project do
    [
      app: :gen_server_virtual_time,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Hex.pm publishing
      description: description(),
      package: package(),

      # Documentation
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      name: "GenServerVirtualTime",

      # Code quality
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_add_apps: [:mix],
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},

      # Code quality (optional, for development)
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Testing (optional, for coverage reports)
      {:excoveralls, "~> 0.18", only: :test, runtime: false}
    ]
  end

  defp description do
    """
    Virtual time scheduler for testing time-dependent GenServer behavior and simulating
    actor systems. Test hours of behavior in seconds with deterministic, fast execution.
    Includes actor simulation DSL with statistics, tracing, and OMNeT++ code generation.
    """
  end

  defp package do
    [
      name: "gen_server_virtual_time",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      maintainers: ["Dmitry Ledentsov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "PUBLISHING.md",
        "CONTRIBUTING.md",
        "OMNETPP_GENERATOR.md"
      ],
      groups_for_modules: [
        "Core": [
          VirtualClock,
          VirtualTimeGenServer,
          TimeBackend,
          VirtualTimeBackend,
          RealTimeBackend
        ],
        "Actor Simulation": [
          ActorSimulation,
          ActorSimulation.Actor,
          ActorSimulation.Definition,
          ActorSimulation.Stats,
          ActorSimulation.OMNeTPPGenerator
        ]
      ]
    ]
  end
end
