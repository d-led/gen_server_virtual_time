defmodule GeneratorAssertions do
  @moduledoc """
  Assertions shared by the code-generator test suites.

  Every generator returns the same thing: a plan of `{filename, content}` pairs.
  Stating that contract once keeps the suites about the code they generate
  instead of about the shape of the return value.
  """

  import ExUnit.Assertions

  @doc """
  Asserts `files` is a generator plan: a non-empty list of `{filename, content}`
  pairs of non-empty strings.

  Returns `files` so it can be used mid-pipeline.
  """
  def assert_file_plan(files) do
    assert [_ | _] = files, "expected a non-empty file plan, got: #{inspect(files)}"

    Enum.each(files, fn
      {name, content} ->
        assert is_binary(name) and name != "", "expected a filename, got: #{inspect(name)}"
        assert is_binary(content) and content != "", "expected content for #{name}"

      other ->
        flunk("expected a {filename, content} pair, got: #{inspect(other)}")
    end)

    files
  end

  @doc """
  The content of `filename` in a generator plan, failing with the list of
  filenames that were generated when it is missing.
  """
  def file_content(files, filename) do
    case List.keyfind(files, filename, 0) do
      {^filename, content} ->
        content

      nil ->
        flunk("#{filename} was not generated; got: #{inspect(Enum.map(files, &elem(&1, 0)))}")
    end
  end
end
