defmodule SimulationMacros do
  @moduledoc """
  Macros for defining actor simulations with automatic source code generation.

  This eliminates code duplication by allowing you to define a simulation once
  and automatically generating both the executable code and its string representation.
  """

  @doc """
  Defines a simulation with automatic source code generation.

  ## Usage

      defsim simulation_name do
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:producer,
          send_pattern: {:periodic, 100, :data},
          targets: [:consumer]
        )
        |> ActorSimulation.add_actor(:consumer)
        |> ActorSimulation.run(duration: 1000)
      end

  This creates:
  - `simulation_name()` - function that returns the simulation
  - `simulation_name_source()` - function that returns the source code string
  """
  defmacro defsim(name, do: block) do
    quote do
      def unquote(name)() do
        unquote(block)
      end

      def unquote(:"#{name}_source")() do
        """
        simulation =
        #{Macro.to_string(block)}
        """
      end
    end
  end

  @doc """
  Defines a simulation with custom source code template.

  ## Usage

      defsim_with_template simulation_name, "Custom simulation setup" do
        ActorSimulation.new()
        |> ActorSimulation.add_actor(:custom_actor)
        |> ActorSimulation.run(duration: 500)
      end
  """
  defmacro defsim_with_template(name, template, do: block) do
    quote do
      def unquote(name)() do
        unquote(block)
      end

      def unquote(:"#{name}_source")() do
        unquote(template)
      end
    end
  end

  @doc """
  Helper macro for common simulation patterns.

  ## Usage

      defsim_pipeline "My Pipeline" do
        [
          source: {:periodic, 100, :data},
          stages: [:stage1, :stage2],
          sink: true
        ]
      end
  """
  defmacro defsim_pipeline(name, config) do
    quote do
      def unquote(name)() do
        config = unquote(config)

        simulation = ActorSimulation.new()

        # Add source
        simulation =
          simulation
          |> ActorSimulation.add_actor(:source,
            send_pattern: config[:source],
            targets: [List.first(config[:stages])]
          )

        # Add stages
        simulation =
          Enum.reduce(config[:stages], simulation, fn stage, acc ->
            ActorSimulation.add_actor(acc, stage, targets: [:sink])
          end)

        # Add sink if requested
        simulation =
          if config[:sink] do
            ActorSimulation.add_actor(simulation, :sink)
          else
            simulation
          end

        ActorSimulation.run(simulation, duration: 1000)
      end

      def unquote(:"#{name}_source")() do
        config = unquote(config)
        source_pattern = inspect(config[:source])
        stages = Enum.map_join(config[:stages], ", ", &inspect/1)

        """
        simulation =
          ActorSimulation.new()
          |> ActorSimulation.add_actor(:source,
            send_pattern: #{source_pattern},
            targets: [#{List.first(config[:stages]) |> inspect}]
          )
          |> ActorSimulation.add_actor(:stage1, targets: [:sink])
          |> ActorSimulation.add_actor(:stage2, targets: [:sink])
          |> ActorSimulation.add_actor(:sink)
          |> ActorSimulation.run(duration: 1000)
        """
      end
    end
  end
end
