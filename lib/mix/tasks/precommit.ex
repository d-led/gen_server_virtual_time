defmodule Mix.Tasks.Precommit do
  @moduledoc """
  Runs all CI checks locally before committing.

  This task runs the same checks that CI runs, helping you catch issues
  before pushing to GitHub.

  ## Usage

      mix precommit           # Run all checks except Dialyzer
      mix precommit --all     # Run all checks including Dialyzer

  ## Checks performed

  1. Code formatting (`mix format`)
  2. Format verification (`mix format --check-formatted`)
  3. Compilation with warnings as errors
  4. Tests (`mix test`)
  5. Code quality (`mix credo --strict`)
  6. Documentation build (`mix docs`)
  7. Type checking (`mix dialyzer`) - only with --all flag

  ## Exit codes

  - 0: All checks passed
  - 1: One or more checks failed
  """

  use Mix.Task

  @shortdoc "Run all CI checks locally"

  @impl Mix.Task
  @dialyzer {:no_return, run: 1}
  def run(args) do
    run_dialyzer = "--all" in args

    IO.puts("\n🔍 Running pre-commit checks...\n")

    checks = [
      {"Formatting code", fn -> format_code() end},
      {"Checking formatting", fn -> check_formatting() end},
      {"Compiling with warnings as errors", fn -> compile_strict() end},
      {"Running tests", fn -> run_tests() end},
      {"Running Credo", fn -> run_credo() end},
      {"Building documentation", fn -> build_docs() end}
    ]

    checks =
      if run_dialyzer do
        checks ++ [{"Running Dialyzer (this may take a while)", fn -> run_dialyzer() end}]
      else
        checks
      end

    results = Enum.map(checks, fn {name, check_fn} -> run_check(name, check_fn) end)

    IO.puts("\n" <> String.duplicate("=", 80))

    if Enum.all?(results) do
      IO.puts("✅ All checks passed! Safe to commit.")
      IO.puts(String.duplicate("=", 80) <> "\n")
      System.halt(0)
    else
      IO.puts("❌ Some checks failed. Please fix the issues before committing.")
      IO.puts(String.duplicate("=", 80) <> "\n")
      System.halt(1)
    end
  end

  defp run_check(name, check_fn) do
    IO.write("  #{name}... ")

    case check_fn.() do
      :ok ->
        IO.puts("✅")
        true

      {:error, reason} ->
        IO.puts("❌")
        IO.puts("    Error: #{reason}")
        false
    end
  end

  defp format_code do
    case Mix.Task.run("format") do
      :ok -> :ok
      _ -> :ok
    end

    :ok
  end

  defp check_formatting do
    case System.cmd("mix", ["format", "--check-formatted"],
           stderr_to_stdout: true,
           into: IO.stream(:stdio, :line)
         ) do
      {_, 0} -> :ok
      _ -> {:error, "Code is not formatted. Run 'mix format' to fix."}
    end
  end

  defp compile_strict do
    # Clear previous compilation
    Mix.Task.clear()
    Mix.Task.reenable("compile")

    case System.cmd("mix", ["compile", "--warnings-as-errors"],
           stderr_to_stdout: true,
           env: [{"MIX_ENV", "test"}]
         ) do
      {_, 0} -> :ok
      _ -> {:error, "Compilation failed or has warnings"}
    end
  end

  defp run_tests do
    Mix.Task.clear()
    Mix.Task.reenable("test")

    # Capture output but don't show it unless there's an error
    case System.cmd("mix", ["test"],
           stderr_to_stdout: true,
           env: [{"MIX_ENV", "test"}]
         ) do
      {_, 0} -> :ok
      _ -> {:error, "Tests failed"}
    end
  end

  defp run_credo do
    case System.cmd("mix", ["credo", "--strict"], stderr_to_stdout: true) do
      {_, 0} -> :ok
      _ -> {:error, "Credo found issues"}
    end
  end

  defp build_docs do
    # Suppress output
    case System.cmd("mix", ["docs"], stderr_to_stdout: true) do
      {_, 0} -> :ok
      _ -> {:error, "Documentation build failed"}
    end
  end

  defp run_dialyzer do
    case System.cmd("mix", ["dialyzer"], stderr_to_stdout: true) do
      {_, 0} -> :ok
      _ -> {:error, "Dialyzer found issues"}
    end
  end
end
