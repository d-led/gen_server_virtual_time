defmodule GenServerVirtualTime.MixProject do
  use Mix.Project

  @version "0.6.1"
  @source_url "https://github.com/d-led/gen_server_virtual_time"

  def project do
    [
      app: :gen_server_virtual_time,
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
      name: "GenServerVirtualTime",

      # Code quality and test reporting
      test_coverage: [
        tool: ExCoveralls,
        summary: [threshold: 70],
        ignore_modules: [Mix.Tasks.Precommit, DiningPhilosophers]
      ],
      # Test reporting (JUnit XML for CI)
      test_paths: ["test"],
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_add_apps: [:mix, :jason, :inets, :ssl, :public_key],
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger] ++ tooling_applications()]
  end

  # `mix templates.upgrade` (see dev/) asks package registries for the latest
  # releases with :httpc over TLS, which needs :inets, :ssl and :public_key on the
  # code path. Only maintainer environments declare them, and only `dev/` uses
  # them, so the published library — built with MIX_ENV=prod — depends on :logger
  # alone.
  defp tooling_applications do
    if Mix.env() == :prod, do: [], else: [:inets, :ssl, :public_key]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        muex: :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "dev"]
  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Test reporting
      {:junit_formatter, "~> 3.4", only: :test, runtime: false},

      # Documentation
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:castore, "~> 1.0", only: :dev, runtime: false},

      # Code quality (optional, for development)
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Testing (optional, for coverage reports)
      {:excoveralls, "~> 0.18", only: :test, runtime: false},

      # Property-based testing
      {:stream_data, "~> 1.4", only: :test, runtime: false},

      # Mutation testing
      {:muex, "~> 0.11", only: [:dev, :test], runtime: false},

      # JSON for `mix templates.upgrade` and the generator tests
      {:jason, "~> 1.4", only: [:dev, :test], runtime: false},

      # Benchmarking
      {:benchee, "~> 1.5", only: :dev, runtime: false},
      {:benchee_html, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Virtual time extension to GenServer and GenStateMachine allowing testing time-based
    actor systems orders of magnitude faster than in wallclock-time.
    Includes actor simulation DSL with statistics, tracing, and code generation into other
    Actor Model implementations in C++, Pony, Go, Rust, Java.
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
      # Maintainer tooling lives in dev/ and is not shipped, so it is not published
      filter_modules: ~r/^(?!Mix\.Tasks\.Templates|ActorSimulation\.TemplateVersions\.Upgrade)/,
      extras: [
        {"README.md", [title: "Overview"]},
        {"docs/index.md", [title: "Documentation Index"]},
        {"CHANGELOG.md", [title: "Changelog"]},
        {"CONTRIBUTING.md", [title: "Contributing"]},
        {"LICENSE", [title: "License"]},
        {"docs/virtual_clock_design.md", [title: "VirtualClock Design"]},
        {"docs/local_clock_injection_feature.md", [title: "Local Clock Injection"]},
        {"docs/flowchart_reports.md", [title: "Flowchart Reports"]},
        {"docs/generators.md", [title: "Code Generators Overview"]},
        {"docs/omnetpp_generator.md", [title: "OMNeT++ Generator"]},
        {"docs/caf_generator.md", [title: "CAF Generator"]},
        {"docs/pony_generator.md", [title: "Pony Generator"]},
        {"docs/phony_generator.md", [title: "Phony (Go) Generator"]},
        {"docs/ractor_generator.md", [title: "Ractor (Rust) Generator"]},
        {"docs/vlingo_generator.md", [title: "VLINGO XOOM Generator"]}
      ],
      groups_for_extras: [
        Project: [
          "README.md",
          "docs/index.md",
          "CHANGELOG.md",
          "CONTRIBUTING.md",
          "LICENSE"
        ],
        "Virtual Time": [
          "docs/virtual_clock_design.md",
          "docs/local_clock_injection_feature.md",
          "docs/flowchart_reports.md"
        ],
        "Code Generators": [
          "docs/generators.md",
          "docs/omnetpp_generator.md",
          "docs/caf_generator.md",
          "docs/pony_generator.md",
          "docs/phony_generator.md",
          "docs/ractor_generator.md",
          "docs/vlingo_generator.md"
        ]
      ],
      groups_for_modules: [
        Core: [
          GenServerVirtualTime,
          VirtualClock,
          VirtualTimeGenServer,
          VirtualTimeGenStateMachine,
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
          ActorSimulation.TemplateVersions,
          ActorSimulation.GeneratorUtils,
          ActorSimulation.OMNeTPPGenerator,
          ActorSimulation.CAFGenerator,
          ActorSimulation.PonyGenerator,
          ActorSimulation.PhonyGenerator,
          ActorSimulation.RactorGenerator,
          ActorSimulation.VlingoGenerator
        ]
      ]
    ]
  end
end
