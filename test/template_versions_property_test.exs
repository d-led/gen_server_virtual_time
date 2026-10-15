defmodule ActorSimulation.TemplateVersionsPropertyTest do
  @moduledoc """
  Laws for the version table that `mix templates.upgrade` reads and writes.

  The table is data, and the upgrade task derives decisions from it: how much of
  an upstream version to take, and what the "major" of the current pin is. A pin
  whose shape does not match its source's transform makes the task silently do
  nothing — the failure mode this whole mechanism exists to prevent — so the
  shape of every pin is a law here rather than a comment.

  `member_of/1` over the table makes each property hold for every entry, which is
  what "the table is well formed" means.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ActorSimulation.TemplateVersions

  property "every pin can be pasted into a build file" do
    check all({key, pin} <- pin()) do
      assert is_binary(pin), "#{key} is not a string"
      assert pin != "" and pin =~ ~r/^\S+$/, "#{key} is not a whitespace-free version"
    end
  end

  property "a pin that starts with a digit reports a numeric major that is its prefix" do
    check all({key, pin} <- member_of(pins_starting_with_a_digit())) do
      major = TemplateVersions.major(key)

      assert major =~ ~r/^\d+$/, "#{key}'s major is not numeric: #{inspect(major)}"
      assert String.starts_with?(pin, major)
    end
  end

  property "a pin compared within its major has a major to compare" do
    check all({key, source} <- source_with(:latest_within_major)) do
      # Deciding "newest within the current major" needs a numeric major to decide
      # from: a pin of "release" or "v0.0.0-20220903..." would never update.
      assert TemplateVersions.get(key) =~ ~r/^\d+\./
    end
  end

  property "a pin that floats within a major is nothing but that major" do
    check all({key, _source} <- source_with(:major)) do
      pin = TemplateVersions.get(key)

      assert pin =~ ~r/^\d+$/, "#{key} is not a bare major: #{inspect(pin)}"
      assert TemplateVersions.major(key) == pin
    end
  end

  property "an action pin is a moving major tag" do
    check all({key, _source} <- source_with(:major_tag)) do
      assert TemplateVersions.get(key) =~ ~r/^v\d+$/, "#{key} is not a major tag"
    end
  end

  defp pin, do: member_of(TemplateVersions.all())

  # Pins that are versions: the rest are channels, tags and pseudo-versions.
  defp pins_starting_with_a_digit do
    Enum.filter(TemplateVersions.all(), fn {_key, pin} -> String.match?(pin, ~r/^\d/) end)
  end

  # Every source whose transform is this one. Enumerating the subset rather than
  # filtering the whole table keeps the properties exhaustive and cheap.
  defp source_with(transform) do
    member_of(source_entries(transform))
  end

  defp source_entries(transform) do
    Enum.filter(TemplateVersions.sources(), fn {_key, {_kind, _target, source_transform}} ->
      source_transform == transform
    end)
  end

  # A property over an empty list passes without checking anything, so the subsets
  # the properties enumerate are asserted to be there.
  test "the subsets the properties enumerate are not empty" do
    assert pins_starting_with_a_digit() != []
    assert source_entries(:latest_within_major) != []
    assert source_entries(:major) != []
    assert source_entries(:major_tag) != []
  end
end
