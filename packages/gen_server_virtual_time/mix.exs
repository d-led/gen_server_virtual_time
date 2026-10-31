defmodule GenServerVirtualTime.MixProject do
  use Mix.Project

  @version "1.1.1"
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
      test_coverage: [tool: ExCoveralls, summary: [threshold: 70]],
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
    [extra_applications: [:logger]]
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
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
      {:stream_data, "~> 1.4", only: :test, runtime: false}
    ]
  end

  defp description do
    """
    Virtual time for GenServer and gen_statem: test time-based processes and
    actor systems orders of magnitude faster than in wall-clock time, with a
    clock a test advances itself.
    """
  end

  defp package do
    [
      name: "gen_server_virtual_time",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
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
      source_url_pattern:
        "#{@source_url}/blob/v#{@version}/packages/gen_server_virtual_time/%{path}#L%{line}",
      extras: [
        {"README.md", [title: "Overview"]},
        {"../../CHANGELOG.md", [title: "Changelog"]},
        {"../../CONTRIBUTING.md", [title: "Contributing"]},
        {"LICENSE", [title: "License"]},
        {"docs/virtual_clock_design.md", [title: "VirtualClock Design"]},
        {"docs/local_clock_injection_feature.md", [title: "Local Clock Injection"]}
      ],
      groups_for_extras: [
        Project: [
          "README.md",
          "../../CHANGELOG.md",
          "../../CONTRIBUTING.md",
          "LICENSE"
        ],
        "Virtual Time": [
          "docs/virtual_clock_design.md",
          "docs/local_clock_injection_feature.md"
        ]
      ],
      groups_for_modules: [
        Core: [
          GenServerVirtualTime,
          VirtualClock,
          VirtualTimeGenServer,
          VirtualTimeGenServer.Instrumentation,
          VirtualTimeGenServer.Doctor,
          VirtualTimeGenStateMachine,
          TimeBackend,
          VirtualTimeBackend,
          RealTimeBackend
        ]
      ]
    ]
  end
end
