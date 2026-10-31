defmodule Mix.Tasks.VirtualTime.UpgradeTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.VirtualTime.Upgrade

  @moduletag :tmp_dir

  describe "--check" do
    test "exits non-zero when a deprecated name is left", %{tmp_dir: tmp} do
      seed!(tmp, "before_qualified")

      capture_io(fn ->
        exit = catch_exit(Upgrade.run(["--paths", tmp, "--check"]))
        assert exit == {:shutdown, 1}
      end)
    end

    test "exits zero when nothing is left to rename", %{tmp_dir: tmp} do
      seed!(tmp, "after_qualified")

      capture_io(fn -> assert :ok == Upgrade.run(["--paths", tmp, "--check"]) end)
    end
  end

  describe "--write" do
    test "renames in place and says so", %{tmp_dir: tmp} do
      seeded = seed!(tmp, "before_aliased")

      output = capture_io(fn -> Upgrade.run(["--paths", tmp, "--write"]) end)

      assert File.read!(seeded) == File.read!("test/fixtures/upgrade/after_aliased.ex")
      assert output =~ "Wrote 1 file(s)."
    end
  end

  describe "the report" do
    test "names the file and the module it would rename", %{tmp_dir: tmp} do
      seed!(tmp, "before_qualified")

      output = capture_io(fn -> Upgrade.run(["--paths", tmp]) end)

      assert output =~ "client.ex"
      assert output =~ "line 3: ActorSimulation.CAFGenerator"
      assert output =~ "1 file(s) would change"
    end

    test "says there is nothing to do on a clean tree", %{tmp_dir: tmp} do
      seed!(tmp, "after_qualified")

      output = capture_io(fn -> Upgrade.run(["--paths", tmp]) end)

      assert output =~ "Nothing to upgrade"
    end
  end

  defp seed!(dir, fixture) do
    path = Path.join(dir, "client.ex")
    File.write!(path, File.read!("test/fixtures/upgrade/#{fixture}.ex"))
    path
  end
end
