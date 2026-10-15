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

  # :httpc and :public_key are only needed by this maintainer task, so the library
  # itself does not declare the :inets, :ssl and :public_key applications. Both
  # ship with OTP.
  @compile {:no_warn_undefined, [:httpc, :public_key]}

  @requirements ["compile"]

  alias ActorSimulation.TemplateVersions, as: Versions
  alias ActorSimulation.TemplateVersions.Upgrade

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [check: :boolean, examples: :boolean, offline: :boolean],
        aliases: [c: :check]
      )

    plan = build_plan(opts)

    report(plan)

    if opts[:check] do
      check(plan)
    else
      write_plan(plan)
    end

    if opts[:examples], do: regenerate_examples()
  end

  defp build_plan(offline: true), do: Upgrade.plan(fn _url -> {:error, :offline} end)
  defp build_plan(_opts), do: Upgrade.plan(&http_fetch/1)

  defp check(plan) do
    if Upgrade.drift?(plan) do
      Mix.raise("""

      #{Enum.count(plan, &(&1.status == :update))} template version(s) are out of date.

      Run `mix templates.upgrade` to update
      #{Upgrade.module_path()}, then
      `mix templates.upgrade --examples` to regenerate the checked-in projects.
      """)
    else
      Mix.shell().info("\nTemplates are up to date.")
    end
  end

  defp write_plan(plan) do
    path = Upgrade.module_path()
    source = File.read!(path)
    updated = Upgrade.rewrite(source, Upgrade.apply_plan(plan))

    if updated == source do
      Mix.shell().info("\nNothing to write; #{path} is already current.")
    else
      File.write!(path, updated)
      Mix.shell().info("\nUpdated #{path}. Run `mix format` and the test suite.")
    end
  end

  defp regenerate_examples do
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

      case mix_run_script(script) do
        0 -> :ok
        status -> Mix.raise("scripts/#{script}.exs exited with #{status}")
      end
    end)

    Mix.shell().info("\nRegenerated the checked-in example projects.")
  end

  defp mix_run_script(script) do
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
  defp comment(%{status: :unresolved, note: note}), do: note
  defp comment(_up_to_date_entry), do: ""

  defp label(key), do: Atom.to_string(key)

  # --- HTTP ---

  defp http_fetch(url) do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    request = {String.to_charlist(url), headers()}

    case :httpc.request(:get, request, http_options(), body_format: :binary) do
      {:ok, {{_version, 200, _reason}, _headers, body}} ->
        {:ok, body}

      {:ok, {{_version, status, reason}, _headers, _body}} ->
        {:error, {status, to_string(reason)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp headers do
    [
      {~c"user-agent", ~c"gen_server_virtual_time templates.upgrade"},
      {~c"accept", ~c"application/vnd.github+json"}
    ] ++ auth_header()
  end

  defp auth_header do
    case System.get_env("GH_TOKEN") || System.get_env("GITHUB_TOKEN") do
      nil -> []
      token -> [{~c"authorization", String.to_charlist("Bearer #{token}")}]
    end
  end

  defp http_options do
    [
      timeout: 30_000,
      connect_timeout: 15_000,
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        depth: 4,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]
  end
end
