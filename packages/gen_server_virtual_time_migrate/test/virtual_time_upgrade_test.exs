defmodule VirtualTimeUpgradeTest do
  use ExUnit.Case, async: true

  alias VirtualTimeMigrate.Edits
  alias VirtualTimeUpgrade

  describe "a fully qualified reference" do
    test "becomes the new module" do
      assert upgrade(read("before_qualified")) == read("after_qualified")
    end
  end

  describe "an alias and the calls it introduces" do
    test "move together, so the file still compiles afterwards" do
      assert upgrade(read("before_aliased")) == read("after_aliased")
    end
  end

  describe "a name it cannot change safely" do
    test "is reported when the new short name is already in use" do
      {:ok, %{edits: edits, notes: notes}} = VirtualTimeUpgrade.plan(read("untouched_clash"))

      assert edits == []
      assert Enum.any?(notes, &(&1.message =~ "already in use"))
    end

    test "is reported when the alias picks its own name" do
      {:ok, %{edits: edits, notes: notes}} = VirtualTimeUpgrade.plan(read("untouched_as_alias"))

      assert edits == []
      assert Enum.any?(notes, &(&1.message =~ "by hand"))
    end
  end

  describe "a file that never mentions the old names" do
    test "plans nothing" do
      assert VirtualTimeUpgrade.plan("defmodule Quiet do\n  def run, do: :ok\nend\n") ==
               {:ok, %{edits: [], notes: []}}
    end
  end

  describe "source that does not parse" do
    test "is an error, not a crash" do
      assert {:error, _reason} =
               VirtualTimeUpgrade.plan("defmodule Broken do\n  def oops( do\nend\n")
    end
  end

  defp upgrade(source) do
    {:ok, plan} = VirtualTimeUpgrade.plan(source)
    Edits.apply(source, plan.edits)
  end

  defp read(name), do: File.read!("test/fixtures/upgrade/#{name}.ex")
end
