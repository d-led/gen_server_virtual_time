defmodule ActorSimulation.TemplateVersions.Upgrade do
  @moduledoc """
  Resolves the latest upstream release of everything in
  `ActorSimulation.TemplateVersions.sources/0` and rewrites the version table.

  This module is pure: it never talks to the network itself. `plan/1` takes a
  `fetch` function and a table, and returns what would change. `Mix.Tasks.Templates.Upgrade`
  supplies the HTTP client; the tests supply a stub.

  `sources/0` describes where each version comes from, so this module only has to
  know how to read those upstreams:

  | source | upstream | read |
  | --- | --- | --- |
  | `{:conan_center, package, transform}` | ConanCenter recipe `config.yml` | highest version |
  | `{:crates_io, crate, transform}` | `crates.io/api/v1/crates/<crate>` | `max_stable_version` |
  | `{:go_module, module, transform}` | `proxy.golang.org/<module>/@latest` | `Version` |
  | `{:maven_central, coord, transform}` | `repo1.maven.org/.../maven-metadata.xml` | highest stable release |
  | `{:github_release, repo, transform}` | `releases/latest` | `tag_name` |
  | `{:github_tags, repo, transform}` | `tags` | highest semver tag |
  | `{:manual, reason, :none}` | — | nothing, reported as manual |

  """

  alias ActorSimulation.TemplateVersions, as: Versions

  @module_path "lib/actor_simulation/template_versions.ex"
  @versions_begin "  # --- versions:begin (managed by `mix templates.upgrade`) ---"
  @versions_end "  # --- versions:end ---"
  @semver ~r/(\d+)\.(\d+)\.(\d+)/

  @typedoc """
  One key's outcome: its `current` pin, the `latest` we could find upstream (if
  any), the `source` it came from, and what that means.
  """
  @type entry :: %{
          key: atom(),
          current: String.t(),
          latest: String.t() | nil,
          status: :update | :current | :manual | :unresolved,
          source: term(),
          note: String.t() | nil
        }

  @doc "Path of the source file that holds the version table, relative to the project root."
  @spec module_path() :: String.t()
  def module_path, do: @module_path

  @doc """
  Asks upstream for every version and reports what would change.

  `fetch` is called as `fetch.(url)` and must return `{:ok, body}` or
  `{:error, reason}`.
  """
  @spec plan((String.t() -> {:ok, binary()} | {:error, term()})) :: [entry()]
  def plan(fetch), do: plan(fetch, Versions.versions())

  @spec plan((String.t() -> {:ok, binary()} | {:error, term()}), %{atom() => String.t()}) ::
          [entry()]
  def plan(fetch, current) do
    for {key, source} <- Versions.sources() do
      entry(key, source, Map.fetch!(current, key), fetch)
    end
  end

  @doc """
  The table the given plan would write, as a map.
  """
  @spec apply_plan([entry()]) :: %{atom() => String.t()}
  def apply_plan(plan) do
    Map.new(plan, fn
      %{status: :update, key: key, latest: latest} -> {key, latest}
      %{key: key, current: current} -> {key, current}
    end)
  end

  @doc """
  True when the plan would change at least one pin.
  """
  @spec drift?([entry()]) :: boolean()
  def drift?(plan), do: Enum.any?(plan, &(&1.status == :update))

  @doc """
  Rewrites the `@versions` table inside `source` with `table`.

  Everything outside the `versions:begin`/`versions:end` markers is left byte for
  byte alone, so the module's documentation and functions are never touched.
  """
  @spec rewrite(String.t(), %{atom() => String.t()}) :: String.t()
  def rewrite(source, table) do
    [head, rest] = String.split(source, @versions_begin, parts: 2)
    [_old, tail] = String.split(rest, @versions_end, parts: 2)

    head <> @versions_begin <> "\n" <> render_table(table) <> "\n\n" <> @versions_end <> tail
  end

  @doc """
  Renders `table` as the `@versions` map literal, in `sources/0` order, with the
  upstream on the line above each pin.

  The layout is exactly what `mix format` produces, so an upgrade is a
  one-line-per-changed-pin diff and never a reformat.
  """
  @spec render_table(%{atom() => String.t()}) :: String.t()
  def render_table(table) do
    body =
      Enum.map_join(Versions.sources(), ",\n", fn {key, source} ->
        "    # #{Versions.describe(source)}\n    #{pin(key, Map.fetch!(table, key))}"
      end)

    Enum.join(["  @versions %{", body, "  }"], "\n")
  end

  defp pin(key, value), do: "#{key}: #{inspect(value)}"

  @doc """
  The `{url, parser}` this source is read from, or `:manual`.

  The parser is a `fun(body, current_pin)` that returns the newest version the
  upstream offers, or `nil` when the body holds none. It receives the current pin
  because `:latest_within_major` uses it as a ceiling: a major upgrade of a
  generated project's dependencies is a decision, not something a script should
  make overnight.
  """
  @spec upstream(term()) ::
          {:ok, String.t(), (binary(), String.t() -> String.t() | nil)} | :manual
  def upstream({:conan_center, package, transform}) do
    url =
      "https://raw.githubusercontent.com/conan-io/conan-center-index/master/recipes/#{package}/config.yml"

    {:ok, url, fn body, current -> body |> conan_versions() |> pick(transform, current) end}
  end

  def upstream({:crates_io, crate, transform}) do
    url = "https://crates.io/api/v1/crates/#{crate}"

    {:ok, url,
     fn body, _current ->
       body |> json_field(["crate", "max_stable_version"]) |> narrow(transform)
     end}
  end

  def upstream({:go_module, module, transform}) do
    url = "https://proxy.golang.org/#{escape_module(module)}/@latest"
    {:ok, url, fn body, _current -> body |> json_field(["Version"]) |> narrow(transform) end}
  end

  def upstream({:maven_central, coord, transform}) do
    {group, artifact} = coord |> String.split(":", parts: 2) |> List.to_tuple()
    path = "#{String.replace(group, ".", "/")}/#{artifact}"
    url = "https://repo1.maven.org/maven2/#{path}/maven-metadata.xml"
    {:ok, url, fn body, current -> body |> xml_versions() |> pick(transform, current) end}
  end

  def upstream({:github_release, repo, transform}) do
    url = "https://api.github.com/repos/#{repo}/releases/latest"
    {:ok, url, fn body, _current -> body |> json_field(["tag_name"]) |> narrow(transform) end}
  end

  def upstream({:github_tags, repo, transform}) do
    url = "https://api.github.com/repos/#{repo}/tags?per_page=100"
    {:ok, url, fn body, current -> body |> tag_names() |> pick(transform, current) end}
  end

  def upstream({:manual, _reason, _transform}), do: :manual

  # --- resolution ---

  defp entry(key, source, current, fetch) do
    case upstream(source) do
      :manual ->
        %{
          key: key,
          current: current,
          latest: nil,
          status: :manual,
          source: source,
          note: Versions.describe(source)
        }

      {:ok, url, parse} ->
        entry_from(key, source, current, url, parse, fetch)
    end
  end

  defp entry_from(key, source, current, url, parse, fetch) do
    case resolve(url, parse, current, fetch) do
      {:ok, ^current} ->
        %{
          key: key,
          current: current,
          latest: current,
          status: :current,
          source: source,
          note: nil
        }

      {:ok, latest} ->
        %{key: key, current: current, latest: latest, status: :update, source: source, note: nil}

      {:error, reason} ->
        %{
          key: key,
          current: current,
          latest: nil,
          status: :unresolved,
          source: source,
          note: "could not read #{url}: #{inspect(reason)}"
        }
    end
  end

  defp resolve(url, parse, current, fetch) do
    with {:ok, body} <- fetch.(url),
         latest when is_binary(latest) <- parse.(body, current) do
      {:ok, latest}
    else
      nil -> {:error, :no_version_found}
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unexpected_response, other}}
    end
  end

  # --- reading upstreams ---

  defp json_field(body, path) do
    case Jason.decode(body) do
      {:ok, data} -> get_in(data, path)
      {:error, _} -> nil
    end
  end

  defp tag_names(body) do
    with {:ok, tags} when is_list(tags) <- Jason.decode(body) do
      tags |> Enum.map(&Map.get(&1, "name")) |> Enum.reject(&is_nil/1)
    else
      _ -> []
    end
  end

  defp xml_versions(body) do
    ~r{<version>([^<]+)</version>}
    |> Regex.scan(body)
    |> Enum.map(&Enum.at(&1, 1))
  end

  # ConanCenter's config.yml is a two-level map of quoted versions; a version
  # line is all we need, so there is no YAML parser in the dependency tree.
  defp conan_versions(body) do
    body
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(~r/^ {2}"[^"]+":/, &1))
    |> Enum.map(fn line ->
      line |> String.trim() |> String.trim_leading("\"") |> String.split("\"") |> hd()
    end)
  end

  # --- choosing a version ---

  @doc """
  Narrows a single upstream version.

    * `:raw` — as published (`"v0.0.0-20220903101357-530938a4b13d"`), for values
      that are not releases at all
    * `:tag` — the tag as published (`"v7.0.1"`)
    * `:version` — the version in the tag (`"7.0.1"`)
    * `:major` — `"v7.0.1"` becomes `"7"`, for pins that float within a major
    * `:major_tag` — `"v7.0.1"` becomes `"v7"`, how GitHub Actions are pinned
  """
  @spec narrow(String.t() | nil, atom()) :: String.t() | nil
  def narrow(nil, _transform), do: nil
  def narrow(value, :raw), do: value
  def narrow(value, :tag), do: value

  def narrow(value, transform) do
    case version_from_tag(value) do
      nil -> nil
      version -> narrow_version(version, transform)
    end
  end

  defp narrow_version(version, :version), do: version
  defp narrow_version(version, :major), do: major_of(version)
  defp narrow_version(version, :major_tag), do: "v" <> major_of(version)

  defp pick(versions, :version, _current), do: highest(versions, :all)
  defp pick(versions, :major, _current), do: versions |> highest(:all) |> narrow(:major)

  defp pick(versions, :latest_within_major, current) do
    highest(versions, {:major, major_of(current)})
  end

  defp highest(versions, :all), do: highest(versions, {:major, :any})

  defp highest(versions, {:major, major}) do
    versions
    |> Enum.reject(&prerelease?/1)
    |> Enum.filter(&(major == :any or major_of(&1) == major))
    |> Enum.map(&{&1, numeric(&1)})
    |> Enum.reject(fn {_raw, numbers} -> numbers == nil end)
    |> Enum.max_by(fn {_raw, numbers} -> numbers end, fn -> nil end)
    |> case do
      nil -> nil
      {raw, _numbers} -> raw
    end
  end

  defp major_of(version) when is_binary(version) do
    case Regex.run(@semver, version) do
      [_all, major, _minor, _patch] -> major
      _ -> nil
    end
  end

  defp major_of(_non_version), do: nil

  defp numeric(version) do
    case Regex.run(@semver, version) do
      [_all, major, minor, patch] ->
        {String.to_integer(major), String.to_integer(minor), String.to_integer(patch)}

      _ ->
        nil
    end
  end

  defp prerelease?(version), do: not is_binary(version) or String.contains?(version, "-")

  defp escape_module(module) do
    # The Go module proxy escapes upper case letters as !lower.
    Regex.replace(~r/[A-Z]/, module, fn letter -> "!" <> String.downcase(letter) end)
  end

  @doc """
  Extracts a version from a git tag.

  Tags come in flavours like `v7.0.1`, `omnetpp-6.4.0` or `1.29.0`; the first
  semver-looking run of digits is the version.
  """
  @spec version_from_tag(String.t() | nil) :: String.t() | nil
  def version_from_tag(nil), do: nil

  def version_from_tag(tag) do
    case Regex.run(@semver, tag) do
      [_all, major, minor, patch] -> "#{major}.#{minor}.#{patch}"
      _ -> nil
    end
  end
end
