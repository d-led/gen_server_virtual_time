defmodule WorkflowPathsTest do
  use ExUnit.Case, async: true

  @workflows Path.wildcard(".github/workflows/*.yml")

  test "every path a workflow watches exists, so no job is silently disabled" do
    missing =
      for workflow <- @workflows,
          path <- watched_paths(workflow),
          not glob?(path),
          not File.exists?(path),
          do: {workflow, path}

    assert missing == []
  end

  test "the workflows are actually being read" do
    assert Enum.any?(@workflows, &(&1 =~ "ci.yml"))
    assert Enum.any?(@workflows, &(&1 =~ "docs.yml"))
  end

  # The `paths:` filters are the only place a workflow names files, so a stale
  # entry there is a job that never runs again.
  defp watched_paths(workflow) do
    workflow
    |> File.read!()
    |> then(&Regex.scan(~r/^\s*paths:\s*\n((?:\s*-\s*'.*'\s*\n)+)/m, &1, capture: :all_but_first))
    |> List.flatten()
    |> Enum.flat_map(&Regex.scan(~r/'(.*)'/, &1, capture: :all_but_first))
    |> List.flatten()
  end

  defp glob?(path), do: String.contains?(path, ["*", "?", "["])
end
