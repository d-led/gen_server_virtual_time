defmodule MyApp.Clash do
  alias ActorSimulation.CAFGenerator
  alias ActorSimulation.Codegen.CAF

  def build(simulation), do: CAFGenerator.generate(simulation, project_name: "App")
end
