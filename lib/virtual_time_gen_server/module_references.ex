defmodule VirtualTimeGenServer.ModuleReferences do
  @moduledoc """
  Finds the modules a source tree refers to.

  Reads `.ex` and `.exs` files and reports every remote call and struct literal
  with the module it names, the function it calls and where it appears. Files
  that do not parse are reported instead of failing the run: a project that does
  not compile is exactly when this is useful.
  """

  @type module_reference :: %{
          module: String.t(),
          function: String.t() | nil,
          file: Path.t(),
          line: pos_integer()
        }

  @type result :: %{references: [module_reference], unparsable: [Path.t()]}

  @doc """
  Scans every file below each path (or the file itself) and collects its
  references, in source order.
  """
  @spec scan([Path.t()]) :: result
  def scan(paths) do
    paths
    |> Enum.flat_map(&files_in/1)
    |> Enum.reduce(%{references: [], unparsable: []}, &scan_file/2)
  end

  defp files_in(path) do
    cond do
      File.dir?(path) -> Path.wildcard(Path.join(path, "**/*.{ex,exs}")) |> Enum.sort()
      File.regular?(path) -> [path]
      true -> []
    end
  end

  defp scan_file(file, result) do
    case parse(file) do
      {:ok, ast} -> %{result | references: result.references ++ references_in(ast, file)}
      :error -> %{result | unparsable: result.unparsable ++ [file]}
    end
  end

  defp parse(file) do
    with {:ok, source} <- File.read(file),
         {:ok, ast} <- Code.string_to_quoted(source) do
      {:ok, ast}
    else
      _ -> :error
    end
  end

  # `Module.function(...)` and the function name in `&Module.function/1`.
  defp references_in(ast, file) do
    {_ast, references} =
      Macro.prewalk(ast, [], fn
        {{:., _dot, [{:__aliases__, alias_meta, parts}, function]}, _call, _arguments} = node, acc
        when is_atom(function) ->
          {node, [reference(parts, function, alias_meta, file) | acc]}

        # `%Module{}`
        {:%, _meta, [{:__aliases__, alias_meta, parts}, _fields]} = node, acc ->
          {node, [reference(parts, nil, alias_meta, file) | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(references)
  end

  defp reference(parts, function, alias_meta, file) do
    %{
      module: Enum.join(parts, "."),
      function: function && Atom.to_string(function),
      file: file,
      line: Keyword.get(alias_meta, :line, 1)
    }
  end
end
