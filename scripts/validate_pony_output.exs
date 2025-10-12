#!/usr/bin/env elixir

# Script to validate Pony generator output
# Usage: mix run scripts/validate_pony_output.exs

defmodule PonyOutputValidator do
  @moduledoc """
  Validates that the Pony generator produces valid, compilable Pony code.
  """

  def run do
    IO.puts("""
    ╔═══════════════════════════════════════════════════════════╗
    ║  Validating Pony Generator Output                         ║
    ╚═══════════════════════════════════════════════════════════╝
    """)

    examples = [
      "examples/pony_pubsub",
      "examples/pony_pipeline",
      "examples/pony_burst",
      "examples/pony_loadbalanced"
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
      {:pony_syntax, &check_pony_syntax/1},
      {:makefile_valid, &check_makefile/1},
      {:callbacks_present, &check_callbacks/1},
      {:ci_pipeline, &check_ci_pipeline/1},
      {:ponytest_tests, &check_ponytest_tests/1}
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
      "main.pony",
      "corral.json",
      "Makefile",
      "README.md",
      ".github/workflows/ci.yml",
      "test/test.pony"
    ]

    missing = Enum.reject(required, fn file -> File.exists?(Path.join(dir, file)) end)

    if missing == [] do
      :ok
    else
      {:error, "Missing files: #{Enum.join(missing, ", ")}"}
    end
  end

  defp check_pony_syntax(dir) do
    # Check that all .pony files have basic valid structure
    pony_files = Path.wildcard(Path.join(dir, "*.pony"))

    errors =
      Enum.flat_map(pony_files, fn file ->
        content = File.read!(file)

        checks = [
          {String.contains?(content, "actor ") or String.contains?(content, "class ") or
             String.contains?(content, "trait "), "No actor/class/trait definition"},
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

  defp check_makefile(dir) do
    makefile = Path.join(dir, "Makefile")
    content = File.read!(makefile)

    required = [
      "ponyc",
      "test",
      "clean",
      "corral fetch"
    ]

    missing = Enum.reject(required, &String.contains?(content, &1))

    if missing == [] do
      :ok
    else
      {:error, "Makefile missing: #{Enum.join(missing, ", ")}"}
    end
  end

  defp check_callbacks(dir) do
    callback_files = Path.wildcard(Path.join(dir, "*_callbacks.pony"))

    if length(callback_files) > 0 do
      # Check that callback files have trait definitions
      all_have_traits =
        Enum.all?(callback_files, fn file ->
          content = File.read!(file)
          String.contains?(content, "trait ") and String.contains?(content, "CallbacksImpl")
        end)

      if all_have_traits do
        :ok
      else
        {:error, "Some callback files missing trait definitions"}
      end
    else
      {:error, "No callback files found"}
    end
  end

  defp check_ci_pipeline(dir) do
    ci_file = Path.join([dir, ".github", "workflows", "ci.yml"])

    if File.exists?(ci_file) do
      content = File.read!(ci_file)

      required_steps = [
        "ponyup",
        "corral fetch",
        "ponyc"
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

  defp check_ponytest_tests(dir) do
    test_file = Path.join([dir, "test", "test.pony"])

    if File.exists?(test_file) do
      content = File.read!(test_file)

      required = [
        "use \"ponytest\"",
        "class iso",
        "UnitTest",
        "TestHelper"
      ]

      missing = Enum.reject(required, &String.contains?(content, &1))

      if missing == [] do
        :ok
      else
        {:error, "Test file missing: #{Enum.join(missing, ", ")}"}
      end
    else
      {:error, "No PonyTest test file found"}
    end
  end
end

PonyOutputValidator.run()

