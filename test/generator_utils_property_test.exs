defmodule ActorSimulation.GeneratorUtilsPropertyTest do
  @moduledoc """
  Laws for the case conversions the generators use to build identifiers.

  Every generated project is stitched together from actor names: file names, class
  names, module names, callback methods. A conversion that produces something
  which is not a legal identifier — a stray separator, a leading underscore, a
  digit where a letter has to be — produces a project that does not compile, so
  these properties state what the conversions have to produce.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ActorSimulation.GeneratorUtils

  describe "identifiers" do
    property "snake case is a legal identifier body" do
      check all(name <- snake_name()) do
        converted = GeneratorUtils.to_snake_case(name)

        assert converted =~ ~r/^[a-z][a-z0-9_]*$/
      end
    end

    property "PascalCase starts with a capital and carries no separators" do
      check all(name <- separated_name()) do
        converted = GeneratorUtils.to_pascal_case(name)

        assert converted =~ ~r/^[A-Z][A-Za-z0-9]*$/
      end
    end

    property "camelCase is PascalCase with a lowercase first letter" do
      check all(name <- separated_name()) do
        pascal = GeneratorUtils.to_pascal_case(name)
        camel = GeneratorUtils.to_camel_case(name)

        assert camel == String.downcase(String.first(pascal)) <> String.slice(pascal, 1..-1//1)
      end
    end
  end

  describe "conversions" do
    property "a name already in snake case is left alone" do
      check all(name <- snake_name()) do
        assert GeneratorUtils.to_snake_case(name) == name
      end
    end

    property "snake and PascalCase round trip" do
      check all(name <- snake_name()) do
        assert name |> GeneratorUtils.to_pascal_case() |> GeneratorUtils.to_snake_case() == name
      end
    end

    property "converting twice is the same as converting once" do
      check all(name <- separated_name()) do
        assert GeneratorUtils.to_snake_case(GeneratorUtils.to_snake_case(name)) ==
                 GeneratorUtils.to_snake_case(name)

        assert GeneratorUtils.to_pascal_case(GeneratorUtils.to_pascal_case(name)) ==
                 GeneratorUtils.to_pascal_case(name)
      end
    end

    property "hyphens and underscores are the same separator" do
      check all(name <- snake_name()) do
        with_hyphens = String.replace(name, "_", "-")

        assert GeneratorUtils.to_snake_case(with_hyphens) == name
        assert GeneratorUtils.to_pascal_case(with_hyphens) == GeneratorUtils.to_pascal_case(name)
        assert GeneratorUtils.to_camel_case(with_hyphens) == GeneratorUtils.to_camel_case(name)
      end
    end

    property "an atom and the string with the same name convert the same way" do
      check all(name <- member_of([:worker, :my_actor, :load_balancer, :subscriber2])) do
        as_string = Atom.to_string(name)

        assert GeneratorUtils.to_snake_case(name) == GeneratorUtils.to_snake_case(as_string)
        assert GeneratorUtils.to_pascal_case(name) == GeneratorUtils.to_pascal_case(as_string)
        assert GeneratorUtils.to_camel_case(name) == GeneratorUtils.to_camel_case(as_string)
      end
    end
  end

  defp word do
    gen all(letters <- list_of(member_of(~w(a b z)), min_length: 1, max_length: 4)) do
      Enum.join(letters)
    end
  end

  # A `snake_case` name of one or more lowercase words.
  defp snake_name do
    gen all(words <- list_of(word(), min_length: 1, max_length: 3)) do
      Enum.join(words, "_")
    end
  end

  # The same, with hyphens instead — the DSL allows both separators.
  defp kebab_name do
    gen all(words <- list_of(word(), min_length: 1, max_length: 3)) do
      Enum.join(words, "-")
    end
  end

  defp separated_name, do: one_of([snake_name(), kebab_name()])
end
