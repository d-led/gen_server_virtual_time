defmodule Mix.Tasks.Precommit do
  @moduledoc """
  Runs the checks CI runs, locally, before you commit.

      mix precommit         # formatting, compilation, tests, credo, docs
      mix precommit --all   # ... and dialyzer, which is the slow one

  Each package is a Mix project of its own, so every check runs inside the
  package it belongs to. The first failure stops the run with the command that
  failed: the first error is the one to fix.
  """

  use Mix.Task

  @shortdoc "Run the CI checks locally (--all adds dialyzer)"

  @packages ~w(gen_server_virtual_time actor_simulation actor_simulation_codegen gen_server_virtual_time_migrate)

  @impl Mix.Task
  def run(args) do
    steps = steps(all?: "--all" in args)

    Enum.each(steps, &run_step/1)

    IO.puts("\nAll #{length(steps)} checks passed.")
  end

  @typedoc "One check: what to call it, where to run it, and what to run."
  @type step :: %{label: String.t(), dir: String.t() | nil, command: [String.t()]}

  @doc """
  The checks, in order.

  `dir` is relative to the repository root, or `nil` for the workspace itself.
  """
  @spec steps(keyword) :: [step]
  def steps(options \\ []) do
    all? = Keyword.get(options, :all?, false)

    format_check() ++
      compile_check() ++
      [
        %{
          label: "tests (every package and the workspace)",
          dir: nil,
          command: ["bash", "scripts/test.sh"]
        }
      ] ++
      per_package("credo", ["mix", "credo", "--strict"]) ++
      per_package("docs", ["mix", "docs"]) ++
      dialyzer(all?)
  end

  defp format_check do
    [%{label: "workspace formatting", dir: nil, command: ["mix", "format", "--check-formatted"]}] ++
      per_package("formatting", ["mix", "format", "--check-formatted"])
  end

  defp compile_check, do: per_package("compile", ["mix", "compile", "--warnings-as-errors"])

  defp dialyzer(true), do: per_package("dialyzer", ["mix", "dialyzer"])
  defp dialyzer(false), do: []

  defp per_package(what, command) do
    Enum.map(@packages, fn package ->
      %{label: "#{package} #{what}", dir: Path.join("packages", package), command: command}
    end)
  end

  defp run_step(%{label: label, dir: dir, command: [executable | arguments]}) do
    IO.puts("\n== #{label} ==")

    {_output, status} =
      System.cmd(executable, arguments,
        cd: dir || ".",
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    if status != 0, do: Mix.raise("`#{Enum.join([executable | arguments], " ")}` failed")
  end
end
