defmodule ActorSimulationCodegen.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/d-led/gen_server_virtual_time"

  def project do
    [
      app: :actor_simulation_codegen,
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
      name: "ActorSimulationCodegen",

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
      # The simulation DSL these generators read
      {:actor_simulation, "~> #{@version}", path: sibling(:actor_simulation)},

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
  # Hex. Hex refuses to build a package that depends on a non-Hex dependency, so
  # packaging runs with HEX_PUBLISH=1 and sees the requirement alone.
  defp sibling(app) do
    path = Path.expand("../#{app}", __DIR__)

    if System.get_env("HEX_PUBLISH") != "1" and File.dir?(Path.join(path, "lib")),
      do: path,
      else: nil
  end

  defp description do
    """
    Generates runnable actor systems from an actor_simulation model: C++ (CAF,
    OMNeT++), Go (Phony), Pony, Rust (Ractor) and Java (VLINGO XOOM) projects
    with build files, CI and tests.
    """
  end

  defp package do
    [
      name: "actor_simulation_codegen",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE docs),
      maintainers: ["Dmitry Ledentsov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Simulation DSL" => "https://hexdocs.pm/actor_simulation"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      source_url_pattern:
        "#{@source_url}/blob/v#{@version}/packages/actor_simulation_codegen/%{path}#L%{line}",
      extras: [
        {"README.md", [title: "Overview"]},
        {"../../CHANGELOG.md", [title: "Changelog"]},
        {"LICENSE", [title: "License"]},
        {"docs/generators.md", [title: "Code Generators Overview"]},
        {"docs/omnetpp_generator.md", [title: "OMNeT++ Generator"]},
        {"docs/caf_generator.md", [title: "CAF Generator"]},
        {"docs/pony_generator.md", [title: "Pony Generator"]},
        {"docs/phony_generator.md", [title: "Phony (Go) Generator"]},
        {"docs/ractor_generator.md", [title: "Ractor (Rust) Generator"]},
        {"docs/vlingo_generator.md", [title: "VLINGO XOOM Generator"]}
      ],
      groups_for_extras: [
        Project: ["README.md", "../../CHANGELOG.md", "LICENSE"],
        Generators: [
          "docs/generators.md",
          "docs/omnetpp_generator.md",
          "docs/caf_generator.md",
          "docs/pony_generator.md",
          "docs/phony_generator.md",
          "docs/ractor_generator.md",
          "docs/vlingo_generator.md"
        ]
      ]
    ]
  end
end
