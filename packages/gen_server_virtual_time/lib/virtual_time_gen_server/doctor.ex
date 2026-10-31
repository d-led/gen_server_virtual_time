defmodule VirtualTimeGenServer.Doctor do
  @moduledoc """
  Turns a project's module references into the dependency lines it is missing.

  The library is published as a family of packages that share one version, and a
  module keeps its name when it moves to another package. So the fix for a
  missing module is a line in `mix.exs`, not a change to the code — and this
  module works out which line.

  `mix virtual_time.doctor` drives it; the parts are pure so they can be
  specified directly.
  """

  alias VirtualTimeGenServer.Packages

  @typedoc """
  A reference the project has to act on: either a module that lives in a package
  the project does not have, or a call that was removed and has a replacement.
  """
  @type finding ::
          %{
            kind: :missing_package,
            module: String.t(),
            function: String.t() | nil,
            file: Path.t(),
            line: pos_integer(),
            package: Packages.package(),
            dependency: String.t()
          }
          | %{
              kind: :removed_api,
              module: String.t(),
              function: String.t() | nil,
              file: Path.t(),
              line: pos_integer(),
              replacement: String.t()
            }

  @doc """
  Reports what a project has to change, given its references and a way to ask
  whether a module is available in the current build.

  A module that is available is not a finding: the doctor only speaks about
  problems. Availability — not the declared dependencies — is what it checks, so
  a package that arrives indirectly is not reported either.
  """
  @spec diagnose([VirtualTimeGenServer.ModuleReferences.module_reference()], (String.t() ->
                                                                                boolean)) ::
          [finding]
  def diagnose(references, available?) do
    references
    |> Enum.map(&diagnose_reference(&1, available?))
    |> Enum.reject(&is_nil/1)
  end

  defp diagnose_reference(%{module: module, function: function} = reference, available?) do
    case Packages.removed_api(module, function) do
      nil -> missing_package(reference, module, available?)
      replacement -> Map.merge(reference, %{kind: :removed_api, replacement: replacement})
    end
  end

  defp missing_package(reference, module, available?) do
    with package when not is_nil(package) <- Packages.owner(module),
         false <- available?.(module) do
      Map.merge(reference, %{
        kind: :missing_package,
        package: package,
        dependency: Packages.dependency(package)
      })
    else
      _available -> nil
    end
  end

  @doc "The dependencies a project has to add, one per package, in report order."
  @spec missing_dependencies([finding]) :: [String.t()]
  def missing_dependencies(findings) do
    findings
    |> Enum.filter(&(&1.kind == :missing_package))
    |> Enum.map(& &1.dependency)
    |> Enum.uniq()
  end

  @doc "The report as a project maintainer reads it."
  @spec format([finding]) :: String.t()
  def format([]), do: "Nothing to do: every module you reference is available.\n"

  def format(findings) do
    findings
    |> Enum.split_with(&(&1.kind == :missing_package))
    |> then(fn {missing, removed} ->
      [format_missing_packages(missing), format_removed_apis(removed)]
    end)
    |> IO.iodata_to_binary()
  end

  defp format_missing_packages([]), do: []

  defp format_missing_packages(findings) do
    [
      "\nThe code refers to modules this project does not have.\n",
      "\nAdd to your deps:\n\n",
      Enum.map(missing_dependencies(findings), &"    #{&1}\n"),
      "\nNo code changes are needed — a module keeps its name when it changes\n",
      "package. Then run `mix deps.get`.\n\n",
      "Where they are used:\n",
      Enum.map(findings, &format_location/1)
    ]
  end

  defp format_removed_apis([]), do: []

  defp format_removed_apis(findings) do
    [
      "\nThe code calls functions that were removed.\n",
      "\nWhat to write instead:\n\n",
      Enum.map(findings, fn finding ->
        "    #{location(finding)}: #{call(finding)}\n" <>
          "      └─ #{finding.replacement}\n"
      end)
    ]
  end

  defp format_location(finding) do
    "    #{location(finding)}: #{call(finding)}  →  #{finding.dependency}\n"
  end

  defp location(finding), do: "#{finding.file}:#{finding.line}"

  defp call(%{module: module, function: nil}), do: "%#{module}{}"

  defp call(%{module: module, function: function}), do: "#{module}.#{function}"
end
