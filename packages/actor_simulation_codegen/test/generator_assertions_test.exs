defmodule GeneratorAssertionsTest do
  @moduledoc """
  The generator suites share `GeneratorAssertions` to state what a generator
  returns. An assertion helper that cannot fail is worse than no helper, so its
  refusals are checked here rather than assumed.
  """

  use ExUnit.Case, async: true

  test "accepts a plan of named files with content" do
    plan = [{"main.c", "int main(void) { return 0; }"}, {"README.md", "# project"}]

    assert GeneratorAssertions.assert_file_plan(plan) == plan
  end

  test "refuses a plan with nothing in it" do
    assert_raise ExUnit.AssertionError, ~r/expected a non-empty file plan/, fn ->
      GeneratorAssertions.assert_file_plan([])
    end
  end

  test "refuses an entry that is not a filename and content pair" do
    assert_raise ExUnit.AssertionError, ~r/expected a \{filename, content\} pair/, fn ->
      GeneratorAssertions.assert_file_plan([:main_c])
    end
  end

  test "refuses an empty filename or missing content" do
    assert_raise ExUnit.AssertionError, ~r/expected a filename/, fn ->
      GeneratorAssertions.assert_file_plan([{"", "int main(void) {}"}])
    end

    assert_raise ExUnit.AssertionError, ~r/expected content for main\.c/, fn ->
      GeneratorAssertions.assert_file_plan([{"main.c", nil}])
    end
  end

  test "names the files it did get when the wanted one is missing" do
    assert_raise ExUnit.AssertionError, ~r{main\.c was not generated; got: \["other\.c"\]}, fn ->
      GeneratorAssertions.file_content([{"other.c", "x"}], "main.c")
    end
  end
end
