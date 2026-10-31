defmodule DoctorTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias VirtualTimeGenServer.{Doctor, ModuleReferences}

  describe "reading a project's module references" do
    test "finds a remote call, with the file and the line it is on" do
      scan = ModuleReferences.scan([fixture("simulation.ex")])

      assert %{module: "ActorSimulation", function: "new", line: 3} = scan.references |> hd()
      assert scan.references |> hd() |> Map.fetch!(:file) |> Path.basename() == "simulation.ex"
    end

    test "finds every module a file names, in source order" do
      modules =
        ModuleReferences.scan([fixture("generator.ex")]).references |> Enum.map(& &1.module)

      assert modules == ["ActorSimulation.Codegen.CAF", "ActorSimulation"]
    end

    test "a file that does not parse is reported, and the rest is still read" do
      scan = ModuleReferences.scan([fixture("broken.ex"), fixture("simulation.ex")])

      assert scan.unparsable == [fixture("broken.ex")]
      refute scan.references == []
    end
  end

  describe "diagnosing a project" do
    test "a module from a package the project does not have is a finding" do
      [finding] = diagnose(fixture("simulation.ex"), available: [])

      assert finding.kind == :missing_package
      assert finding.module == "ActorSimulation"
      assert finding.dependency == ~s|{:actor_simulation, "~> 1.0"}|
    end

    test "nothing is reported once the module is available" do
      assert diagnose(fixture("simulation.ex"), available: ["ActorSimulation"]) == []
    end

    test "the code generators are reported against their own package" do
      [finding] = diagnose(fixture("generator.ex"), available: ["ActorSimulation"])

      assert finding.module == "ActorSimulation.Codegen.CAF"
      assert finding.dependency == ~s|{:actor_simulation_codegen, "~> 1.0"}|
    end

    test "modules of this package are never a finding" do
      assert diagnose(fixture("clock.ex"), available: []) == []
    end

    test "a call that was removed is reported with what to write instead" do
      [finding] = diagnose(fixture("removed_api.ex"), available: [])

      assert finding.kind == :removed_api
      assert finding.module == "VirtualTimeGenServer"
      assert finding.function == "enable_stats_tracking"
      assert finding.replacement =~ "instrumentation: MyObserver"
    end
  end

  describe "what the maintainer reads" do
    test "a project with nothing to fix is told so" do
      assert Doctor.format([]) == "Nothing to do: every module you reference is available.\n"
    end

    test "the report names the dependency to add and where the module is used" do
      report = Doctor.format(diagnose(fixture("simulation.ex"), available: []))

      assert report =~ ~s|{:actor_simulation, "~> 1.0"}|
      assert report =~ "No code changes are needed"
      assert report =~ "simulation.ex:3: ActorSimulation.new"
    end

    test "each missing package is offered once, however often it is used" do
      findings = diagnose(fixture("simulation.ex"), available: [])

      assert Doctor.missing_dependencies(findings ++ findings) == [
               ~s|{:actor_simulation, "~> 1.0"}|
             ]
    end

    test "a removed call is shown with its replacement on the next line" do
      report = Doctor.format(diagnose(fixture("removed_api.ex"), available: []))

      assert report =~ "VirtualTimeGenServer.enable_stats_tracking"
      assert report =~ "instrument/1"
    end
  end

  describe "the task" do
    test "reports what the project has to change, reading the tree it is given" do
      output = capture_io(fn -> Mix.Tasks.VirtualTime.Doctor.run(["--paths", fixture_dir()]) end)

      assert output =~ "VirtualTimeGenServer.enable_stats_tracking"
      assert output =~ "instrument/1"
      assert output =~ "Could not parse"
    end
  end

  defp diagnose(file, available: available) do
    Doctor.diagnose(ModuleReferences.scan([file]).references, &(&1 in available))
  end

  defp fixture(name), do: Path.expand("fixtures/doctor/#{name}", __DIR__)

  defp fixture_dir, do: Path.expand("fixtures/doctor", __DIR__)
end
