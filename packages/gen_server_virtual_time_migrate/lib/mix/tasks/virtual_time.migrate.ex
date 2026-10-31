defmodule Mix.Tasks.VirtualTime.Migrate do
  @moduledoc """
  Rewrites `GenServer` and `GenStateMachine` modules to their virtual-time
  equivalents, reporting first and writing only when asked.

  ## Usage

      mix virtual_time.migrate                       # what would change, and what needs a human
      mix virtual_time.migrate --write               # apply it
      mix virtual_time.migrate --check               # exit 1 when something would change (CI)
      mix virtual_time.migrate --paths lib --paths test

  ## What it rewrites

    * `use GenServer` → `use VirtualTimeGenServer`, options untouched;
      `use GenStateMachine` → `use VirtualTimeGenStateMachine`;
    * inside a converted module, `Process.send_after/3`, `:erlang.send_after/3`,
      `Process.sleep/1` and `:timer.sleep/1` → the `VirtualTimeGenServer`
      equivalents, which is what puts the module on the virtual clock;
    * `GenServer.call/cast/stop/reply/start_link/start/child_spec` when the
      target is a literal module this tree converts, or `__MODULE__`.

  It never guesses: a call on a pid or a variable is reported and left alone,
  and a call to a module that stays a plain `GenServer` is not touched. A file
  that does not parse is reported and skipped, and a rewrite that would not
  parse aborts the whole run without writing anything.

  The rewrite is a token replacement, not a reformat: the rest of the file is
  byte for byte what it was, so the diff shows only what changed.
  """

  use Mix.Task

  alias VirtualTimeMigrate
  alias VirtualTimeMigrate.Project

  @shortdoc "Rewrites GenServer modules to VirtualTimeGenServer (report first, --write to apply)"

  @impl Mix.Task
  def run(args) do
    options = parse!(args)
    plans = Project.plan(options.paths, &VirtualTimeMigrate.plan/2)
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
    do: IO.puts("Nothing to migrate: every GenServer here is already a virtual-time server.")

  defp finish(_options, pending),
    do: IO.puts("\n#{length(pending)} file(s) would change. Re-run with --write to apply.")
end
