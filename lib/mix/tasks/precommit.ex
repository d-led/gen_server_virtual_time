defmodule Mix.Tasks.Precommit do
  @moduledoc """
  Runs all CI checks locally before committing.

  This task runs the same checks that CI runs, helping you catch issues
  before pushing to GitHub.

  ## Usage

      mix precommit           # Run all checks except Dialyzer
      mix precommit --all     # Run all checks including Dialyzer and coverage

  ## Checks performed

  1. Code formatting (`mix format`)
  2. Markdown formatting (`prettier` for docs/)
  3. Format verification (`mix format --check-formatted`)
  4. Markdown format verification
  5. Compilation with warnings as errors
  6. Tests (`mix test`)
  7. Code quality (`mix credo --strict`)
  8. Documentation build (`mix docs`)
  9. Coverage report (`mix coveralls.html`) - only with --all flag
  10. Type checking (`mix dialyzer`) - only with --all flag

  ## Coverage reporting

  When run with `--all`, the task will display the total code coverage percentage
  and generate an HTML report in `cover/excoveralls.html`.

  ## Exit codes

  - 0: All checks passed
  - 1: One or more checks failed
  """

  use Mix.Task

  @shortdoc "Run all CI checks locally"

  @impl Mix.Task
  @dialyzer {:no_return, run: 1}
  def run(args) do
    run_all = "--all" in args

    IO.puts("\n🔍 Running pre-commit checks...\n")

    checks = [
      {"Formatting code", fn -> format_code() end},
      {"Formatting markdown files", fn -> format_markdown() end},
      {"Checking formatting", fn -> check_formatting() end},
      {"Checking markdown formatting", fn -> check_markdown_formatting() end},
      {"Compiling with warnings as errors", fn -> compile_strict() end},
      {"Running tests", fn -> run_tests() end},
      # Optionally run diagram-generation tests (HTML reports)
      # Only when --all flag is provided, to avoid slowing down regular precommit
      {"Running diagram-generation tests",
       fn -> if run_all, do: run_diagram_tests(), else: :ok end},
      {"Running Credo", fn -> run_credo() end},
      {"Building documentation", fn -> build_docs() end}
    ]

    checks =
      if run_all do
        checks ++
          [
            {"Running combined coverage analysis", fn -> run_coverage() end},
            {"Running Dialyzer (this may take a while)", fn -> run_dialyzer() end}
          ]
      else
        checks
      end

    results = Enum.map(checks, fn {name, check_fn} -> run_check(name, check_fn) end)

    IO.puts("\n" <> String.duplicate("=", 80))

    if Enum.all?(results) do
      IO.puts("✅ All checks passed! Safe to commit.")

      if run_all do
        IO.puts("\n📊 Coverage report generated!")
        print_coverage_with_file_link()
      end

      IO.puts(String.duplicate("=", 80) <> "\n")
      System.halt(0)
    else
      IO.puts("❌ Some checks failed. Please fix the issues before committing.")

      # Still show coverage if available, even when other checks fail
      if run_all do
        print_coverage_summary()
      end

      IO.puts(String.duplicate("=", 80) <> "\n")
      System.halt(1)
    end
  end

  defp print_coverage_with_file_link do
    case Process.get(:coverage_percentage) do
      nil ->
        IO.puts("📂 Open: cover/excoveralls.html")

      percentage ->
        coverage_value = String.to_float(percentage)

        if coverage_value >= 70.0 do
          IO.puts("📈 Total coverage: #{percentage}% ✅")
        else
          IO.puts("⚠️  Total coverage: #{percentage}% (below 70% threshold)")
        end

        IO.puts("📂 Open: cover/excoveralls.html")
    end
  end

  defp print_coverage_summary do
    case Process.get(:coverage_percentage) do
      nil ->
        :ok

      percentage ->
        coverage_value = String.to_float(percentage)

        if coverage_value >= 70.0 do
          IO.puts("📈 Coverage: #{percentage}% ✅")
        else
          IO.puts("⚠️  Coverage: #{percentage}% (below 70% threshold)")
        end
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

  defp run_diagram_tests do
    Mix.Task.clear()
    Mix.Task.reenable("test")

    case System.cmd("mix", ["test", "--include", "diagram_generation"],
           stderr_to_stdout: true,
           env: [{"MIX_ENV", "test"}]
         ) do
      {_, 0} -> :ok
      _ -> {:error, "Diagram-generation tests failed"}
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

  defp run_coverage do
    # Clean old coverage data
    File.rm_rf("cover")
    File.mkdir_p!("cover")

    # Run coverage exports - ignore exit codes as individual test suites may have low coverage
    # Exit codes 0, 1, 2 are all OK (0=success, 1=below threshold, 2=below threshold with warning)
    with {_, code1} when code1 in [0, 1, 2] <-
           System.cmd("mix", ["coveralls", "--export-coverage", "fast"],
             stderr_to_stdout: true,
             env: [{"MIX_ENV", "test"}]
           ),
         {_, code2} when code2 in [0, 1, 2] <-
           System.cmd("mix", ["coveralls", "--only", "slow", "--export-coverage", "slow"],
             stderr_to_stdout: true,
             env: [{"MIX_ENV", "test"}]
           ),
         {_, code3} when code3 in [0, 1, 2] <-
           System.cmd(
             "mix",
             ["coveralls", "--only", "diagram_generation", "--export-coverage", "diagram"],
             stderr_to_stdout: true,
             env: [{"MIX_ENV", "test"}]
           ),
         {_, code_test_cov} when code_test_cov in [0, 1, 2] <-
           System.cmd("mix", ["test.coverage"],
             stderr_to_stdout: true,
             env: [{"MIX_ENV", "test"}]
           ),
         {output, code4} when code4 in [0, 1, 2] <-
           System.cmd("mix", ["coveralls.html", "--import-cover", "cover"],
             stderr_to_stdout: true,
             env: [{"MIX_ENV", "test"}]
           ) do
      # Extract coverage percentage from output
      extract_and_store_coverage(output)
      :ok
    else
      {_, bad_code} ->
        {:error, "Coverage analysis failed with exit code #{bad_code}"}

      _ ->
        {:error, "Coverage analysis failed"}
    end
  end

  defp extract_and_store_coverage(_output) do
    # Extract coverage percentage from the HTML file instead of console output
    html_path = "cover/excoveralls.html"

    if File.exists?(html_path) do
      case File.read(html_path) do
        {:ok, content} ->
          # Look for the total coverage in the HTML file
          # Format: <div class='percentage'>XX.X</div>
          case Regex.run(~r/<div class='percentage'>(\d+\.?\d*)<\/div>/, content) do
            [_, percentage] ->
              Process.put(:coverage_percentage, percentage)

            _ ->
              nil
          end

        _ ->
          nil
      end
    end
  end

  defp format_markdown do
    # Check if prettier is available (via npx)
    case System.cmd("npx", ["--version"], stderr_to_stdout: true) do
      {_, 0} ->
        # Format markdown files in docs/ directory
        case System.cmd(
               "npx",
               [
                 "--yes",
                 "prettier@latest",
                 "--write",
                 "--prose-wrap",
                 "always",
                 "docs/**/*.md",
                 "*.md"
               ],
               stderr_to_stdout: true
             ) do
          {_, 0} -> :ok
          _ -> {:error, "Failed to format markdown files"}
        end

      _ ->
        IO.puts("    Warning: npx not available, skipping markdown formatting")
        :ok
    end
  end

  defp check_markdown_formatting do
    # Check if prettier is available (via npx)
    case System.cmd("npx", ["--version"], stderr_to_stdout: true) do
      {_, 0} ->
        # Check markdown files in docs/ directory
        case System.cmd(
               "npx",
               [
                 "--yes",
                 "prettier@latest",
                 "--check",
                 "--prose-wrap",
                 "always",
                 "docs/**/*.md",
                 "*.md"
               ],
               stderr_to_stdout: true
             ) do
          {_, 0} -> :ok
          _ -> {:error, "Markdown files are not formatted. Run 'mix precommit' to fix."}
        end

      _ ->
        IO.puts("    Warning: npx not available, skipping markdown format check")
        :ok
    end
  end
end
