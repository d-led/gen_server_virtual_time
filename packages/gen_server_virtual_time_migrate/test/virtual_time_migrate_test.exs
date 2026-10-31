defmodule VirtualTimeMigrateTest do
  use ExUnit.Case, async: true

  alias VirtualTimeMigrate

  describe "the declaration" do
    test "becomes the virtual-time one, and nothing else changes" do
      assert migrate(read("before")) == read("after")
    end

    test "keeps the options GenServer was given" do
      assert migrate(read("before_options_and_time")) == read("after_options_and_time")
    end
  end

  describe "time calls inside a converted module" do
    test "go through the virtual backend, so they land on the test's clock" do
      migrated = migrate(read("before_options_and_time"))

      assert migrated =~ "VirtualTimeGenServer.send_after(self(), :tick, 1000)"
      assert migrated =~ "VirtualTimeGenServer.sleep(10)"
    end

    test "report :erlang.send_after/3, whose arguments are in another order" do
      migrated = migrate(read("before_options_and_time"))
      {:ok, %{notes: notes}} = VirtualTimeMigrate.plan(read("before_options_and_time"))

      assert migrated =~ ":erlang.send_after(500, self(), :tick)"
      assert Enum.any?(notes, &(&1.message =~ "takes the delay first"))
    end
  end

  describe "calls to other servers" do
    test "a converted target is rewritten, a plain GenServer is not" do
      assert migrate(read("before_calls"), MapSet.new(["MyApp.Counter"])) == read("after_calls")
    end

    test "a target that is not a literal module is reported instead of guessed" do
      {:ok, %{edits: edits, notes: notes}} =
        VirtualTimeMigrate.plan(read("before_calls"), MapSet.new(["MyApp.Counter"]))

      assert Enum.any?(notes, &(&1.message =~ "not a literal module"))
      refute Enum.any?(edits, &(&1.change =~ "cast"))
    end
  end

  describe "a converted module" do
    test "keeps every call it cannot rewrite, and its comments and strings" do
      migrated = migrate(read("untouched"))

      assert migrated =~ "GenServer.call(pid, :get)"
      assert migrated =~ "# GenServer.call(pid, :get) is not virtual here"
      assert migrated =~ ~s|"GenServer.call(MyApp.Other, :get)"|
      refute migrated =~ "VirtualTimeGenServer.call"
    end
  end

  describe "the rewritten source" do
    test "still parses" do
      for name <- ~w(before before_options_and_time before_calls) do
        assert {:ok, _ast} = Code.string_to_quoted(migrate(read(name)))
      end
    end

    test "is a fixed point: migrating it again changes nothing" do
      for name <- ~w(after after_options_and_time after_calls) do
        assert {:ok, %{edits: []}} = VirtualTimeMigrate.plan(read(name))
      end
    end

    test "differs only on the lines that were rewritten" do
      before_lines = read("before_calls") |> String.split("\n")

      after_lines =
        read("before_calls") |> migrate(MapSet.new(["MyApp.Counter"])) |> String.split("\n")

      changed = Enum.zip(before_lines, after_lines) |> Enum.reject(fn {a, b} -> a == b end)

      assert changed != []
      assert Enum.all?(changed, fn {a, b} -> a =~ "GenServer" and b =~ "VirtualTimeGenServer" end)
    end
  end

  describe "source that does not parse" do
    test "is an error, not a crash" do
      assert {:error, _reason} =
               VirtualTimeMigrate.plan("defmodule Broken do\n  def oops( do\nend\n")
    end
  end

  defp migrate(source, known_converted \\ nil) do
    {:ok, plan} = VirtualTimeMigrate.plan(source, known_converted)
    VirtualTimeMigrate.apply_edits(source, plan.edits)
  end

  defp read(name) do
    "test/fixtures/declaration/#{name}.ex" |> File.read!()
  end
end
