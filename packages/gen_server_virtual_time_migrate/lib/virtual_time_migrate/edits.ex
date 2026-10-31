defmodule VirtualTimeMigrate.Edits do
  @moduledoc """
  The editable unit of a planned rewrite: a token at a line and column.

  Two rewrites need this — moving `GenServer` code onto the virtual clock
  (`VirtualTimeMigrate`) and moving a project off the deprecated module names
  (`VirtualTimeUpgrade`) — so the machinery for collecting, checking and applying
  the edits lives here rather than in either of them.

  Every edit carries the exact source text it expects to find at its position and
  is checked against the source before it joins the plan, so a plan can never be
  applied to text it does not describe.
  """

  @typedoc """
  One replacement: `from` is the exact source text at `column` on `line`, and
  `to` is what replaces it.
  """
  @type edit :: %{
          line: pos_integer(),
          column: pos_integer(),
          from: String.t(),
          to: String.t(),
          change: String.t()
        }

  @typedoc "Something the rewrite noticed but leaves alone."
  @type note :: %{line: pos_integer(), message: String.t()}

  @type plan :: %{edits: [edit], notes: [note]}

  @opaque state :: %{
            edits: [edit],
            notes: [note],
            lines: tuple()
          }

  @doc "Starts collecting edits for `source`."
  @spec new(String.t()) :: state
  def new(source) do
    %{edits: [], notes: [], lines: source |> String.split("\n") |> List.to_tuple()}
  end

  @doc """
  Records that `from`, at `meta`'s position, becomes `to`.

  `change` is what the report prints. If the source does not have `from` there, a
  note is recorded instead: a wrong position is a bug in the plan, and a note is
  how it becomes visible rather than a silently mis-edited file.
  """
  @spec add(state, keyword, String.t(), String.t(), String.t()) :: state
  def add(state, meta, from, to, change) do
    line = Keyword.fetch!(meta, :line)
    column = Keyword.fetch!(meta, :column)

    if anchored?(state.lines, line, column, from) do
      %{
        state
        | edits: [%{line: line, column: column, from: from, to: to, change: change} | state.edits]
      }
    else
      note(state, meta, "expected `#{from}` at line #{line}, column #{column} — left alone")
    end
  end

  @doc "Records something worth telling the human about, without rewriting it."
  @spec note(state, keyword, String.t()) :: state
  def note(state, meta, message) do
    %{state | notes: [%{line: Keyword.fetch!(meta, :line), message: message} | state.notes]}
  end

  @doc "The plan, in source order."
  @spec to_plan(state) :: plan
  def to_plan(state), do: %{edits: Enum.reverse(state.edits), notes: Enum.reverse(state.notes)}

  @doc """
  Applies a plan to the source it was planned from.

  Edits are applied right to left within a line, so an earlier replacement never
  moves a later one.
  """
  @spec apply(String.t(), [edit]) :: String.t()
  def apply(source, edits) do
    edits_by_line = Enum.group_by(edits, & &1.line)

    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {line, number} ->
      replace_in_line(line, Map.get(edits_by_line, number, []))
    end)
  end

  defp anchored?(lines, line, column, from) do
    case elem(lines, line - 1) do
      nil -> false
      text -> text |> String.slice(column - 1, String.length(text)) |> String.starts_with?(from)
    end
  end

  defp replace_in_line(line, []), do: line

  defp replace_in_line(line, edits) do
    edits
    |> Enum.sort_by(& &1.column, :desc)
    |> Enum.reduce(line, fn %{column: column, from: from, to: to}, acc ->
      prefix = String.slice(acc, 0, column - 1)
      rest = String.slice(acc, column - 1, String.length(acc))

      if String.starts_with?(rest, from) do
        prefix <> to <> String.slice(rest, String.length(from)..-1//1)
      else
        acc
      end
    end)
  end
end
