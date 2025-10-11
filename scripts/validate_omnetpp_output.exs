#!/usr/bin/env elixir

# Script to validate generated OMNeT++ code
# Usage: mix run scripts/validate_omnetpp_output.exs

defmodule OMNeTPPValidator do
  @moduledoc """
  Validates generated OMNeT++ code for correctness and completeness.
  """

  def run do
    IO.puts """
    ╔═══════════════════════════════════════════════════════════╗
    ║  Validating OMNeT++ Generated Code                        ║
    ╚═══════════════════════════════════════════════════════════╝
    """

    examples = [
      "examples/omnetpp_pubsub",
      "examples/omnetpp_pipeline",
      "examples/omnetpp_burst",
      "examples/omnetpp_loadbalanced"
    ]

    results = Enum.map(examples, &validate_project/1)

    # Summary
    IO.puts """

    ╔═══════════════════════════════════════════════════════════╗
    ║  Validation Summary                                        ║
    ╚═══════════════════════════════════════════════════════════╝
    """

    total = length(results)
    passed = Enum.count(results, fn {status, _, _} -> status == :ok end)
    total_errors = Enum.sum(Enum.map(results, fn {_, errors, _} -> errors end))

    IO.puts "Projects validated: #{total}"
    IO.puts "Passed: #{passed}/#{total}"
    IO.puts "Total errors: #{total_errors}"

    if passed == total and total_errors == 0 do
      IO.puts "\n✅ All validations passed!"
      exit({:shutdown, 0})
    else
      IO.puts "\n❌ Validation failed"
      exit({:shutdown, 1})
    end
  end

  defp validate_project(dir) do
    project_name = Path.basename(dir)
    IO.puts "\n📋 Validating: #{project_name}"
    IO.puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    errors = []

    # Check directory exists
    if !File.exists?(dir) do
      IO.puts "❌ Directory not found: #{dir}"
      {:error, 1, []}
    else

    # Required files
    required_files = [
      {"*.ned", "NED topology file"},
      {"CMakeLists.txt", "CMake configuration"},
      {"conanfile.txt", "Conan configuration"},
      {"omnetpp.ini", "OMNeT++ configuration"}
    ]

    errors = Enum.reduce(required_files, errors, fn {pattern, description}, acc ->
      files = Path.wildcard(Path.join(dir, pattern))
      if Enum.empty?(files) do
        IO.puts "❌ Missing: #{description}"
        acc ++ [description]
      else
        IO.puts "✅ Found: #{description}"
        acc
      end
    end)

    # Check C++ files
    h_files = Path.wildcard(Path.join(dir, "*.h"))
    cc_files = Path.wildcard(Path.join(dir, "*.cc"))

    IO.puts "✅ C++ headers: #{length(h_files)}"
    IO.puts "✅ C++ sources: #{length(cc_files)}"

    errors = if length(h_files) == 0 or length(cc_files) == 0 do
      IO.puts "❌ Missing C++ files"
      errors ++ ["Missing C++ files"]
    else
      errors
    end

    # Validate C++ file content
    errors = Enum.reduce(h_files, errors, fn file, acc ->
      content = File.read!(file)
      fname = Path.basename(file)
      
      cond do
        !String.contains?(content, "#ifndef") ->
          IO.puts "❌ #{fname}: Missing include guard"
          acc ++ ["#{fname}: Missing include guard"]
        
        !String.contains?(content, "cSimpleModule") ->
          IO.puts "❌ #{fname}: Not a cSimpleModule"
          acc ++ ["#{fname}: Not a cSimpleModule"]
        
        !String.contains?(content, "virtual void initialize()") ->
          IO.puts "❌ #{fname}: Missing initialize()"
          acc ++ ["#{fname}: Missing initialize()"]
        
        true ->
          acc
      end
    end)

    # Validate C++ source files
    errors = Enum.reduce(cc_files, errors, fn file, acc ->
      content = File.read!(file)
      fname = Path.basename(file)
      module_name = String.replace(fname, ".cc", "")
      
      cond do
        !String.contains?(content, "Define_Module(#{module_name})") ->
          IO.puts "❌ #{fname}: Missing Define_Module"
          acc ++ ["#{fname}: Missing Define_Module"]
        
        !String.contains?(content, "void #{module_name}::initialize()") ->
          IO.puts "❌ #{fname}: Missing initialize() implementation"
          acc ++ ["#{fname}: Missing initialize() implementation"]
        
        !String.contains?(content, "void #{module_name}::handleMessage") ->
          IO.puts "❌ #{fname}: Missing handleMessage() implementation"
          acc ++ ["#{fname}: Missing handleMessage() implementation"]
        
        true ->
          acc
      end
    end)

    # Validate NED file
    ned_files = Path.wildcard(Path.join(dir, "*.ned"))
    errors = if !Enum.empty?(ned_files) do
      ned_content = File.read!(hd(ned_files))
      
      cond do
        !String.contains?(ned_content, "simple ") ->
          IO.puts "❌ NED: No simple module definitions"
          errors ++ ["NED: No simple module definitions"]
        
        !String.contains?(ned_content, "network ") ->
          IO.puts "❌ NED: No network definition"
          errors ++ ["NED: No network definition"]
        
        !String.contains?(ned_content, "submodules:") ->
          IO.puts "❌ NED: No submodules section"
          errors ++ ["NED: No submodules section"]
        
        true ->
          IO.puts "✅ NED file structure valid"
          errors
      end
    else
      errors
    end

    # Validate CMakeLists.txt
    cmake_file = Path.join(dir, "CMakeLists.txt")
    if File.exists?(cmake_file) do
      cmake_content = File.read!(cmake_file)
      
      required_cmake = [
        "cmake_minimum_required",
        "project(",
        "find_package(OMNeT++",
        "add_executable",
        "target_link_libraries"
      ]
      
      errors = Enum.reduce(required_cmake, errors, fn cmd, acc ->
        if String.contains?(cmake_content, cmd) do
          acc
        else
          IO.puts "❌ CMakeLists.txt: Missing #{cmd}"
          acc ++ ["CMakeLists.txt: Missing #{cmd}"]
        end
      end)
      
      if length(errors) == length(required_cmake) do
        IO.puts "✅ CMakeLists.txt valid"
      end
    end

    # Validate omnetpp.ini
    ini_file = Path.join(dir, "omnetpp.ini")
    errors = if File.exists?(ini_file) do
      ini_content = File.read!(ini_file)
      
      cond do
        !String.contains?(ini_content, "[General]") ->
          IO.puts "❌ omnetpp.ini: Missing [General] section"
          errors ++ ["omnetpp.ini: Missing [General] section"]
        
        !String.contains?(ini_content, "network =") ->
          IO.puts "❌ omnetpp.ini: Missing network configuration"
          errors ++ ["omnetpp.ini: Missing network configuration"]
        
        true ->
          IO.puts "✅ omnetpp.ini valid"
          errors
      end
    else
      errors
    end

    # Check for timestamps (should not have any)
    all_files = Path.wildcard(Path.join(dir, "*.{h,cc,ned}"))
    timestamp_violations = Enum.filter(all_files, fn file ->
      content = File.read!(file)
      String.match?(content, ~r/\d{4}-\d{2}-\d{2}/) or 
      String.contains?(content, "Generated on:")
    end)

    if !Enum.empty?(timestamp_violations) do
      IO.puts "⚠️  Warning: Files contain timestamps:"
      Enum.each(timestamp_violations, fn file ->
        IO.puts "     - #{Path.basename(file)}"
      end)
    else
      IO.puts "✅ No timestamps found (good for version control)"
    end

    error_count = length(errors)
    if error_count == 0 do
      IO.puts "\n✅ #{project_name}: All checks passed"
      {:ok, 0, []}
    else
      IO.puts "\n❌ #{project_name}: #{error_count} errors found"
      {:error, error_count, errors}
    end
    end
  end
end

# Run validation
OMNeTPPValidator.run()

