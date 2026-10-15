defmodule ActorSimulation.TemplateVersions.UpgradeTest do
  @moduledoc """
  The upgrade task is the only thing that writes
  `ActorSimulation.TemplateVersions`, so it is tested against canned copies of
  what each upstream actually returns — no network, and every response format is
  pinned by a test.
  """

  use ExUnit.Case, async: true

  alias ActorSimulation.TemplateVersions
  alias ActorSimulation.TemplateVersions.Upgrade

  describe "reading upstreams" do
    test "ConanCenter recipes: the newest release on the current major" do
      body = """
      versions:
        "2.0.0":
          folder: all
        "1.1.0":
          folder: all
        "1.0.2":
          folder: all
        "0.19.4":
          folder: all
      """

      assert latest({:conan_center, "caf", :latest_within_major}, body, "1.0.2") == "1.1.0"
    end

    test "crates.io: the newest stable release, or only its major" do
      body = ~s({"crate":{"max_stable_version":"1.53.3","max_version":"1.53.3"}})

      assert latest({:crates_io, "tokio-test", :version}, body, "0.4") == "1.53.3"
      assert latest({:crates_io, "tokio", :major}, body, "1") == "1"
    end

    test "the Go module proxy: the version untouched, pseudo-versions included" do
      body = ~s({"Version":"v0.0.0-20220903101357-530938a4b13d","Time":"2022-09-03T10:13:57Z"})

      assert latest({:go_module, "github.com/Arceliar/phony", :raw}, body, "v0.0.0-old") ==
               "v0.0.0-20220903101357-530938a4b13d"
    end

    test "Maven Central metadata: the newest stable release on the current major" do
      body = """
      <metadata>
        <versioning>
          <latest>4.0.0-beta-1</latest>
          <release>4.0.0-beta-1</release>
          <versions>
            <version>3.13.0</version>
            <version>3.15.0</version>
            <version>3.16.0-M1</version>
            <version>4.0.0-beta-1</version>
          </versions>
        </versioning>
      </metadata>
      """

      assert latest(
               {:maven_central, "org.apache.maven.plugins:maven-compiler-plugin",
                :latest_within_major},
               body,
               "3.11.0"
             ) ==
               "3.15.0"
    end

    test "GitHub releases: a version, a major, or the major tag Actions use" do
      body = ~s({"tag_name":"omnetpp-6.4.0","name":"OMNeT++ 6.4.0"})

      assert latest({:github_release, "omnetpp/omnetpp", :version}, body, "6.2.0") == "6.4.0"
      assert latest({:github_release, "omnetpp/omnetpp", :major}, body, "6.2.0") == "6"
      assert latest({:github_release, "actions/checkout", :major_tag}, body, "v7") == "v6"
    end

    test "GitHub tags: the highest semver tag, for repositories whose newest release is not ours" do
      body = ~s([{"name":"@mermaid-js/tiny@12.2.0"},{"name":"v11.12.0"},{"name":"v11.0.0"}])

      assert latest({:github_tags, "mermaid-js/mermaid", :major}, body, "11") == "11"
    end

    test "a manual entry has no upstream at all" do
      assert Upgrade.upstream({:manual, "a language level", :none}) == :manual
    end

    test "a response that holds no version resolves to nothing rather than a wrong version" do
      assert latest(
               {:github_release, "actions/checkout", :major_tag},
               ~s({"message":"Not Found"}),
               "v7"
             ) ==
               nil
    end
  end

  describe "version_from_tag/1" do
    test "reads the version out of the tag flavours in use" do
      assert Upgrade.version_from_tag("v7.0.1") == "7.0.1"
      assert Upgrade.version_from_tag("omnetpp-6.4.0") == "6.4.0"
      assert Upgrade.version_from_tag("1.29.0") == "1.29.0"
      assert Upgrade.version_from_tag("nightly") == nil
      assert Upgrade.version_from_tag(nil) == nil
    end
  end

  describe "planning" do
    test "reports what moved, what did not, what is manual and what could not be read" do
      plan = Upgrade.plan(fetch(urls()), TemplateVersions.versions())

      assert entry(plan, :caf) == %{status: :update, current: "1.1.0", latest: "1.2.0"}
      assert entry(plan, :vlingo) == %{status: :current, current: "1.11.1", latest: "1.11.1"}
      assert entry(plan, :cmake_minimum).status == :manual
      assert entry(plan, :junit).status == :unresolved
      assert Upgrade.drift?(plan)
    end

    test "a plan that matches the table has no drift" do
      plan = Upgrade.plan(fn url -> {:ok, body_matching(url)} end, TemplateVersions.versions())

      refute Upgrade.drift?(plan)
      assert Upgrade.apply_plan(plan) == TemplateVersions.versions()
    end

    test "an offline run resolves nothing and changes nothing" do
      plan = Upgrade.plan(fn _url -> {:error, :offline} end, TemplateVersions.versions())

      refute Upgrade.drift?(plan)
      assert Upgrade.apply_plan(plan) == TemplateVersions.versions()

      assert Enum.all?(plan, fn
               %{status: :manual} -> true
               %{status: :unresolved} -> true
               _other -> false
             end)
    end
  end

  describe "rewriting the table" do
    test "the checked-in table is exactly what the renderer produces" do
      source = File.read!(Upgrade.module_path())

      assert Upgrade.rewrite(source, TemplateVersions.versions()) == source,
             "run `mix templates.upgrade` to re-render lib/actor_simulation/template_versions.ex"
    end

    test "changes only the version block, and produces a file that still parses" do
      source = File.read!(Upgrade.module_path())
      table = Map.put(TemplateVersions.versions(), :caf, "9.9.9")

      rewritten = Upgrade.rewrite(source, table)

      assert rewritten =~ ~s(caf: "9.9.9")
      assert rewritten =~ "@moduledoc"
      assert Code.string_to_quoted!(rewritten)
      assert rewrites_to_same(rewritten, table)
    end

    test "keeps every other pin untouched" do
      source = File.read!(Upgrade.module_path())
      rewritten = Upgrade.rewrite(source, Map.put(TemplateVersions.versions(), :caf, "9.9.9"))

      for {key, version} <- TemplateVersions.all(), key != :caf do
        assert rewritten =~ ~s(#{key}: "#{version}"), "#{key} was rewritten"
      end
    end
  end

  defp rewrites_to_same(source, table),
    do: Upgrade.rewrite(source, table) == Upgrade.rewrite(Upgrade.rewrite(source, table), table)

  defp latest(source, body, current) do
    {:ok, _url, parse} = Upgrade.upstream(source)
    parse.(body, current)
  end

  defp entry(plan, key),
    do: plan |> Enum.find(&(&1.key == key)) |> Map.take([:status, :current, :latest])

  # One canned body per upstream, in the shape that upstream really returns.
  # `junit` is deliberately left out so the plan has something it cannot read.
  defp urls do
    TemplateVersions.sources()
    |> Enum.flat_map(fn {_key, source} ->
      case Upgrade.upstream(source) do
        {:ok, url, _parse} -> [url]
        :manual -> []
      end
    end)
    |> Enum.reject(&String.contains?(&1, "junit-jupiter"))
    |> Map.new(&{&1, fetch_body(&1)})
  end

  defp fetch(urls) do
    fn url ->
      case Map.fetch(urls, url) do
        {:ok, body} -> {:ok, body}
        :error -> {:error, :not_stubbed}
      end
    end
  end

  defp fetch_body(url) do
    if String.ends_with?(url, "recipes/caf/config.yml") do
      conan_body("1.2.0") <> conan_body("1.1.0")
    else
      body_matching(url)
    end
  end

  defp body_matching(url) do
    cond do
      String.ends_with?(url, "recipes/caf/config.yml") ->
        conan_body(TemplateVersions.get(:caf))

      String.ends_with?(url, "recipes/catch2/config.yml") ->
        conan_body(TemplateVersions.get(:catch2))

      String.contains?(url, "crates.io") ->
        ~s({"crate":{"max_stable_version":"#{crate_version(url)}"}})

      String.contains?(url, "proxy.golang.org") ->
        ~s({"Version":"#{TemplateVersions.get(:phony)}"})

      String.contains?(url, "maven-metadata.xml") ->
        "<versioning><versions><version>#{maven_version(url)}</version></versions></versioning>"

      String.contains?(url, "releases/latest") ->
        ~s({"tag_name":"#{release_tag(url)}"})

      String.contains?(url, "tags?per_page") ->
        ~s([{"name":"v#{TemplateVersions.get(:mermaid)}.0.0"}])

      true ->
        flunk("no canned response for #{url}")
    end
  end

  defp conan_body(version), do: "versions:\n  \"#{version}\":\n    folder: all\n"

  defp crate_version(url) do
    cond do
      String.ends_with?(url, "/tokio") -> "#{TemplateVersions.get(:tokio)}.53.3"
      String.ends_with?(url, "/tokio-test") -> TemplateVersions.get(:tokio_test)
      String.ends_with?(url, "/ractor") -> TemplateVersions.get(:ractor)
    end
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
      true -> action_tag(url)
    end
  end

  defp action_tag(url) do
    Enum.find_value(TemplateVersions.sources(), fn
      {key, {:github_release, repo, :major_tag}} ->
        if String.ends_with?(url, repo), do: "#{TemplateVersions.get(key)}.0.0"

      _source ->
        nil
    end)
  end
end
