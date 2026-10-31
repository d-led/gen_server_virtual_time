defmodule Mix.Tasks.VirtualTime.MigrateTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.VirtualTime.Migrate

  @moduletag :tmp_dir

  describe "--check" do
    test "exits non-zero when something would change", %{tmp_dir: tmp} do
      seed!(tmp, "before")

      capture_io(fn ->
        exit = catch_exit(Migrate.run(["--paths", tmp, "--check"]))
        assert exit == {:shutdown, 1}
      end)
    end

    test "exits zero when the tree is already migrated", %{tmp_dir: tmp} do
      seed!(tmp, "after")

      capture_io(fn -> assert :ok == Migrate.run(["--paths", tmp, "--check"]) end)
    end
  end

  describe "--write" do
    test "rewrites the file in place and says so", %{tmp_dir: tmp} do
      seeded = seed!(tmp, "before")
      original = File.read!(seeded)

      output = capture_io(fn -> Migrate.run(["--paths", tmp, "--write"]) end)

      assert File.read!(seeded) =~ "use VirtualTimeGenServer"
      assert File.read!(seeded) != original
      assert output =~ "Wrote 1 file(s)."
    end

    test "leaves a tree that is already migrated untouched", %{tmp_dir: tmp} do
      seeded = seed!(tmp, "after")
      original = File.read!(seeded)

      output = capture_io(fn -> Migrate.run(["--paths", tmp, "--write"]) end)

      assert File.read!(seeded) == original
      assert output =~ "Nothing to migrate"
    end
  end

  describe "the report" do
    test "names the file and the line it would change", %{tmp_dir: tmp} do
      seed!(tmp, "before")

      output = capture_io(fn -> Migrate.run(["--paths", tmp]) end)

      assert output =~ "server.ex"
      assert output =~ "line 2: use GenServer"
      assert output =~ "1 file(s) would change"
    end

    test "skips a file it cannot parse, and still reports the others", %{tmp_dir: tmp} do
      seed!(tmp, "before")
      File.write!(Path.join(tmp, "broken.ex"), "defmodule Broken do\n  def oops( do\nend\n")

      output = capture_io(fn -> Migrate.run(["--paths", tmp]) end)

      assert output =~ "broken.ex: could not parse — skipped"
      assert output =~ "server.ex"
    end
  end

  defp seed!(dir, fixture) do
    path = Path.join(dir, "server.ex")
    File.write!(path, File.read!("test/fixtures/declaration/#{fixture}.ex"))
    path
  end
end
