defmodule MyApp.Build do
  alias ActorSimulation.Codegen.Pony

  def build(simulation) do
    {:ok, files} = Pony.generate(simulation, project_name: "App")
    Pony.write_to_directory(files, "out/")
  end
end
