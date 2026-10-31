defmodule Mix.Tasks.VirtualTime.Upgrade do
  @moduledoc """
  Moves a project off the deprecated code-generator module names.

  `ActorSimulation.CAFGenerator` and its five siblings became
  `ActorSimulation.Codegen.*`. The old names still work and warn, so this is
  optional: it is the difference between a build with deprecation warnings and a
  build without them.

  ## Usage

      mix virtual_time.upgrade                        # what would change, and what needs a human
      mix virtual_time.upgrade --write                 # apply it
      mix virtual_time.upgrade --check                 # exit 1 when something would change (CI)
      mix virtual_time.upgrade --paths lib --paths test

  ## What it rewrites

    * `ActorSimulation.CAFGenerator.generate(...)`, and the five siblings used the
      same way;
    * `alias ActorSimulation.CAFGenerator` with the bare `CAFGenerator.foo()`
      calls that follow it, when the name it becomes (`CAF`) is free in that file.

  It reports instead of guessing when an alias uses `as:`, when the new short name
  is already taken, and when a bare short name has no alias it can point at.

  The rewrite is a token replacement, not a reformat: the rest of the file is
  byte for byte what it was, so the diff shows only what changed.
  """

  use Mix.Task

  alias VirtualTimeMigrate.Project
  alias VirtualTimeUpgrade

  @shortdoc "Renames the deprecated ActorSimulation.*Generator modules (report first, --write to apply)"

  @impl Mix.Task
  def run(args) do
    options = parse!(args)

    plans =
      Project.plan(options.paths, fn source, _converted -> VirtualTimeUpgrade.plan(source) end)

    pending = Project.pending(plans)

    Project.report(plans)
    finish(options, pending)

    :ok
  end

  defp parse!(args) do
    {options, _positional} =
      OptionParser.parse!(args, strict: [write: :boolean, check: :boolean, paths: :keep])

    %{
      write: options[:write] == true,
      check: options[:check] == true,
      paths: Project.paths(Keyword.get_values(options, :paths))
    }
  end

  defp finish(%{write: true}, pending) when pending != [], do: Project.write(pending)
  defp finish(%{check: true}, pending) when pending != [], do: exit({:shutdown, 1})

  defp finish(_options, []),
    do: IO.puts("Nothing to upgrade: no deprecated generator names here.")

  defp finish(_options, pending),
    do: IO.puts("\n#{length(pending)} file(s) would change. Re-run with --write to apply.")
end
