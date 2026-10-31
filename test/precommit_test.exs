defmodule Mix.Tasks.PrecommitTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Precommit

  describe "the checks" do
    test "run every package's formatting, compilation, credo and docs" do
      packages = Enum.map(steps(), & &1.label)

      for package <-
            ~w(gen_server_virtual_time actor_simulation actor_simulation_codegen gen_server_virtual_time_migrate) do
        assert "#{package} formatting" in packages
        assert "#{package} compile" in packages
        assert "#{package} credo" in packages
        assert "#{package} docs" in packages
      end
    end

    test "stay in the package they belong to" do
      dirs = steps() |> Enum.map(& &1.dir) |> Enum.reject(&is_nil/1)

      assert Enum.all?(dirs, &String.starts_with?(&1, "packages/"))
      assert Enum.any?(dirs, &(&1 == "packages/gen_server_virtual_time_migrate"))
    end

    test "run the tests once for everything, after the format check" do
      labels = Enum.map(steps(), & &1.label)

      assert Enum.count(labels, &(&1 =~ "tests")) == 1

      assert index(labels, "tests (every package and the workspace)") >
               index(labels, "workspace formatting")
    end

    test "leave dialyzer out unless it is asked for" do
      refute Enum.any?(steps(), &(&1.label =~ "dialyzer"))
      assert Enum.count(steps(all?: true), &(&1.label =~ "dialyzer")) == 4
    end
  end

  defp steps(options \\ []), do: Precommit.steps(options)

  defp index(labels, wanted) do
    labels |> Enum.find_index(&(&1 == wanted)) || flunk("no step called #{inspect(wanted)}")
  end
end
