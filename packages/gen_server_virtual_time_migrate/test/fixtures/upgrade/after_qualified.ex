defmodule MyApp.Pipeline do
  def render(simulation) do
    {:ok, files} = ActorSimulation.Codegen.CAF.generate(simulation, project_name: "App")
    ActorSimulation.Codegen.CAF.write_to_directory(files, "out/")
  end
end
