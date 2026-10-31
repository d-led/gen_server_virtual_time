defmodule VirtualTimeMigrate do
  @moduledoc """
  Works out how to turn `GenServer` modules into their virtual-time equivalents.

  It is a planner, not a formatter: it reads a file, decides which tokens to
  replace and where, and hands the plan back. `mix virtual_time.migrate` decides
  whether to print that plan or apply it.

  The plan is deliberately conservative — a call is only rewritten when the
  change provably means the same thing:

    * `use GenServer` becomes `use VirtualTimeGenServer`, options untouched
      (`use GenStateMachine` → `use VirtualTimeGenStateMachine`);
    * inside a converted module, `Process.send_after/3`, `Process.sleep/1`,
      `:erlang.send_after/3` and `:timer.sleep/1` become `VirtualTimeGenServer`
      calls, because that is what puts the module on the virtual clock;
    * `GenServer.call/cast/stop/reply/start_link/start/child_spec` is rewritten
      only when its target is a literal module that is converted somewhere in the
      project, or `__MODULE__` inside a converted module.

  Anything else — a pid, a variable, a module that stays a plain `GenServer` — is
  left alone, and reported when the caller is a converted module and the tool
  cannot tell.

  Every edit carries the exact source text it expects to find at its position,
  and is checked against the source before it joins the plan, so a plan can never
  be applied to text it does not describe.
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

  @typedoc "Something the migration noticed but does not rewrite."
  @type note :: %{line: pos_integer(), message: String.t()}

  @type plan :: %{edits: [edit], notes: [note]}

  @declarations %{
    "GenServer" => "VirtualTimeGenServer",
    "GenStateMachine" => "VirtualTimeGenStateMachine"
  }

  @server_calls ~w(call cast stop reply start_link start child_spec)
  @process_calls ~w(send_after sleep)

  @doc """
  Plans the migration of one file's source.

  `known_converted` is the set of module names the rest of the project converts
  (see `converted_modules/1`), so a call into another file can be recognised.
  The modules this file converts are added to it.

  Returns `{:error, reason}` when the source does not parse — the caller reports
  that file and carries on with the others.
  """
  @spec plan(String.t(), MapSet.t(String.t()) | nil) :: {:ok, plan} | {:error, term}
  def plan(source, known_converted \\ nil) do
    with {:ok, ast} <- Code.string_to_quoted(source, columns: true) do
      converted =
        case known_converted do
          nil -> converted_modules(source)
          known -> MapSet.union(known, converted_modules(source))
        end

      {:ok, ast |> collect(converted, lines(source)) |> to_plan()}
    end
  end

  @doc """
  Applies a plan to the source it was planned from.

  Edits are applied right to left within a line, so an earlier replacement never
  moves a later one.
  """
  @spec apply_edits(String.t(), [edit]) :: String.t()
  def apply_edits(source, edits) do
    edits_by_line = Enum.group_by(edits, & &1.line)

    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {line, number} ->
      replace_in_line(line, Map.get(edits_by_line, number, []))
    end)
  end

  @doc """
  The modules a source (or an AST) converts, as dotted names.
  """
  @spec converted_modules(Macro.t() | String.t()) :: MapSet.t(String.t())
  def converted_modules(source) when is_binary(source) do
    case Code.string_to_quoted(source) do
      {:ok, ast} -> converted_modules(ast)
      {:error, _reason} -> MapSet.new()
    end
  end

  def converted_modules(ast) do
    {_ast, names} =
      Macro.prewalk(ast, [], fn
        {:defmodule, _meta, [{:__aliases__, _, parts}, [do: body]]} = node, acc ->
          uses = body |> block() |> Enum.any?(&declaration?/1)
          {node, if(uses, do: [dotted(parts) | acc], else: acc)}

        node, acc ->
          {node, acc}
      end)

    MapSet.new(names)
  end

  defp lines(source), do: source |> String.split("\n") |> List.to_tuple()

  defp to_plan(state), do: %{edits: Enum.reverse(state.edits), notes: Enum.reverse(state.notes)}

  defp block({:__block__, _meta, forms}) when is_list(forms), do: forms
  defp block(body) when is_list(body), do: body
  defp block(body), do: [body]

  defp declaration?({:use, _meta, [{:__aliases__, _, parts} | _]}),
    do: Map.has_key?(@declarations, dotted(parts))

  defp declaration?(_other), do: false

  defp collect(ast, converted, lines) do
    walk(%{edits: [], notes: [], lines: lines}, ast, nil, converted)
  end

  # The enclosing module is carried down, because a conversion is only safe
  # inside a module that is itself converted.
  defp walk(
         state,
         {:defmodule, _meta, [{:__aliases__, _, parts}, [do: body]]},
         _enclosing,
         converted
       ) do
    walk(state, body, dotted(parts), converted)
  end

  defp walk(state, {form, meta, args}, enclosing, converted) when is_list(args) do
    node = {form, meta, args}

    state
    |> declaration_edit(node)
    |> then(&walk_call(&1, node, enclosing, converted))
    |> then(fn state -> Enum.reduce(args, state, &walk(&2, &1, enclosing, converted)) end)
  end

  # Function bodies and `case`/`cond` branches hang off `do:`/`else:` pairs.
  defp walk(state, {_key, value}, enclosing, converted) do
    walk(state, value, enclosing, converted)
  end

  defp walk(state, list, enclosing, converted) when is_list(list) do
    Enum.reduce(list, state, &walk(&2, &1, enclosing, converted))
  end

  defp walk(state, _leaf, _enclosing, _converted), do: state

  # `use GenServer` — the declaration itself, whatever options it carries.
  defp declaration_edit(state, {:use, _meta, [{:__aliases__, alias_meta, parts} | _rest]}) do
    name = dotted(parts)

    case Map.fetch(@declarations, name) do
      {:ok, replacement} -> add_edit(state, alias_meta, token(parts), replacement, "use #{name}")
      :error -> state
    end
  end

  defp declaration_edit(state, _node), do: state

  defp walk_call(state, node, enclosing, converted) do
    with {:ok, %{name: name, token: token, function: function, args: args, meta: meta}} <-
           remote_call(node),
         true <- enclosing in converted do
      rewrite(state, {name, token, function, args, meta}, converted)
    else
      _other -> state
    end
  end

  defp rewrite(state, {"GenServer", "GenServer", function, args, meta}, converted)
       when function in @server_calls do
    server_call(state, meta, function, args, converted)
  end

  defp rewrite(state, {module, token, function, _args, meta}, _converted)
       when module in ["Process", "erlang"] and function in @process_calls do
    add_edit(state, meta, token, "VirtualTimeGenServer", "#{token}.#{function}")
  end

  defp rewrite(state, {"timer", ":timer", "sleep", _args, meta}, _converted) do
    add_edit(state, meta, ":timer", "VirtualTimeGenServer", ":timer.sleep")
  end

  defp rewrite(state, _call, _converted), do: state

  # `GenServer.call(MyApp.Counter, :get)` may become a virtual-time call, but only
  # when we can see the target: a literal converted module, or `__MODULE__`.
  defp server_call(state, meta, function, [target | _rest], converted) do
    case target_of(target) do
      {:module, name} ->
        if MapSet.member?(converted, name) do
          add_edit(
            state,
            meta,
            "GenServer",
            "VirtualTimeGenServer",
            "GenServer.#{function} to #{name}"
          )
        else
          state
        end

      :self ->
        add_edit(
          state,
          meta,
          "GenServer",
          "VirtualTimeGenServer",
          "GenServer.#{function} on __MODULE__"
        )

      :unknown ->
        note(
          state,
          meta,
          "GenServer.#{function} on a target that is not a literal module — left alone"
        )
    end
  end

  defp target_of({:__aliases__, _, parts}), do: {:module, dotted(parts)}
  defp target_of({:__MODULE__, _, _}), do: :self
  defp target_of(_other), do: :unknown

  # `{remote, meta, args}` plus the module the call goes to, when it is literal.
  defp remote_call({{:., dot_meta, [module, function]}, _call_meta, args}) when is_list(args) do
    with {:ok, name, token, meta} <- module_of(module, dot_meta) do
      {:ok,
       %{name: name, token: token, function: Atom.to_string(function), args: args, meta: meta}}
    end
  end

  defp remote_call(_other), do: :error

  defp module_of({:__aliases__, meta, parts}, _dot_meta),
    do: {:ok, dotted(parts), token(parts), meta}

  # `:erlang.send_after/3` is a remote call on an atom, and the only position the
  # parser gives is the dot — the module token sits just before it.
  defp module_of(atom, dot_meta) when is_atom(atom) do
    token = ":" <> Atom.to_string(atom)
    meta = Keyword.update!(dot_meta, :column, &(&1 - String.length(token)))
    {:ok, Atom.to_string(atom), token, meta}
  end

  defp module_of(_other, _dot_meta), do: :error

  defp add_edit(state, meta, from, to, change) do
    line = Keyword.fetch!(meta, :line)
    column = Keyword.fetch!(meta, :column)

    if anchored?(state.lines, line, column, from) do
      edit = %{line: line, column: column, from: from, to: to, change: change}
      %{state | edits: [edit | state.edits]}
    else
      note(state, meta, "expected `#{from}` at line #{line}, column #{column} — left alone")
    end
  end

  defp anchored?(lines, line, column, from) do
    case elem(lines, line - 1) do
      nil -> false
      text -> text |> String.slice(column - 1, String.length(text)) |> String.starts_with?(from)
    end
  end

  defp note(state, meta, message) do
    %{state | notes: [%{line: Keyword.fetch!(meta, :line), message: message} | state.notes]}
  end

  # Right to left, so an earlier replacement does not move a later one.
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

  defp dotted(parts), do: Enum.join(parts, ".")

  # What the module token looks like in the source: `Process`, `:erlang`, or a
  # dotted alias — the AST stores both alias and atom forms as `__aliases__`.
  defp token([single]) when is_atom(single) do
    text = Atom.to_string(single)
    if Regex.match?(~r/^[A-Z]/, text), do: text, else: ":" <> text
  end

  defp token(parts), do: dotted(parts)
end
