defmodule MyApp.Pipeline do
  def render(simulation) do
    {:ok, files} = ActorSimulation.CAFGenerator.generate(simulation, project_name: "App")
    ActorSimulation.CAFGenerator.write_to_directory(files, "out/")
  end
end
