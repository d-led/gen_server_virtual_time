defmodule VirtualTimeUpgrade do
  @moduledoc """
  Plans the move off the deprecated code-generator module names.

  `ActorSimulation.CAFGenerator` and its five siblings became
  `ActorSimulation.Codegen.*` in 1.1. The old names still work — they forward to
  the new ones and warn — so this task is a convenience: it turns the warnings
  into silence, and it never guesses.

  What it rewrites:

    * a fully qualified reference, `ActorSimulation.CAFGenerator.generate(...)`;
    * `alias ActorSimulation.CAFGenerator` together with the bare
      `CAFGenerator.foo()` calls that follow it in the same file — but only when
      the name it would introduce, `CAF`, is not already used there.

  What it leaves alone, and reports:

    * an alias with `as:`, which may be renamed to anything;
    * a file where the new short name is already in use, because then the two
      names would collide;
    * a bare short name no alias introduced: it may come from anywhere.
  """

  alias VirtualTimeMigrate.Edits

  @renames %{
    "ActorSimulation.CAFGenerator" => "ActorSimulation.Codegen.CAF",
    "ActorSimulation.OMNeTPPGenerator" => "ActorSimulation.Codegen.OMNeTPP",
    "ActorSimulation.PhonyGenerator" => "ActorSimulation.Codegen.Phony",
    "ActorSimulation.PonyGenerator" => "ActorSimulation.Codegen.Pony",
    "ActorSimulation.RactorGenerator" => "ActorSimulation.Codegen.Ractor",
    "ActorSimulation.VlingoGenerator" => "ActorSimulation.Codegen.Vlingo"
  }

  @doc "The modules this task knows how to rename: old name → new name."
  @spec renames() :: %{String.t() => String.t()}
  def renames, do: @renames

  @doc """
  Plans the upgrade of one file's source.

  Returns `{:error, reason}` when the source does not parse, so the caller can
  report the file and carry on.
  """
  @spec plan(String.t()) :: {:ok, Edits.plan()} | {:error, term}
  def plan(source) do
    with {:ok, ast} <- Code.string_to_quoted(source, columns: true) do
      aliased = aliases(ast)

      {:ok, Edits.new(source) |> collect(ast, aliased) |> Edits.to_plan()}
    end
  end

  # `alias ActorSimulation.CAFGenerator` makes the short name `CAFGenerator` mean
  # that module for the rest of the file, so the alias and the short name have to
  # move together. A short name only moves when the name it becomes is free.
  defp aliases(ast) do
    {_ast, found} =
      Macro.prewalk(ast, %{renamable: %{}, used: MapSet.new()}, fn
        {:alias, _meta, [{:__aliases__, _, parts}]} = node, acc ->
          short = short_of(Enum.join(parts, "."))
          acc = %{acc | used: MapSet.put(acc.used, short)}

          case Map.fetch(@renames, Enum.join(parts, ".")) do
            {:ok, new_name} ->
              {node, %{acc | renamable: Map.put(acc.renamable, short, short_of(new_name))}}

            :error ->
              {node, acc}
          end

        {:__aliases__, _meta, parts} = node, acc ->
          {node, %{acc | used: MapSet.put(acc.used, short_of(Enum.join(parts, ".")))}}

        node, acc ->
          {node, acc}
      end)

    renamable = Map.reject(found.renamable, fn {_old, new} -> MapSet.member?(found.used, new) end)
    %{renamable: renamable, blocked: Map.drop(found.renamable, Map.keys(renamable))}
  end

  defp collect(state, {:alias, alias_meta, [{:__aliases__, meta, parts}]}, aliased) do
    name = Enum.join(parts, ".")
    short = short_of(name)

    cond do
      not Map.has_key?(@renames, name) ->
        state

      Map.has_key?(aliased.blocked, short) ->
        Edits.note(
          state,
          alias_meta,
          "#{short} would have to become #{aliased.blocked[short]}, which is already in use " <>
            "here — left alone"
        )

      true ->
        Edits.add(state, meta, name, @renames[name], "alias #{name}")
    end
  end

  # `alias X, as: Y` renames the module to whatever the author chose, so the short
  # name cannot be inferred and nothing is rewritten.
  defp collect(state, {:alias, alias_meta, [{:__aliases__, _, parts} | _opts]}, _aliased) do
    name = Enum.join(parts, ".")

    if Map.has_key?(@renames, name) do
      Edits.note(state, alias_meta, "alias #{name} with `as:` — rename it by hand")
    else
      state
    end
  end

  # A fully qualified use, or the bare short name an alias introduced.
  defp collect(state, {:__aliases__, meta, parts}, aliased) do
    name = Enum.join(parts, ".")
    short = short_of(name)

    cond do
      Map.has_key?(@renames, name) ->
        Edits.add(state, meta, name, @renames[name], name)

      Map.has_key?(aliased.renamable, short) ->
        new_short = aliased.renamable[short]
        Edits.add(state, meta, short, new_short, "#{short} → #{new_short} (aliased)")

      true ->
        state
    end
  end

  defp collect(state, {form, _meta, args}, aliased) when is_list(args) do
    # In a remote call the module sits in the callee (`{{:., _, [alias, fun]}, _, args}`),
    # not in `args`, so the callee is walked too.
    state
    |> collect(form, aliased)
    |> then(fn acc -> Enum.reduce(args, acc, &collect(&2, &1, aliased)) end)
  end

  # Function bodies and branches hang off `do:`/`else:` pairs.
  defp collect(state, {_key, value}, aliased), do: collect(state, value, aliased)

  defp collect(state, list, aliased) when is_list(list) do
    Enum.reduce(list, state, &collect(&2, &1, aliased))
  end

  defp collect(state, _leaf, _aliased), do: state

  defp short_of(dotted), do: dotted |> String.split(".") |> List.last()
end
