defmodule ActorSimulation.TemplateVersionsTest do
  @moduledoc """
  The version table is the only place a generated project's dependencies are
  pinned, so these tests hold two ends of that contract:

    * the table itself is complete and well formed
    * every generator actually reads from it
  """

  use ExUnit.Case, async: true

  doctest ActorSimulation.TemplateVersions

  alias ActorSimulation.CAFGenerator
  alias ActorSimulation.OMNeTPPGenerator
  alias ActorSimulation.PhonyGenerator
  alias ActorSimulation.PonyGenerator
  alias ActorSimulation.RactorGenerator
  alias ActorSimulation.TemplateVersions
  alias ActorSimulation.VlingoGenerator

  describe "the table" do
    test "every version has a source" do
      assert Enum.sort(Map.keys(TemplateVersions.versions())) ==
               Enum.sort(Enum.map(TemplateVersions.sources(), &elem(&1, 0)))
    end

    test "every version is a version-shaped string" do
      for {key, version} <- TemplateVersions.all() do
        assert is_binary(version) and version != "", "#{key} has no version"
      end
    end

    test "all/0 follows the presentation order of the sources" do
      assert Enum.map(TemplateVersions.all(), &elem(&1, 0)) ==
               Enum.map(TemplateVersions.sources(), &elem(&1, 0))
    end

    test "manual entries explain why they are not tracked" do
      manual =
        for {key, {:manual, reason, :none}} <- TemplateVersions.sources(), do: {key, reason}

      assert manual != []

      for {key, reason} <- manual do
        assert is_binary(reason) and reason != "", "#{key} needs a reason"
      end
    end

    test "the keys that are tracked by hand are the ones with no upstream" do
      manual = for {key, {:manual, _reason, :none}} <- TemplateVersions.sources(), do: key

      assert Enum.sort(manual) ==
               [
                 :cmake_minimum,
                 :corral_channel,
                 :cpp_standard,
                 :go,
                 :java_release,
                 :ponyc_channel,
                 :rust_edition
               ]
    end

    test "every kind of source describes itself for the report" do
      describe = &TemplateVersions.describe/1

      assert describe.({:conan_center, "caf", :latest_within_major}) == "conan center: caf"
      assert describe.({:crates_io, "ractor", :version}) == "crates.io: ractor"
      assert describe.({:go_module, "github.com/x/y", :raw}) == "go module: github.com/x/y"
      assert describe.({:maven_central, "g:a", :latest_within_major}) == "maven central: g:a"
      assert describe.({:github_release, "o/r", :version}) == "github release: o/r"
      assert describe.({:github_release, "o/r", :major}) == "github release: o/r, major only"
      assert describe.({:github_release, "o/r", :major_tag}) == "github release: o/r"
      assert describe.({:github_tags, "o/r", :major}) == "github tags: o/r, major only"
      assert describe.({:github_tags, "o/r", :version}) == "github tags: o/r"
      assert describe.({:manual, "a reason", :none}) == "manual: a reason"
    end

    test "a pin that is not a version has no major" do
      assert TemplateVersions.major(:ponyc_channel) == nil
      assert TemplateVersions.major(:caf) == "1"
    end

    test "an unknown key is an error rather than a silent default" do
      assert_raise KeyError, fn -> TemplateVersions.get(:no_such_dependency) end
    end
  end

  describe "generated projects" do
    test "take the C++ pins from the table" do
      conan =
        file("conanfile.txt", CAFGenerator.generate(simulation(), project_name: "TableActors"))

      cmake =
        file("CMakeLists.txt", CAFGenerator.generate(simulation(), project_name: "TableActors"))

      assert conan =~ "caf/#{TemplateVersions.get(:caf)}"
      assert conan =~ "catch2/#{TemplateVersions.get(:catch2)}"
      assert cmake =~ "cmake_minimum_required(VERSION #{TemplateVersions.get(:cmake_minimum)})"
      assert cmake =~ "set(CMAKE_CXX_STANDARD #{TemplateVersions.get(:cpp_standard)})"
      assert cmake =~ "find_package(Catch2 #{TemplateVersions.major(:catch2)} REQUIRED)"
    end

    test "take the OMNeT++ pin from the table" do
      ci =
        file(
          ".github/workflows/ci.yml",
          OMNeTPPGenerator.generate(simulation(), network_name: "TableNetwork")
        )

      assert ci =~ "opp_env install omnetpp-#{TemplateVersions.get(:omnetpp)}"
    end

    test "take the Go module pins from the table" do
      gomod = file("go.mod", PhonyGenerator.generate(simulation(), project_name: "table_actors"))

      assert gomod =~ "go #{TemplateVersions.get(:go)}"
      assert gomod =~ "require github.com/Arceliar/phony #{TemplateVersions.get(:phony)}"
    end

    test "take the Rust crate pins from the table" do
      cargo =
        file("Cargo.toml", RactorGenerator.generate(simulation(), project_name: "table_actors"))

      assert cargo =~ ~s(ractor = "#{TemplateVersions.get(:ractor)}")
      assert cargo =~ ~s(tokio = { version = "#{TemplateVersions.get(:tokio)}")
      assert cargo =~ ~s(tokio-test = "#{TemplateVersions.get(:tokio_test)}")
    end

    test "take the Maven pins from the table" do
      pom =
        file(
          "pom.xml",
          VlingoGenerator.generate(simulation(),
            project_name: "table-actors",
            group_id: "com.example"
          )
        )

      assert pom =~ "<vlingo.version>#{TemplateVersions.get(:vlingo)}</vlingo.version>"
      assert pom =~ "<junit.version>#{TemplateVersions.get(:junit)}</junit.version>"
      assert pom =~ "<release>#{TemplateVersions.get(:java_release)}</release>"
      assert pom =~ ~s(<version>#{TemplateVersions.get(:maven_surefire_plugin)}</version>)
    end

    test "take the Pony channel from the table" do
      ci =
        file(
          ".github/workflows/ci.yml",
          PonyGenerator.generate(simulation(), project_name: "table_actors")
        )

      assert ci =~ "ponyup update ponyc #{TemplateVersions.get(:ponyc_channel)}"
      assert ci =~ "ponyup update corral #{TemplateVersions.get(:corral_channel)}"
    end

    test "pin the GitHub Actions used by every generated CI workflow" do
      workflows = %{
        "CAF" => generation(CAFGenerator, project_name: "TableActors"),
        "OMNeT++" => generation(OMNeTPPGenerator, network_name: "TableNetwork"),
        "Phony" => generation(PhonyGenerator, project_name: "table_actors"),
        "Pony" => generation(PonyGenerator, project_name: "table_actors"),
        "Ractor" => generation(RactorGenerator, project_name: "table_actors"),
        "VLINGO" =>
          generation(VlingoGenerator, project_name: "table-actors", group_id: "com.example")
      }

      for {language, files} <- workflows do
        ci = file(".github/workflows/ci.yml", files)

        assert ci =~ "actions/checkout@#{TemplateVersions.get(:checkout_action)}",
               "#{language} CI does not use the pinned checkout action"
      end
    end

    test "refer to this repository, not a placeholder" do
      readme =
        file("README.md", PhonyGenerator.generate(simulation(), project_name: "table_actors"))

      assert readme =~ "https://github.com/d-led/gen_server_virtual_time"
    end
  end

  defp simulation do
    ActorSimulation.new()
    |> ActorSimulation.add_actor(:sender,
      send_pattern: {:periodic, 100, :msg},
      targets: [:receiver]
    )
    |> ActorSimulation.add_actor(:receiver)
  end

  defp generation(generator, options) do
    {:ok, files} = generator.generate(simulation(), options)
    GeneratorAssertions.assert_file_plan(files)
    files
  end

  defp file(name, {:ok, files}), do: file(name, files)
  defp file(name, files) when is_list(files), do: GeneratorAssertions.file_content(files, name)
end
