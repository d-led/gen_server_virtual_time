# Bumps the version of every package at once, or checks that they agree.
#
#   elixir scripts/release.exs bump patch    # 1.0.0 -> 1.0.1
#   elixir scripts/release.exs bump minor
#   elixir scripts/release.exs bump major
#   elixir scripts/release.exs check         # exit 1 when they disagree
#
# The packages share one version and are released together from one tag, so the
# version lives in VERSION and is written into each mix.exs and each README's
# dependency snippet by this script. A tag `vX.Y.Z` publishes all of them in
# dependency order (.github/workflows/publish.yml).

defmodule Release do
  @packages ~w(gen_server_virtual_time actor_simulation actor_simulation_codegen gen_server_virtual_time_migrate)
  @version_file "VERSION"

  def main(["bump", kind]) do
    current = current_version()
    next = bump(kind, current)

    File.write!(@version_file, next <> "\n")
    readmes = @packages |> Enum.map(&rewriter("packages/#{&1}", next)) |> Enum.count(&(&1 == :pinned))
    rewrite_workspace_version(next)
    rewrite_changelog(current, next)

    IO.puts("#{current} -> #{next}")

    IO.puts(
      "Updated #{@version_file}, #{length(@packages)} mix.exs files, #{readmes} README(s) and CHANGELOG.md"
    )

    IO.puts("Next: review the diff, commit, then ./scripts/tag_and_push_version.sh")
  end

  def main(["check"]) do
    versions = [{"VERSION", current_version()} | Enum.map(@packages, &{&1, mix_version(&1)})]

    case Enum.uniq_by(versions, &elem(&1, 1)) do
      [_one] ->
        IO.puts("All packages are at #{current_version()}")

      _disagreement ->
        Enum.each(versions, fn {name, version} -> IO.puts("  #{name}: #{version}") end)
        Mix.raise("Versions disagree; run `elixir scripts/release.exs bump patch`")
    end
  end

  def main(_) do
    Mix.raise("Usage: elixir scripts/release.exs bump {major|minor|patch} | check")
  end

  defp bump("major", version), do: version |> parts() |> then(fn [m, _, _] -> "#{m + 1}.0.0" end)

  defp bump("minor", version),
    do: version |> parts() |> then(fn [m, n, _] -> "#{m}.#{n + 1}.0" end)

  defp bump("patch", version),
    do: version |> parts() |> then(fn [m, n, p] -> "#{m}.#{n}.#{p + 1}" end)

  defp bump(kind, _version),
    do: Mix.raise("Unknown bump #{inspect(kind)}; use major, minor or patch")

  defp parts(version) do
    case String.split(version, ".") do
      [major, minor, patch] ->
        [String.to_integer(major), String.to_integer(minor), String.to_integer(patch)]

      _ ->
        Mix.raise("Cannot parse version #{version}")
    end
  end

  defp current_version do
    @version_file |> File.read!() |> String.trim()
  end

  defp mix_version(package) do
    path = "packages/#{package}/mix.exs"

    case Regex.run(~r/@version "([^"]+)"/, File.read!(path)) do
      [_, version] -> version
      nil -> Mix.raise("No @version in #{path}")
    end
  end

  # The workspace app is not published, but its version is the requirement each of
  # its path deps has to satisfy, so it has to move with the packages.
  defp rewrite_workspace_version(version) do
    replace!("mix.exs", ~r/@version "[^"]+"/, ~s(@version "#{version}"))
  end

  defp rewriter(dir, version) do
    replace!("#{dir}/mix.exs", ~r/@version "[^"]+"/, ~s(@version "#{version}"))

    readme = "#{dir}/README.md"

    # A package whose README carries no dependency snippet — the migrator is a
    # repository tool and does not have one — has nothing to pin.
    if File.exists?(readme), do: pin(readme, version), else: :no_pin
  end

  defp pin(path, version) do
    pattern = ~r/\{:(\w+), "~> [^"]+"\}/
    contents = File.read!(path)

    if Regex.match?(pattern, contents) do
      File.write!(path, Regex.replace(pattern, contents, ~s({:\\1, "~> #{version}"})))
      :pinned
    else
      :no_pin
    end
  end

  defp rewrite_changelog(previous, version) do
    path = "CHANGELOG.md"
    today = Date.utc_today() |> Date.to_iso8601()
    compare = "https://github.com/d-led/gen_server_virtual_time/compare"

    contents =
      path
      |> File.read!()
      |> String.replace(
        "## [Unreleased]\n",
        "## [Unreleased]\n\n## [#{version}] - #{today}\n",
        global: false
      )
      # The released version gets its own compare link, and `Unreleased` moves on
      # to the new tag, so the file keeps working with Keep a Changelog.
      |> String.replace(
        ~r/^\[Unreleased\]:\n  \S+$/m,
        "[Unreleased]:\n  #{compare}/v#{version}...HEAD\n" <>
          "[#{version}]:\n  #{compare}/v#{previous}...v#{version}",
        global: false
      )

    File.write!(path, contents)
  end

  defp replace!(path, pattern, replacement) do
    contents = File.read!(path)
    updated = Regex.replace(pattern, contents, replacement)

    if updated == contents and not Regex.match?(pattern, contents) do
      Mix.raise("#{path} does not contain #{inspect(pattern)}")
    end

    File.write!(path, updated)
  end
end

Release.main(System.argv())
