defmodule VirtualTimeMigrate.MixProject do
  use Mix.Project

  @version "1.0.1"
  @source_url "https://github.com/d-led/gen_server_virtual_time"

  def project do
    [
      app: :gen_server_virtual_time_migrate,
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
      name: "GenServerVirtualTimeMigrate",

      # Code quality and test reporting
      test_coverage: [tool: ExCoveralls, summary: [threshold: 70]],
      test_paths: ["test"],
      test_ignore_filters: [~r"test/fixtures/"],
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
      # Test reporting
      {:junit_formatter, "~> 3.4", only: :test, runtime: false},

      # Documentation
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},

      # Code quality
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Coverage
      {:excoveralls, "~> 0.18", only: :test, runtime: false}
    ]
  end

  defp description do
    """
    `mix virtual_time.migrate` rewrites GenServer and GenStateMachine modules to
    their virtual-time equivalents, reporting first and writing only when asked.
    Dev-only: it rewrites source, it is not a runtime dependency.
    """
  end

  defp package do
    [
      name: "gen_server_virtual_time_migrate",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      maintainers: ["Dmitry Ledentsov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "The library it rewrites for" => "https://hexdocs.pm/gen_server_virtual_time"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      source_url_pattern:
        "#{@source_url}/blob/v#{@version}/packages/gen_server_virtual_time_migrate/%{path}#L%{line}",
      extras: [
        {"README.md", [title: "Overview"]},
        {"../../CHANGELOG.md", [title: "Changelog"]},
        {"LICENSE", [title: "License"]}
      ],
      groups_for_extras: [Project: ["README.md", "../../CHANGELOG.md", "LICENSE"]]
    ]
  end
end
