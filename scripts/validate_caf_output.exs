#!/usr/bin/env elixir

# Script to validate CAF generator output
# Usage: mix run scripts/validate_caf_output.exs

defmodule CAFOutputValidator do
  @moduledoc """
  Validates that the CAF generator produces valid, compilable C++ code.
  """

  def run do
    IO.puts("""
    ╔═══════════════════════════════════════════════════════════╗
    ║  Validating CAF Generator Output                          ║
    ╚═══════════════════════════════════════════════════════════╝
    """)

    examples = [
      "examples/caf_pubsub",
      "examples/caf_pipeline",
      "examples/caf_burst",
      "examples/caf_loadbalanced"
    ]

    results = Enum.map(examples, &validate_example/1)

    # Summary
    IO.puts("""

    ╔═══════════════════════════════════════════════════════════╗
    ║  Validation Summary                                        ║
    ╚═══════════════════════════════════════════════════════════╝
    """)

    passed = Enum.count(results, fn {status, _, _} -> status == :ok end)
    total = length(results)

    IO.puts("Total examples: #{total}")
    IO.puts("Passed: #{passed}")
    IO.puts("Failed: #{total - passed}")

    if passed == total do
      IO.puts("\n✅ All validations passed!")
      exit({:shutdown, 0})
    else
      IO.puts("\n❌ Some validations failed")
      exit({:shutdown, 1})
    end
  end

  defp validate_example(example_dir) do
    IO.puts("\n📚 Validating: #{example_dir}")
    IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    validations = [
      {:required_files, &check_required_files/1},
      {:cpp_syntax, &check_cpp_syntax/1},
      {:cmake_valid, &check_cmake_valid/1},
      {:callbacks_present, &check_callbacks/1},
      {:ci_pipeline, &check_ci_pipeline/1},
      {:catch2_tests, &check_catch2_tests/1}
    ]

    results =
      Enum.map(validations, fn {name, check_fn} ->
        case check_fn.(example_dir) do
          :ok ->
            IO.puts("  ✅ #{name}")
            :ok

          {:error, reason} ->
            IO.puts("  ❌ #{name}: #{reason}")
            :error
        end
      end)

    status = if Enum.all?(results, &(&1 == :ok)), do: :ok, else: :error
    {status, example_dir, results}
  end

  defp check_required_files(dir) do
    required = [
      "CMakeLists.txt",
      "conanfile.txt",
      "main.cpp",
      "README.md",
      ".github/workflows/ci.yml"
    ]

    missing = Enum.reject(required, fn file -> File.exists?(Path.join(dir, file)) end)

    if missing == [] do
      :ok
    else
      {:error, "Missing files: #{Enum.join(missing, ", ")}"}
    end
  end

  defp check_cpp_syntax(dir) do
    # Check that all .cpp files have basic valid structure
    cpp_files = Path.wildcard(Path.join(dir, "*.cpp"))

    errors =
      Enum.flat_map(cpp_files, fn file ->
        content = File.read!(file)

        checks = [
          {String.contains?(content, "#include"), "Missing includes"},
          {String.contains?(content, "::"), "No namespace usage"},
          {String.ends_with?(content, "\n"), "No trailing newline"}
        ]

        Enum.filter(checks, fn {pass, _msg} -> !pass end)
        |> Enum.map(fn {_, msg} -> "#{Path.basename(file)}: #{msg}" end)
      end)

    if errors == [] do
      :ok
    else
      {:error, Enum.join(errors, "; ")}
    end
  end

  defp check_cmake_valid(dir) do
    cmake_file = Path.join(dir, "CMakeLists.txt")
    content = File.read!(cmake_file)

    required_cmake = [
      "cmake_minimum_required",
      "project(",
      "find_package(CAF",
      "add_executable(",
      "target_link_libraries("
    ]

    missing = Enum.reject(required_cmake, &String.contains?(content, &1))

    if missing == [] do
      :ok
    else
      {:error, "CMakeLists.txt missing: #{Enum.join(missing, ", ")}"}
    end
  end

  defp check_callbacks(dir) do
    callback_files = Path.wildcard(Path.join(dir, "*_callbacks_impl.cpp"))

    if length(callback_files) > 0 do
      # Check that callback files have TODO comments
      all_have_todos =
        Enum.all?(callback_files, fn file ->
          content = File.read!(file)
          String.contains?(content, "TODO")
        end)

      if all_have_todos do
        :ok
      else
        {:error, "Some callback files missing TODO comments"}
      end
    else
      {:error, "No callback implementation files found"}
    end
  end

  defp check_ci_pipeline(dir) do
    ci_file = Path.join([dir, ".github", "workflows", "ci.yml"])

    if File.exists?(ci_file) do
      content = File.read!(ci_file)

      required_steps = [
        "conan install",
        "cmake",
        "cmake --build"
      ]

      missing = Enum.reject(required_steps, &String.contains?(content, &1))

      if missing == [] do
        :ok
      else
        {:error, "CI pipeline missing steps: #{Enum.join(missing, ", ")}"}
      end
    else
      {:error, "CI pipeline file not found"}
    end
  end

  defp check_catch2_tests(dir) do
    test_files = Path.wildcard(Path.join(dir, "test_*.cpp"))

    if length(test_files) > 0 do
      # Check that test files include Catch2
      all_use_catch2 =
        Enum.all?(test_files, fn file ->
          content = File.read!(file)
          String.contains?(content, "catch2/catch_test_macros.hpp")
        end)

      if all_use_catch2 do
        :ok
      else
        {:error, "Some test files don't use Catch2"}
      end
    else
      {:error, "No Catch2 test files found"}
    end
  end
end

CAFOutputValidator.run()

