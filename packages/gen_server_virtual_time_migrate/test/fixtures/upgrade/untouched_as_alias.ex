defmodule MyApp.AsAlias do
  alias ActorSimulation.PhonyGenerator, as: Gen

  def build(simulation), do: Gen.generate(simulation, project_name: "App")
end
