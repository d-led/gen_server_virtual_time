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

  @shortdoc "Rewrites GenServer modules to VirtualTimeGenServer (report first, --write to apply)"

  @default_paths ~w(lib test)

  @impl Mix.Task
  def run(args) do
    options = parse!(args)
    plans = plan_all(options.paths)
    pending = pending(plans)

    report(plans)
    finish(options, pending)

    :ok
  end

  defp parse!(args) do
    {options, _positional} =
      OptionParser.parse!(args, strict: [write: :boolean, check: :boolean, paths: :keep])

    %{write: options[:write] == true, check: options[:check] == true, paths: paths(options)}
  end

  # `--paths` may be given more than once; a path may itself contain a comma.
  defp paths(options) do
    case Keyword.get_values(options, :paths) do
      [] -> @default_paths
      given -> given
    end
  end

  defp plan_all(paths) do
    sources =
      paths
      |> Enum.flat_map(&files_in/1)
      |> Enum.map(fn file ->
        case File.read(file) do
          {:ok, source} -> {file, {:ok, source}}
          {:error, reason} -> {file, {:unreadable, reason}}
        end
      end)

    # A call may target a module in another file, so every file is read once to
    # learn what the project converts before anything is planned.
    converted =
      sources
      |> Enum.flat_map(fn
        {_file, {:ok, source}} -> [VirtualTimeMigrate.converted_modules(source)]
        {_file, _error} -> []
      end)
      |> Enum.reduce(MapSet.new(), &MapSet.union/2)

    Enum.map(sources, fn
      {file, {:ok, source}} ->
        case VirtualTimeMigrate.plan(source, converted) do
          {:ok, plan} -> {file, plan}
          {:error, _reason} -> {file, :unparsable}
        end

      {file, error} ->
        {file, error}
    end)
  end

  defp files_in(path) do
    cond do
      File.dir?(path) -> Path.wildcard(Path.join(path, "**/*.{ex,exs}")) |> Enum.sort()
      File.regular?(path) -> [path]
      true -> []
    end
  end

  defp report(plans), do: Enum.each(plans, &report_plan/1)

  defp report_plan({file, plan}) when is_map(plan) do
    if plan.edits != [] or plan.notes != [] do
      IO.puts("\n#{file}")
      Enum.each(plan.edits, &IO.puts("  line #{&1.line}: #{&1.change}"))
      Enum.each(plan.notes, &IO.puts("  line #{&1.line}: #{&1.message}"))
    end
  end

  defp report_plan({file, :unparsable}), do: IO.puts("\n#{file}: could not parse — skipped")

  defp report_plan({file, {:unreadable, reason}}),
    do: IO.puts("\n#{file}: could not read (#{reason}) — skipped")

  defp finish(%{write: true}, pending) when pending != [], do: write(pending)

  defp finish(%{check: true}, pending) when pending != [], do: exit({:shutdown, 1})

  defp finish(_options, []),
    do: IO.puts("Nothing to migrate: every GenServer here is already a virtual-time server.")

  defp finish(_options, pending),
    do: IO.puts("\n#{length(pending)} file(s) would change. Re-run with --write to apply.")

  defp write(pending) do
    Enum.each(pending, &write_plan/1)
    IO.puts("Wrote #{length(pending)} file(s).")
  end

  defp write_plan({file, plan}) do
    source = File.read!(file)
    updated = VirtualTimeMigrate.apply_edits(source, plan.edits)

    case Code.string_to_quoted(updated) do
      {:ok, _ast} ->
        File.write!(file, updated)

      {:error, error} ->
        Mix.raise(
          "Refusing to write #{file}: the rewrite would not parse (#{inspect(error)}). Please report this."
        )
    end
  end

  defp pending(plans),
    do: Enum.filter(plans, fn {_file, plan} -> is_map(plan) and plan.edits != [] end)
end
