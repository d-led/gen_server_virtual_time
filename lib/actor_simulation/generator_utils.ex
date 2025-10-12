defmodule ActorSimulation.GeneratorUtils do
  @moduledoc """
  Shared utilities for code generators.

  This module provides common functionality used across all generators
  (OMNeT++, CAF, Pony, Phony) to minimize code duplication.
  """

  @doc """
  Writes generated files to a directory, creating subdirectories as needed.
  """
  def write_to_directory(files, output_dir) do
    Enum.each(files, fn {filename, content} ->
      path = Path.join(output_dir, filename)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, content)
    end)

    :ok
  end

  @doc """
  Converts an atom or string to snake_case.

  ## Examples

      iex> GeneratorUtils.to_snake_case(:my_actor)
      "my_actor"

      iex> GeneratorUtils.to_snake_case("MyActor")
      "my_actor"
  """
  def to_snake_case(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> to_snake_case()
  end

  def to_snake_case(string) when is_binary(string) do
    string
    |> String.replace("-", "_")
    |> String.replace(~r/([A-Z])/, "_\\1")
    |> String.downcase()
    |> String.trim_leading("_")
  end

  @doc """
  Converts an atom or string to PascalCase.

  ## Examples

      iex> GeneratorUtils.to_pascal_case(:my_actor)
      "MyActor"

      iex> GeneratorUtils.to_pascal_case("my_actor")
      "MyActor"
  """
  def to_pascal_case(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> to_pascal_case()
  end

  def to_pascal_case(string) when is_binary(string) do
    string
    |> String.split(~r/[_-]/)
    |> Enum.map_join("", &String.capitalize/1)
  end

  @doc """
  Converts an atom or string to camelCase.

  ## Examples

      iex> GeneratorUtils.to_camel_case(:my_actor)
      "myActor"
  """
  def to_camel_case(atom) when is_atom(atom) do
    atom |> Atom.to_string() |> to_camel_case()
  end

  def to_camel_case(string) when is_binary(string) do
    parts = String.split(string, ~r/[_-]/)

    case parts do
      [] -> ""
      [first | rest] -> String.downcase(first) <> Enum.map_join(rest, "", &String.capitalize/1)
    end
  end

  @doc """
  Extracts messages from a send pattern.

  ## Examples

      iex> GeneratorUtils.extract_messages({:periodic, 100, :tick})
      [:tick]

      iex> GeneratorUtils.extract_messages({:burst, 10, 1000, :batch})
      [:batch]
  """
  def extract_messages(nil), do: []
  def extract_messages({_type, _interval, message}), do: [message]
  def extract_messages({:burst, _count, _interval, message}), do: [message]

  @doc """
  Calculates the interval in milliseconds for a send pattern.

  ## Examples

      iex> GeneratorUtils.pattern_interval({:periodic, 100, :msg})
      100

      iex> GeneratorUtils.pattern_interval({:rate, 10, :msg})
      100
  """
  def pattern_interval({:periodic, interval_ms, _message}), do: interval_ms
  def pattern_interval({:rate, per_second, _message}), do: div(1000, per_second)
  def pattern_interval({:burst, _count, interval_ms, _message}), do: interval_ms
  def pattern_interval(nil), do: nil

  @doc """
  Converts interval to seconds (for OMNeT++ and other simulators).
  """
  def interval_to_seconds(interval_ms) when is_number(interval_ms) do
    interval_ms / 1000.0
  end

  @doc """
  Converts interval to nanoseconds (for Pony timers).
  """
  def interval_to_nanoseconds(interval_ms) when is_number(interval_ms) do
    interval_ms * 1_000_000
  end

  @doc """
  Normalizes a message name to a valid identifier.
  """
  def message_name(msg) when is_atom(msg), do: Atom.to_string(msg)
  def message_name(msg) when is_binary(msg), do: msg

  def message_name(msg) do
    inspect(msg) |> String.replace(~r/[^a-z0-9_]/, "_")
  end

  @doc """
  Filters simulated actors from an actors map.
  """
  def simulated_actors(actors) do
    actors
    |> Enum.filter(fn {_name, info} -> info.type == :simulated end)
    |> Enum.map(fn {name, info} -> {name, info.definition} end)
  end

  @doc """
  Generates a basic README template.
  """
  def readme_template(project_name, framework, options) do
    build_cmd = Keyword.fetch!(options, :build_cmd)
    test_cmd = Keyword.fetch!(options, :test_cmd)
    run_cmd = Keyword.fetch!(options, :run_cmd)
    framework_url = Keyword.fetch!(options, :framework_url)

    """
    # #{project_name}

    Generated from ActorSimulation DSL using #{framework}.

    ## About

    This project uses [#{framework}](#{framework_url}) for high-performance actor systems.

    ## Building

    ```bash
    #{build_cmd}
    ```

    ## Running

    ```bash
    #{run_cmd}
    ```

    ## Testing

    ```bash
    #{test_cmd}
    ```

    ## Customizing Behavior

    The generated code uses callback interfaces/traits to allow customization
    WITHOUT modifying generated files. See the implementation files for details.

    ## Project Structure

    - Generated actor code (DO NOT EDIT unless needed)
    - Callback implementations (EDIT THESE!)
    - Tests (expand as needed)
    - Build configuration

    ## Learn More

    - [#{framework}](#{framework_url})
    - [ActorSimulation DSL](https://github.com/yourusername/gen_server_virtual_time)
    """
  end
end
