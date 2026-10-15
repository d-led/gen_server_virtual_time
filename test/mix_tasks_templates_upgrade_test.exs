defmodule Mix.Tasks.Templates.UpgradeTest do
  @moduledoc """
  `mix templates.upgrade` is the only thing that writes the version table, so its
  own behaviour is exercised here: reporting, refusing to pass a check it cannot
  pass, and rewriting a table file.

  The task takes its fetcher and its table path as arguments, so these tests need
  neither the network nor the real table.

  Two of these tests are about the *ceiling* rather than the upgrade: a pin marked
  `:latest_within_major` must not follow an upstream major. That is what keeps a
  script from moving someone's generated project across a breaking change.
  """

  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias ActorSimulation.TemplateVersions
  alias ActorSimulation.TemplateVersions.Upgrade

  setup do
    # A copy of the real table, so a test can rewrite it without touching it.
    path =
      Path.join(System.tmp_dir!(), "template_versions_#{System.unique_integer([:positive])}.ex")

    File.write!(path, File.read!(Upgrade.module_path()))
    on_exit(fn -> File.rm(path) end)

    %{path: path}
  end

  describe "reporting" do
    test "lists every pin, its current version and where it comes from", %{path: path} do
      output = run_task(["--offline"], &offline/1, path)

      for {key, pin} <- TemplateVersions.all() do
        assert output =~ Atom.to_string(key), "#{key} is missing from the report"
        assert output =~ pin
      end

      assert output =~ "conan center: caf"
      assert output =~ "manual: minimum CMake the templates require"
    end

    test "lists what it could not read instead of silently skipping it", %{path: path} do
      output = run_task(["--offline"], &offline/1, path)

      assert output =~ "could not read"
    end
  end

  describe "checking" do
    test "passes when every pin is current", %{path: path} do
      output = run_task(["--check"], &upstream_holds_current/1, path)

      assert output =~ "Templates are up to date"
    end

    test "fails the build when a pin is behind, without writing", %{path: path} do
      before = File.read!(path)

      assert_raise Mix.Error, ~r/1 template version\(s\) are out of date/, fn ->
        run_task(["--check"], &caf_has_a_new_minor/1, path)
      end

      assert File.read!(path) == before, "--check must not write"
    end

    test "does not follow an upstream major on its own", %{path: path} do
      output = run_task(["--check"], &caf_has_a_new_major/1, path)

      assert output =~ "Templates are up to date"
    end
  end

  describe "writing" do
    test "takes a new minor and leaves every other pin alone", %{path: path} do
      output = run_task([], &caf_has_a_new_minor/1, path)
      rewritten = File.read!(path)

      assert output =~ "Updated #{path}"
      assert rewritten =~ ~s(caf: "1.2.0")

      for {key, pin} <- TemplateVersions.all(), key != :caf do
        assert rewritten =~ ~s(#{key}: "#{pin}"), "#{key} was rewritten"
      end

      assert Code.string_to_quoted!(rewritten)
    end

    test "leaves an up-to-date table alone", %{path: path} do
      before = File.read!(path)

      output = run_task([], &upstream_holds_current/1, path)

      assert output =~ "already current"
      assert File.read!(path) == before
    end
  end

  describe "regenerating examples" do
    test "runs the script behind every checked-in example project", %{path: path} do
      output = run_task(["--examples", "--offline"], &offline/1, path, fn _script -> 0 end)

      assert announced_scripts(output) == [
               "generate_omnetpp_examples",
               "generate_caf_examples",
               "generate_pony_examples",
               "generate_phony_examples",
               "generate_ractor_examples",
               "generate_vlingo_sample"
             ]

      for script <- announced_scripts(output) do
        assert File.exists?("scripts/#{script}.exs"), "#{script}.exs is missing from scripts/"
      end

      assert output =~ "Regenerated the checked-in example projects"
    end

    test "fails the build when a generator script fails", %{path: path} do
      fail_the_caf_script = fn
        "generate_caf_examples" -> 2
        _script -> 0
      end

      assert_raise Mix.Error, ~r/scripts\/generate_caf_examples\.exs exited with 2/, fn ->
        run_task(["--examples", "--offline"], &offline/1, path, fail_the_caf_script)
      end
    end

    test "does not regenerate examples unless asked", %{path: path} do
      run_task(["--offline"], &offline/1, path, fn script -> flunk("#{script} was run") end)
    end
  end

  # The scripts the task says it is about to run.
  defp announced_scripts(output) do
    ~r/^\$ mix run scripts\/(.+?)\.exs$/m
    |> Regex.scan(output, capture: :all_but_first)
    |> List.flatten()
  end

  defp run_task(args, fetch, path, run_script) do
    capture_io(fn -> Mix.Tasks.Templates.Upgrade.run(args, fetch, path, run_script) end)
  end

  defp run_task(args, fetch, path) do
    capture_io(fn -> Mix.Tasks.Templates.Upgrade.run(args, fetch, path) end)
  end

  defp offline(_url), do: {:error, :offline}

  # The CAF sources have a newer major *and* a newer minor available.
  defp caf_has_a_new_minor(url) do
    if String.ends_with?(url, "recipes/caf/config.yml") do
      {:ok, conan("99.0.0") <> conan("1.2.0") <> conan(TemplateVersions.get(:caf))}
    else
      upstream_holds_current(url)
    end
  end

  # The CAF sources have only a newer major available.
  defp caf_has_a_new_major(url) do
    if String.ends_with?(url, "recipes/caf/config.yml") do
      {:ok, conan("99.0.0") <> conan(TemplateVersions.get(:caf))}
    else
      upstream_holds_current(url)
    end
  end

  # Every upstream reports exactly what the table already pins.
  defp upstream_holds_current(url) do
    body =
      cond do
        String.ends_with?(url, "recipes/caf/config.yml") ->
          conan(TemplateVersions.get(:caf))

        String.ends_with?(url, "recipes/catch2/config.yml") ->
          conan(TemplateVersions.get(:catch2))

        String.contains?(url, "crates.io") ->
          ~s({"crate":{"max_stable_version":"#{crate_version(url)}"}})

        String.contains?(url, "proxy.golang.org") ->
          ~s({"Version":"#{TemplateVersions.get(:phony)}"})

        String.contains?(url, "maven-metadata.xml") ->
          maven_metadata(url)

        String.contains?(url, "releases/latest") ->
          ~s({"tag_name":"#{release_tag(url)}"})

        String.contains?(url, "tags?per_page") ->
          ~s([{"name":"v#{TemplateVersions.get(:mermaid)}.0.0"}])

        true ->
          flunk("no canned response for #{url}")
      end

    {:ok, body}
  end

  defp conan(version), do: ~s(versions:\n  "#{version}":\n    folder: all\n)

  defp crate_version(url) do
    cond do
      String.ends_with?(url, "/tokio") -> "#{TemplateVersions.get(:tokio)}.53.3"
      String.ends_with?(url, "/tokio-test") -> TemplateVersions.get(:tokio_test)
      String.ends_with?(url, "/ractor") -> TemplateVersions.get(:ractor)
    end
  end

  defp maven_metadata(url) do
    "<versioning><versions><version>#{maven_version(url)}</version></versions></versioning>"
  end

  defp maven_version(url) do
    cond do
      String.contains?(url, "xoom-actors") ->
        TemplateVersions.get(:vlingo)

      String.contains?(url, "junit-jupiter") ->
        TemplateVersions.get(:junit)

      String.contains?(url, "maven-compiler-plugin") ->
        TemplateVersions.get(:maven_compiler_plugin)

      String.contains?(url, "maven-surefire-plugin") ->
        TemplateVersions.get(:maven_surefire_plugin)

      String.contains?(url, "exec-maven-plugin") ->
        TemplateVersions.get(:maven_exec_plugin)

      String.contains?(url, "maven-assembly-plugin") ->
        TemplateVersions.get(:maven_assembly_plugin)
    end
  end

  defp release_tag(url) do
    cond do
      String.ends_with?(url, "omnetpp/omnetpp") -> "omnetpp-#{TemplateVersions.get(:omnetpp)}"
      String.ends_with?(url, "prismjs/prism") -> "v#{TemplateVersions.get(:prism)}"
      true -> "#{action_pin(url)}.0.0"
    end
  end

  defp action_pin(url) do
    Enum.find_value(TemplateVersions.sources(), fn
      {key, {:github_release, repo, :major_tag}} ->
        if String.ends_with?(url, repo), do: TemplateVersions.get(key)

      _source ->
        nil
    end)
  end
end
