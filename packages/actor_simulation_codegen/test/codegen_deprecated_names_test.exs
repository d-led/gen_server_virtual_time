defmodule Codegen.DeprecatedNamesTest do
  use ExUnit.Case, async: true

  @shims [
    {ActorSimulation.CAFGenerator, ActorSimulation.Codegen.CAF},
    {ActorSimulation.OMNeTPPGenerator, ActorSimulation.Codegen.OMNeTPP},
    {ActorSimulation.PhonyGenerator, ActorSimulation.Codegen.Phony},
    {ActorSimulation.PonyGenerator, ActorSimulation.Codegen.Pony},
    {ActorSimulation.RactorGenerator, ActorSimulation.Codegen.Ractor},
    {ActorSimulation.VlingoGenerator, ActorSimulation.Codegen.Vlingo}
  ]

  describe "the names a 1.0 project already uses" do
    test "generate exactly what the new names generate" do
      simulation =
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:sender,
          send_pattern: {:periodic, 100, :msg},
          targets: [:receiver]
        )
        |> ActorSimulation.add_actor(:receiver)

      opts = [project_name: "Deprecated"]

      # `apply/3`, so the test itself does not trip the deprecation warning.
      # credo:disable-for-next-line Credo.Check.Refactor.Apply
      assert apply(ActorSimulation.CAFGenerator, :generate, [simulation, opts]) ==
               ActorSimulation.Codegen.CAF.generate(simulation, opts)
    end

    test "warn at compile time, and say what to use instead" do
      for {{old, new}, index} <- Enum.with_index(@shims) do
        {_module, diagnostics} =
          Code.with_diagnostics(fn ->
            Code.compile_string("""
            defmodule DeprecatedNameProbe#{index} do
              def run(simulation), do: #{inspect(old)}.generate(simulation, project_name: "x")
            end
            """)
          end)

        assert Enum.any?(diagnostics, fn %{message: message} ->
                 message =~ "is deprecated" and message =~ inspect(new)
               end),
               "expected #{inspect(old)} to warn about #{inspect(new)}: #{inspect(diagnostics)}"
      end
    end
  end
end
