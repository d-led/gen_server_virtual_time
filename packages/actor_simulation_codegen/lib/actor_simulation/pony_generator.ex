defmodule ActorSimulation.PonyGenerator do
  @moduledoc """
  Deprecated: use `ActorSimulation.Codegen.Pony`.
  """

  @deprecated "use ActorSimulation.Codegen.Pony"
  defdelegate generate(simulation, opts \\ []), to: ActorSimulation.Codegen.Pony

  @deprecated "use ActorSimulation.Codegen.Pony"
  defdelegate write_to_directory(files, output_dir), to: ActorSimulation.Codegen.Pony
end
