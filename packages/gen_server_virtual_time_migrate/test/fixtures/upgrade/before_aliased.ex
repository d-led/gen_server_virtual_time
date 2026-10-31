defmodule MyApp.Build do
  alias ActorSimulation.PonyGenerator

  def build(simulation) do
    {:ok, files} = PonyGenerator.generate(simulation, project_name: "App")
    PonyGenerator.write_to_directory(files, "out/")
  end
end
