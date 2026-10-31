defmodule VirtualTimeMigrate.Project do
  @moduledoc """
  The part of both rewrite tasks that is the same: walk a tree, plan each file,
  report, and write only what still parses.

  `virtual_time.migrate` (GenServer → virtual-time GenServer) and
  `virtual_time.upgrade` (deprecated module names → their replacements) differ
  only in their planner, so the walking and the writing live here once.
  """

  alias VirtualTimeMigrate.Edits

  @default_paths ~w(lib test)

  @type path :: String.t()

  @doc "The paths to plan, from the `--paths` flags or the defaults."
  @spec paths([String.t()]) :: [path]
  def paths(nil), do: @default_paths
  def paths(given), do: given

  @doc """
  Plans every `.ex`/`.exs` file under `paths`.

  `planner.(source, converted)` returns `{:ok, plan}` or `{:error, reason}`; the
  second argument is the set of module names the whole tree converts, which only
  the GenServer rewrite needs.

  Returns `[{file, plan}]`, `[{file, :unparsable}]` or `[{file, {:unreadable, reason}}]`.
  """
  @spec plan([path], (String.t(), MapSet.t(String.t()) -> {:ok, Edits.plan()} | {:error, term})) ::
          [{path, Edits.plan() | :unparsable | {:unreadable, term}}]
  def plan(paths, planner) do
    sources =
      paths
      |> Enum.flat_map(&files_in/1)
      |> Enum.map(fn file ->
        case File.read(file) do
          {:ok, source} -> {file, {:ok, source}}
          {:error, reason} -> {file, {:unreadable, reason}}
        end
      end)

    converted =
      sources
      |> Enum.flat_map(fn
        {_file, {:ok, source}} -> [converted_modules(source)]
        {_file, _error} -> []
      end)
      |> Enum.reduce(MapSet.new(), &MapSet.union/2)

    Enum.map(sources, fn
      {file, {:ok, source}} ->
        case planner.(source, converted) do
          {:ok, plan} -> {file, plan}
          {:error, _reason} -> {file, :unparsable}
        end

      {file, error} ->
        {file, error}
    end)
  end

  @doc "Prints one section per file that has something to say."
  @spec report([{path, term}]) :: :ok
  def report(plans), do: Enum.each(plans, &report_plan/1)

  @doc "The files whose plan would change something."
  @spec pending([{path, term}]) :: [{path, Edits.plan()}]
  def pending(plans),
    do: Enum.filter(plans, fn {_file, plan} -> is_map(plan) and plan.edits != [] end)

  @doc """
  Writes every pending plan, refusing to write one that would not parse.

  A rewrite that breaks the syntax is a bug in the planner; aborting the whole
  run keeps the tree compilable and makes the bug visible.
  """
  @spec write([{path, Edits.plan()}]) :: :ok
  def write(pending) do
    Enum.each(pending, &write_plan/1)
    IO.puts("Wrote #{length(pending)} file(s).")
  end

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

  defp write_plan({file, plan}) do
    source = File.read!(file)
    updated = Edits.apply(source, plan.edits)

    case Code.string_to_quoted(updated) do
      {:ok, _ast} ->
        File.write!(file, updated)

      {:error, error} ->
        Mix.raise(
          "Refusing to write #{file}: the rewrite would not parse (#{inspect(error)}). Please report this."
        )
    end
  end

  defp files_in(path) do
    cond do
      File.dir?(path) -> Path.wildcard(Path.join(path, "**/*.{ex,exs}")) |> Enum.sort()
      File.regular?(path) -> [path]
      true -> []
    end
  end

  defp converted_modules(source), do: VirtualTimeMigrate.converted_modules(source)
end
