defmodule ActorSimulation.VlingoGenerator do
  @moduledoc """
  Deprecated: use `ActorSimulation.Codegen.Vlingo`.
  """

  @deprecated "use ActorSimulation.Codegen.Vlingo"
  defdelegate generate(simulation, opts \\ []), to: ActorSimulation.Codegen.Vlingo

  @deprecated "use ActorSimulation.Codegen.Vlingo"
  defdelegate write_to_directory(files, output_dir), to: ActorSimulation.Codegen.Vlingo
end
