defmodule MyApp.Generator do
  def export(simulation) do
    ActorSimulation.CAFGenerator.generate(simulation)
  end

  def build(simulation) do
    {simulation, ActorSimulation.new()}
  end
end
