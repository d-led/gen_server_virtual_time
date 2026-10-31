defmodule Mix.Tasks.Templates.Upgrade do
  @shortdoc "Deprecated: use mix actor_simulation.upgrade"

  @moduledoc """
  Deprecated: use `mix actor_simulation.upgrade`.

  Kept so a habit or a script does not break; it forwards everything and prints
  what to type instead.
  """

  use Mix.Task

  @requirements ["compile"]

  @impl Mix.Task
  def run(args) do
    Mix.shell().info("mix templates.upgrade is now mix actor_simulation.upgrade — forwarding.")
    Mix.Task.run("actor_simulation.upgrade", args)
  end
end
