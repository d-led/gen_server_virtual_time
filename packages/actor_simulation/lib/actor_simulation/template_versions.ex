defmodule ActorSimulation.TemplateVersions do
  @moduledoc """
  The third-party versions that the code generators pin in the projects they
  emit.

  A generated project is a real project: it has a `conanfile.txt`, a `go.mod`, a
  `Cargo.toml`, a `pom.xml` and a CI workflow of its own. Each of those pins
  versions, and those pins drift. Keeping the literals scattered across six
  generator modules made drift invisible; this module makes it a single table
  that can be read, reviewed, and upgraded.

  Generators read versions through `get/1`, for example:

      ActorSimulation.TemplateVersions.get(:caf)

  ## Checking for drift

      mix templates.upgrade --check

  ## Upgrading

      mix templates.upgrade

  `sources/0` records where each version comes from, so `mix templates.upgrade`
  can ask upstream for the latest release. Versions marked `:manual` have no
  meaningful upstream (a language level, a minimum CMake, a floating release
  channel) and are reported but never rewritten automatically.

  ## Generated projects

  The generated project templates and the projects checked into `examples/` and
  `generated/` come from the same generators, so after upgrading run
  `mix templates.upgrade --examples` to regenerate the checked-in ones.
  """

  # --- versions:begin (managed by `mix templates.upgrade`) ---
  @versions %{
    # conan center: caf
    caf: "1.1.0",
    # conan center: catch2
    catch2: "3.16.0",
    # manual: minimum CMake the templates require
    cmake_minimum: "3.15",
    # manual: C++ standard the templates compile with
    cpp_standard: "17",
    # github release: omnetpp/omnetpp
    omnetpp: "6.4.0",
    # manual: Go language version the module targets
    go: "1.21",
    # go module: github.com/Arceliar/phony
    phony: "v0.0.0-20220903101357-530938a4b13d",
    # manual: ponyup channel, always latest
    ponyc_channel: "release",
    # manual: ponyup channel, always latest
    corral_channel: "release",
    # manual: Rust edition the templates compile with
    rust_edition: "2021",
    # crates.io: ractor
    ractor: "0.16.5",
    # crates.io: tokio
    tokio: "1",
    # crates.io: tokio-test
    tokio_test: "0.4.6",
    # maven central: io.vlingo.xoom:xoom-actors
    vlingo: "1.11.1",
    # maven central: org.junit.jupiter:junit-jupiter
    junit: "5.14.4",
    # manual: Java release level the templates compile with
    java_release: "11",
    # maven central: org.apache.maven.plugins:maven-compiler-plugin
    maven_compiler_plugin: "3.16.0",
    # maven central: org.apache.maven.plugins:maven-surefire-plugin
    maven_surefire_plugin: "3.6.0",
    # maven central: org.codehaus.mojo:exec-maven-plugin
    maven_exec_plugin: "3.6.4",
    # maven central: org.apache.maven.plugins:maven-assembly-plugin
    maven_assembly_plugin: "3.8.0",
    # github tags: mermaid-js/mermaid, major only
    mermaid: "11",
    # github release: prismjs/prism
    prism: "1.30.0",
    # github release: actions/checkout
    checkout_action: "v7",
    # github release: actions/cache
    cache_action: "v6",
    # github release: actions/setup-go
    setup_go_action: "v7",
    # github release: actions/setup-java
    setup_java_action: "v6",
    # github release: actions/setup-python
    setup_python_action: "v7",
    # github release: actions-rust-lang/setup-rust-toolchain
    setup_rust_toolchain_action: "v2",
    # github release: conan-io/setup-conan
    setup_conan_action: "v1",
    # github release: EnricoMi/publish-unit-test-result-action
    publish_test_results_action: "v2"
  }

  # --- versions:end ---

  @doc """
  Every pinned version as a map.

  ## Examples

      iex> ActorSimulation.TemplateVersions.get(:caf) |> is_binary()
      true
  """
  @spec versions() :: %{atom() => String.t()}
  def versions, do: @versions

  @doc """
  The version pinned under `key`.

  Raises `KeyError` for a key that is not in the table.

  ## Examples

      iex> ActorSimulation.TemplateVersions.get(:checkout_action) |> String.starts_with?("v")
      true
  """
  @spec get(atom()) :: String.t()
  def get(key), do: Map.fetch!(@versions, key)

  @doc """
  Every pin in presentation order, as `{key, version}` pairs.
  """
  @spec all() :: [{atom(), String.t()}]
  def all, do: for({key, _source} <- sources(), do: {key, get(key)})

  @doc """
  The major component of `key`'s version, or `nil` when the pin is not a version
  at all (a release channel, or a Go pseudo-version).

  Templates that must name a major (a CMake package major, a JS library major)
  use this instead of repeating the digit, so the major cannot drift away from
  the pinned version.

  ## Examples

      iex> ActorSimulation.TemplateVersions.major(:caf)
      "1"

      iex> ActorSimulation.TemplateVersions.major(:ponyc_channel)
      nil
  """
  @spec major(atom()) :: String.t() | nil
  def major(key) do
    case Regex.run(~r/^\d+/, get(key)) do
      [digits] -> digits
      nil -> nil
    end
  end

  @doc """
  Where each pin comes from, in the order the table should be presented.

  A source is `{kind, target, transform}`:

    * `{:conan_center, package, transform}` — ConanCenter recipes
    * `{:crates_io, crate, transform}` — crates.io
    * `{:go_module, module, transform}` — the Go module proxy
    * `{:maven_central, "group:artifact", transform}` — Maven Central metadata
    * `{:github_release, "owner/repo", transform}` — the latest GitHub release
    * `{:github_tags, "owner/repo", transform}` — the highest semver tag, for
      repositories whose newest release is not the library we pin (Mermaid)
    * `{:manual, reason, :none}` — deliberately not tracked against an upstream

  `transform` says how much of the upstream version we take:

    * `:version` — the whole version (`"6.2.0"`)
    * `:latest_within_major` — the newest release on the *current* major, so a
      script never pushes a generated project across a breaking major
    * `:major` — only the major (`"11"`), for pins that float within it
    * `:major_tag` — `"v7"`, how GitHub Actions are pinned
    * `:raw` — the upstream value untouched (`"v0.0.0-2022..."`)
  """
  @spec sources() :: [{atom(), term()}]
  def sources do
    [
      # C++ (Conan)
      caf: {:conan_center, "caf", :latest_within_major},
      catch2: {:conan_center, "catch2", :latest_within_major},
      cmake_minimum: {:manual, "minimum CMake the templates require", :none},
      cpp_standard: {:manual, "C++ standard the templates compile with", :none},
      # OMNeT++
      omnetpp: {:github_release, "omnetpp/omnetpp", :version},
      # Go
      go: {:manual, "Go language version the module targets", :none},
      phony: {:go_module, "github.com/Arceliar/phony", :raw},
      # Pony
      ponyc_channel: {:manual, "ponyup channel, always latest", :none},
      corral_channel: {:manual, "ponyup channel, always latest", :none},
      # Rust
      rust_edition: {:manual, "Rust edition the templates compile with", :none},
      ractor: {:crates_io, "ractor", :version},
      tokio: {:crates_io, "tokio", :major},
      tokio_test: {:crates_io, "tokio-test", :version},
      # Java
      vlingo: {:maven_central, "io.vlingo.xoom:xoom-actors", :latest_within_major},
      junit: {:maven_central, "org.junit.jupiter:junit-jupiter", :latest_within_major},
      java_release: {:manual, "Java release level the templates compile with", :none},
      maven_compiler_plugin:
        {:maven_central, "org.apache.maven.plugins:maven-compiler-plugin", :latest_within_major},
      maven_surefire_plugin:
        {:maven_central, "org.apache.maven.plugins:maven-surefire-plugin", :latest_within_major},
      maven_exec_plugin:
        {:maven_central, "org.codehaus.mojo:exec-maven-plugin", :latest_within_major},
      maven_assembly_plugin:
        {:maven_central, "org.apache.maven.plugins:maven-assembly-plugin", :latest_within_major},
      # HTML assets in generated reports
      mermaid: {:github_tags, "mermaid-js/mermaid", :major},
      prism: {:github_release, "prismjs/prism", :version},
      # GitHub Actions
      checkout_action: {:github_release, "actions/checkout", :major_tag},
      cache_action: {:github_release, "actions/cache", :major_tag},
      setup_go_action: {:github_release, "actions/setup-go", :major_tag},
      setup_java_action: {:github_release, "actions/setup-java", :major_tag},
      setup_python_action: {:github_release, "actions/setup-python", :major_tag},
      setup_rust_toolchain_action:
        {:github_release, "actions-rust-lang/setup-rust-toolchain", :major_tag},
      setup_conan_action: {:github_release, "conan-io/setup-conan", :major_tag},
      publish_test_results_action:
        {:github_release, "EnricoMi/publish-unit-test-result-action", :major_tag}
    ]
  end

  @doc """
  A human-readable description of `source`, used as the trailing comment in the
  rendered version table.
  """
  @spec describe(term()) :: String.t()
  def describe({:conan_center, package, _transform}), do: "conan center: #{package}"
  def describe({:crates_io, crate, _transform}), do: "crates.io: #{crate}"
  def describe({:go_module, module, _transform}), do: "go module: #{module}"
  def describe({:maven_central, coord, _transform}), do: "maven central: #{coord}"
  def describe({:github_release, repo, :major}), do: "github release: #{repo}, major only"
  def describe({:github_release, repo, _transform}), do: "github release: #{repo}"
  def describe({:github_tags, repo, :major}), do: "github tags: #{repo}, major only"
  def describe({:github_tags, repo, _transform}), do: "github tags: #{repo}"
  def describe({:manual, reason, _transform}), do: "manual: #{reason}"
end
