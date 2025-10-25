defmodule Mix.Tasks.Cover.Show do
  @moduledoc """
  Runs comprehensive test coverage analysis including all tests.

  This task runs ALL tests (including slow and diagram generation tests)
  and generates an HTML coverage report that opens in the browser.

  ## Usage

      mix coverage

  ## What it does

  1. Runs all tests with coverage enabled (no exclusions)
  2. Generates HTML coverage report
  3. Opens the report in the default browser (platform-specific)

  ## Platform Support

  - **macOS**: Uses `open` command
  - **Linux**: Uses `xdg-open` command
  - **Windows**: Uses `start` command
  - **Fallback**: Prints the file path if no command is available

  ## Output

  The HTML report is generated in `cover/excoveralls.html` and includes:
  - Line-by-line coverage analysis
  - Coverage percentages per module
  - Overall project coverage statistics
  - Interactive browsing of source code with coverage highlighting
  """

  use Mix.Task

  @shortdoc "Run comprehensive test coverage analysis and show report"

  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("🔍 Running comprehensive test coverage analysis...")
    IO.puts("📊 This includes ALL tests (slow, diagram generation, etc.)")
    IO.puts("")

    # Run all tests with coverage enabled (no exclusions)
    case run_tests_with_coverage() do
      :ok ->
        IO.puts("✅ All tests passed!")
        generate_and_open_report()

      {:error, reason} ->
        IO.puts("❌ Tests failed: #{reason}")
        System.halt(1)
    end
  end

  defp run_tests_with_coverage do
    IO.puts("🧪 Running all tests with coverage...")
    IO.puts("   📊 Including: fast tests, slow tests, diagram generation, ridiculous tests")

    # Run tests with coverage, no exclusions - this includes ALL test tags
    case System.cmd("mix", ["test", "--cover"],
           stderr_to_stdout: true,
           env: [{"MIX_ENV", "test"}]
         ) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        IO.puts("Test failures:")
        IO.puts(output)
        {:error, "Tests failed"}
    end
  end

  defp generate_and_open_report do
    IO.puts("📈 Generating HTML coverage report...")

    # Generate HTML report using coveralls.html which respects coveralls.json settings
    case System.cmd("mix", ["coveralls.html"],
           stderr_to_stdout: true,
           env: [{"MIX_ENV", "test"}]
         ) do
      {_output, exit_code} when exit_code in [0, 1, 2] ->
        # Exit codes 0, 1, 2 are all OK (0=success, 1=below threshold, 2=below threshold with warning)
        # We ignore threshold failures since this is just for viewing coverage
        open_html_report()

      {output, _exit_code} ->
        IO.puts("❌ Failed to generate coverage report:")
        IO.puts(output)
        System.halt(1)
    end
  end

  defp open_html_report do
    report_path = "cover/excoveralls.html"

    if File.exists?(report_path) do
      IO.puts("📊 Coverage report generated: #{Path.absname(report_path)}")
      IO.puts("🌐 Opening in browser...")

      case open_in_browser(report_path) do
        {_, 0} ->
          IO.puts("✅ Report opened successfully!")
          IO.puts("")
          IO.puts("📋 Coverage Summary:")
          print_coverage_summary()

        {_, _exit_code} ->
          IO.puts("⚠️  Could not open browser automatically")
          IO.puts("📁 Report available at: #{Path.absname(report_path)}")
      end
    else
      IO.puts("❌ Coverage report not found at #{report_path}")
      System.halt(1)
    end
  end

  defp open_in_browser(file_path) do
    case :os.type() do
      {:unix, :darwin} ->
        # macOS
        System.cmd("open", [file_path])

      {:win32, _} ->
        # Windows
        System.cmd("start", [file_path])

      {:unix, _} ->
        # Linux and other Unix-like systems
        System.cmd("xdg-open", [file_path])
    end
  end

  defp print_coverage_summary do
    # Just point to the HTML report - no need for JSON parsing
    IO.puts("   📊 Coverage data available in HTML report")
  end
end
