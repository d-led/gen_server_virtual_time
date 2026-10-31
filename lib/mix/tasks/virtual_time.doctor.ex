defmodule Mix.Tasks.VirtualTime.Doctor do
  @moduledoc """
  Reports modules your project uses that live in another package of the family,
  and the dependency line that makes the build work again.

  The library is published as a family of packages that share one version:
  `gen_server_virtual_time` (the clock and the OTP wrappers),
  `actor_simulation` (the DSL, statistics and diagrams) and
  `actor_simulation_codegen` (the code generators). A module keeps its name when
  it moves to another package, so a project that is missing one of them does not
  need code changes — it needs a dependency.

  ## Usage

      mix virtual_time.doctor                  # report, always exit 0
      mix virtual_time.doctor --check          # exit 1 when something is missing (CI)
      mix virtual_time.doctor --paths lib,test,config

  ## Example

      $ mix virtual_time.doctor

      This project refers to modules that are not available.

      Add these to your deps:

          {:actor_simulation, "~> 1.0"}

      No code changes are needed — a module keeps its name when it changes
      package. Then run `mix deps.get`.

      Where they are used:
          lib/my_app/pipeline.ex:12: ActorSimulation.new  →  {:actor_simulation, "~> 1.0"}
  """

  use Mix.Task

  alias VirtualTimeGenServer.{Doctor, ModuleReferences}

  @shortdoc "Reports modules that moved to another package, and the dependency that fixes the build"

  @default_paths ~w(lib test config)

  @impl Mix.Task
  def run(args) do
    {options, _positional} = OptionParser.parse!(args, strict: strict())

    paths = options |> Keyword.get(:paths, @default_paths) |> String.split(",", trim: true)
    scan = ModuleReferences.scan(paths)
    findings = Doctor.diagnose(scan.references, &available?/1)

    IO.puts(Doctor.format(findings))
    report_unparsable(scan.unparsable)

    if options[:check] && findings != [] do
      exit({:shutdown, 1})
    end

    :ok
  end

  defp available?(module_name) do
    module_name |> String.split(".") |> Module.concat() |> Code.ensure_loaded?()
  end

  # A project that does not compile is when this task is most useful, so a file
  # it cannot parse is reported and the rest of the tree is still read.
  defp report_unparsable([]), do: :ok

  defp report_unparsable(files) do
    IO.puts("Could not parse (skipped):\n")

    Enum.each(files, &IO.puts("    #{&1}"))

    IO.puts("")
  end

  defp strict do
    [
      paths: :string,
      check: :boolean,
      help: :boolean
    ]
  end
end
