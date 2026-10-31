defmodule ActorSimulation.CAFGenerator do
  @moduledoc """
  Deprecated: use `ActorSimulation.Codegen.CAF`.

  Kept for one major version so code written against 1.0 keeps compiling. It
  forwards everything, so the behaviour is the same and the only thing to change
  is the name.
  """

  @deprecated "use ActorSimulation.Codegen.CAF"
  defdelegate generate(simulation, opts \\ []), to: ActorSimulation.Codegen.CAF

  @deprecated "use ActorSimulation.Codegen.CAF"
  defdelegate write_to_directory(files, output_dir), to: ActorSimulation.Codegen.CAF
end
