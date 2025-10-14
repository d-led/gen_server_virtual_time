defmodule GenServerVirtualTime.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/d-led/gen_server_virtual_time"

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

      # Code quality and test reporting
      test_coverage: [
        tool: ExCoveralls,
        summary: [threshold: 70]
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        muzak: :test,
        "exavier.test": :test
      ],

      # Test reporting (JUnit XML for CI)
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Test reporting
      {:junit_formatter, "~> 3.3", only: :test, runtime: false},

      # Documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:castore, "~> 1.0", only: :dev, runtime: false},

      # Code quality (optional, for development)
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Testing (optional, for coverage reports)
      {:excoveralls, "~> 0.18", only: :test, runtime: false},

      # Mutation testing
      {:muzak, "~> 1.1", only: :test, runtime: false},
      {:exavier, "~> 0.3.0", only: :test, runtime: false}
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
        {"README.md", [title: "Overview"]},
        {"CHANGELOG.md", [title: "Changelog"]},
        {"CONTRIBUTING.md", [title: "Contributing"]},
        {"LICENSE", [title: "License"]},
        {"docs/generators.md", [title: "Code Generators Overview"]},
        {"docs/omnetpp_generator.md", [title: "OMNeT++ Generator"]},
        {"docs/caf_generator.md", [title: "CAF Generator"]},
        {"docs/pony_generator.md", [title: "Pony Generator"]},
        {"docs/phony_generator.md", [title: "Phony (Go) Generator"]},
        {"docs/vlingo_generator.md", [title: "VLINGO XOOM Generator"]}
      ],
      groups_for_extras: [
        Project: [
          "README.md",
          "CHANGELOG.md",
          "CONTRIBUTING.md",
          "LICENSE"
        ],
        "Code Generators": [
          "docs/generators.md",
          "docs/omnetpp_generator.md",
          "docs/caf_generator.md",
          "docs/pony_generator.md",
          "docs/phony_generator.md",
          "docs/vlingo_generator.md"
        ]
      ],
      groups_for_modules: [
        Core: [
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
          ActorSimulation.MermaidReportGenerator
        ],
        "Code Generators": [
          ActorSimulation.GeneratorUtils,
          ActorSimulation.OMNeTPPGenerator,
          ActorSimulation.CAFGenerator,
          ActorSimulation.PonyGenerator,
          ActorSimulation.PhonyGenerator,
          ActorSimulation.VlingoGenerator
        ]
      ]
    ]
  end
end
