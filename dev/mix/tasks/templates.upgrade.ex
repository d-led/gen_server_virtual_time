defmodule Mix.Tasks.Templates.Upgrade do
  @shortdoc "Checks and upgrades the versions the code generators pin"

  @moduledoc """
  Keeps the third-party versions in the generated-project templates current.

  The generators pin versions (Conan packages, crates, Maven artifacts, GitHub
  Actions, the Go module of the Phony actor library) in
  `ActorSimulation.TemplateVersions`. Left alone, those pins rot silently: a
  generated project can be years behind the frameworks it claims to use.

  This task asks each upstream for its latest release and reports the drift.

      $ mix templates.upgrade --check

  and, unless `--check` is given, rewrites the table:

      $ mix templates.upgrade

  ## Options

    * `--check` — report only; exits non-zero when any pin is behind
    * `--examples` — after upgrading, regenerate the checked-in `examples/` and
      `generated/` projects by running the `scripts/generate_*.exs` scripts
    * `--offline` — skip upstream lookups and only report the table

  Versions that have no meaningful upstream (a language level, a minimum CMake,
  a floating `ponyup` channel) are marked `:manual` in
  `ActorSimulation.TemplateVersions.sources/0`, and are reported but never
  rewritten.

  ## GitHub rate limits

  Anonymous GitHub API requests are limited to 60 per hour, and this task makes
  about a dozen of them. Export `GH_TOKEN` (or `GITHUB_TOKEN`) to raise the
  limit:

      $ GH_TOKEN=$(gh auth token) mix templates.upgrade --check

  ## Example output

      caF             1.0.2   -> 1.1.0    conan center: caf
      checkout_action v7      -> v7       up to date
      cmake_minimum   3.15               manual: minimum CMake the templates require

  """

  use Mix.Task

  @requirements ["compile"]

  alias ActorSimulation.TemplateVersions, as: Versions
  alias ActorSimulation.TemplateVersions.Upgrade
  alias Mix.Tasks.Templates.Upgrade.Http

  @impl Mix.Task
  def run(args), do: run(args, &Http.get/1, Upgrade.module_path())

  @doc """
  Runs the task against `fetch`, the table kept in `path`, and `run_script` for
  regenerating the checked-in examples.

  Mix calls `run/1`; this arity exists so the task can be exercised without the
  network, without rewriting the real table, and without rebuilding examples.
  """
  def run(args, fetch, path, run_script \\ &run_script/1) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [check: :boolean, examples: :boolean, offline: :boolean],
        aliases: [c: :check]
      )

    plan = build_plan(opts, fetch)

    report(plan)

    if opts[:check] do
      check(plan, path)
    else
      write_plan(plan, path)
    end

    if opts[:examples], do: regenerate_examples(run_script)
  end

  defp build_plan(opts, fetch) do
    if opts[:offline] do
      Upgrade.plan(fn _url -> {:error, :offline} end)
    else
      Upgrade.plan(fetch)
    end
  end

  defp check(plan, path) do
    if Upgrade.drift?(plan) do
      Mix.raise("""

      #{Enum.count(plan, &(&1.status == :update))} template version(s) are out of date.

      Run `mix templates.upgrade` to update
      #{path}, then
      `mix templates.upgrade --examples` to regenerate the checked-in projects.
      """)
    else
      Mix.shell().info("\nTemplates are up to date.")
    end
  end

  defp write_plan(plan, path) do
    source = File.read!(path)
    updated = Upgrade.rewrite(source, Upgrade.apply_plan(plan))

    if updated == source do
      Mix.shell().info("\nNothing to write; #{path} is already current.")
    else
      File.write!(path, updated)
      Mix.shell().info("\nUpdated #{path}. Run `mix format` and the test suite.")
    end
  end

  defp regenerate_examples(run_script) do
    scripts = ~w(
      generate_omnetpp_examples
      generate_caf_examples
      generate_pony_examples
      generate_phony_examples
      generate_ractor_examples
      generate_vlingo_sample
    )

    Enum.each(scripts, fn script ->
      Mix.shell().info("\n$ mix run scripts/#{script}.exs")

      case run_script.(script) do
        0 -> :ok
        status -> Mix.raise("scripts/#{script}.exs exited with #{status}")
      end
    end)

    Mix.shell().info("\nRegenerated the checked-in example projects.")
  end

  defp run_script(script) do
    {output, status} = System.cmd("mix", ["run", "scripts/#{script}.exs"], stderr_to_stdout: true)
    Mix.shell().info(output)
    status
  end

  defp report(plan) do
    columns = %{
      key: width(plan, &label(&1.key)),
      current: width(plan, & &1.current),
      latest: width(plan, &(latest(&1) || "—"))
    }

    heading = line(["key", "current", "latest", "upstream"], columns)
    rows = Enum.map_join(plan, "\n", &line(entry_cells(&1), columns))

    Mix.shell().info("""
    Template versions (#{Upgrade.module_path()})

    #{heading}
    #{String.duplicate("─", 100)}
    #{rows}
    """)
  end

  defp entry_cells(entry),
    do: [label(entry.key), entry.current, latest(entry) || "—", comment(entry)]

  defp line(cells, columns) do
    cells
    |> Enum.zip([columns.key, columns.current, columns.latest, nil])
    |> Enum.map_join("  ", fn
      {cell, nil} -> cell
      {cell, width} -> String.pad_trailing(cell, width)
    end)
  end

  defp width(plan, value_of),
    do: plan |> Enum.map(value_of) |> Enum.max_by(&String.length/1) |> String.length()

  defp latest(%{status: :update, latest: latest}), do: latest
  defp latest(_entry), do: nil

  defp comment(%{status: :update, source: source}), do: Versions.describe(source)
  defp comment(%{status: :manual, note: note}), do: note

  # Say where the version would have come from, and then why it did not: a
  # maintainer reading an unresolved row needs both.
  defp comment(%{status: :unresolved, source: source, note: note}) do
    "#{Versions.describe(source)} — #{note}"
  end

  defp comment(_up_to_date_entry), do: ""

  defp label(key), do: Atom.to_string(key)
end
