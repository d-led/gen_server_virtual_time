defmodule ActorSimulation.PhonyGenerator do
  @moduledoc """
  Deprecated: use `ActorSimulation.Codegen.Phony`.
  """

  @deprecated "use ActorSimulation.Codegen.Phony"
  defdelegate generate(simulation, opts \\ []), to: ActorSimulation.Codegen.Phony

  @deprecated "use ActorSimulation.Codegen.Phony"
  defdelegate write_to_directory(files, output_dir), to: ActorSimulation.Codegen.Phony
end
