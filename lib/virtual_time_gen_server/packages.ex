defmodule VirtualTimeGenServer.Packages do
  @moduledoc """
  Which package of this library family owns a module, and what a project has to
  add when the module is missing.

  The library is published as several packages that share one version. A module
  keeps its name when it changes package, so a project that misses one of them
  only has to add a dependency — this table is what lets
  `mix virtual_time.doctor` say which one, instead of leaving a bare
  `module ActorSimulation is not available` in the build output.
  """

  @type package :: :actor_simulation | :actor_simulation_codegen

  @families [
    %{
      package: :actor_simulation,
      dependency: ~s|{:actor_simulation, "~> 1.0"}|,
      modules: [
        "ActorSimulation",
        "ActorSimulation.Actor",
        "ActorSimulation.Definition",
        "ActorSimulation.GeneratorMetadata",
        "ActorSimulation.MermaidReportGenerator",
        "ActorSimulation.Observer",
        "ActorSimulation.Stats"
      ]
    },
    %{
      package: :actor_simulation_codegen,
      dependency: ~s|{:actor_simulation_codegen, "~> 1.0"}|,
      modules: [
        "ActorSimulation.CAFGenerator",
        "ActorSimulation.GeneratorUtils",
        "ActorSimulation.OMNeTPPGenerator",
        "ActorSimulation.PhonyGenerator",
        "ActorSimulation.PonyGenerator",
        "ActorSimulation.RactorGenerator",
        "ActorSimulation.TemplateVersions",
        "ActorSimulation.VlingoGenerator"
      ]
    }
  ]

  # Calls that no longer exist, and what to write instead. The port replaced the
  # process-dictionary statistics in 1.0.
  @removed [
    %{
      module: "VirtualTimeGenServer",
      function: "enable_stats_tracking",
      replacement:
        "start_link(..., instrumentation: MyObserver) for a server, instrument/1 for a process"
    },
    %{
      module: "VirtualTimeGenServer",
      function: "get_process_stats",
      replacement: "VirtualTimeGenServer.snapshot/1, read by the observer you installed"
    },
    %{
      module: "VirtualTimeGenServer",
      function: "generate_incoming_trace_event",
      replacement: "an observer's on_receive/2 callback"
    },
    %{
      module: "VirtualTimeGenServer",
      function: "set_global_trace_collector",
      replacement: "the :instrumentation start option, or instrument/1"
    },
    %{
      module: "VirtualTimeGenServer",
      function: "get_global_trace_collector",
      replacement: "the observer configured with instrument/1"
    }
  ]

  @doc "Every package that is published next to this one."
  @spec packages() :: [package]
  def packages, do: Enum.map(@families, & &1.package)

  @doc """
  The package that owns `module`, or `nil` when the module belongs to this
  package or to nothing we know.

  A module matches a family entry when it is that entry's module or a module
  under it. The most specific entry wins, so `ActorSimulation.CAFGenerator` is
  the codegen package's even though `ActorSimulation` is the simulation's.
  """
  @spec owner(String.t()) :: package | nil
  def owner(module) when is_binary(module) do
    @families
    |> Enum.flat_map(fn family -> owned_lengths(family, module) end)
    |> Enum.max_by(&elem(&1, 0), fn -> nil end)
    |> case do
      nil -> nil
      {_length, package} -> package
    end
  end

  @doc "The dependency line a project adds for `package`."
  @spec dependency(package) :: String.t()
  def dependency(package) do
    @families
    |> Enum.find(&(&1.package == package))
    |> Map.fetch!(:dependency)
  end

  @doc """
  What to write instead of a call that no longer exists, or `nil` when the call
  is fine.
  """
  @spec removed_api(String.t(), String.t() | nil) :: String.t() | nil
  def removed_api(_module, nil), do: nil

  def removed_api(module, function) do
    Enum.find_value(@removed, fn removed ->
      if removed.module == module and removed.function == function do
        removed.replacement
      end
    end)
  end

  defp owned_lengths(family, module) do
    family.modules
    |> Enum.filter(&owns?(&1, module))
    |> Enum.map(&{String.length(&1), family.package})
  end

  defp owns?(owned, module), do: module == owned or String.starts_with?(module, owned <> ".")
end
