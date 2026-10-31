defmodule ActorSimulation.SitePages do
  @moduledoc false

  # The example pages the documentation site publishes are checked in at the
  # repository root, not inside this package, so a test that regenerates one has
  # to write there: running the suite from `packages/actor_simulation` must not
  # leave a stale copy behind.
  def path(relative), do: Path.join(repo_root(), relative)

  def ensure_dir(relative), do: File.mkdir_p!(path(relative))

  defp repo_root, do: Path.expand("../../../../", __DIR__)
end
