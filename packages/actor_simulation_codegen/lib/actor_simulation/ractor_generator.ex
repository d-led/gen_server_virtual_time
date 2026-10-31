defmodule ActorSimulation.RactorGenerator do
  @moduledoc """
  Deprecated: use `ActorSimulation.Codegen.Ractor`.
  """

  @deprecated "use ActorSimulation.Codegen.Ractor"
  defdelegate generate(simulation, opts \\ []), to: ActorSimulation.Codegen.Ractor

  @deprecated "use ActorSimulation.Codegen.Ractor"
  defdelegate write_to_directory(files, output_dir), to: ActorSimulation.Codegen.Ractor
end
