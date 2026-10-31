defmodule ActorSimulation.OMNeTPPGenerator do
  @moduledoc """
  Deprecated: use `ActorSimulation.Codegen.OMNeTPP`.
  """

  @deprecated "use ActorSimulation.Codegen.OMNeTPP"
  defdelegate generate(simulation, opts \\ []), to: ActorSimulation.Codegen.OMNeTPP

  @deprecated "use ActorSimulation.Codegen.OMNeTPP"
  defdelegate write_to_directory(files, output_dir), to: ActorSimulation.Codegen.OMNeTPP
end
