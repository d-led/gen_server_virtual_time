defmodule ActorSimulation.Definition do
  @moduledoc """
  Defines an actor's behavior in the simulation.

  ## Example

      iex> definition = ActorSimulation.Definition.new(:worker,
      ...>   send_pattern: {:periodic, 100, :tick},
      ...>   targets: [:supervisor])
      iex> definition.name
      :worker
      iex> definition.targets
      [:supervisor]

  """

  defstruct [
    :name,
    :send_pattern,
    :targets,
    :on_receive,
    :on_match,
    :initial_state
  ]

  def new(name, opts) do
    %__MODULE__{
      name: name,
      send_pattern: Keyword.get(opts, :send_pattern),
      targets: Keyword.get(opts, :targets, []),
      on_receive: Keyword.get(opts, :on_receive),
      on_match: Keyword.get(opts, :on_match, []),
      initial_state: Keyword.get(opts, :initial_state, %{})
    }
  end

  @doc """
  Matches a message against the on_match patterns and returns the response.
  Returns nil if no match.
  """
  def match_message(definition, msg) do
    Enum.find_value(definition.on_match, fn {pattern, response} ->
      case pattern do
        ^msg -> {:matched, response}
        _ when is_function(pattern, 1) ->
          if pattern.(msg), do: {:matched, response}, else: nil
        _ -> nil
      end
    end)
  end

  @doc """
  Calculates the interval in milliseconds for a send pattern.

  ## Examples

      iex> ActorSimulation.Definition.interval_for_pattern({:periodic, 100, :msg})
      100

      iex> ActorSimulation.Definition.interval_for_pattern({:rate, 10, :msg})
      100

      iex> ActorSimulation.Definition.interval_for_pattern({:burst, 5, 500, :msg})
      500

  """
  def interval_for_pattern({:periodic, interval, _message}), do: interval
  def interval_for_pattern({:rate, per_second, _message}), do: div(1000, per_second)
  def interval_for_pattern({:burst, _count, interval, _message}), do: interval
  def interval_for_pattern(nil), do: nil

  @doc """
  Gets the message(s) to send for a send pattern.

  ## Examples

      iex> ActorSimulation.Definition.messages_for_pattern({:periodic, 100, :tick})
      [:tick]

      iex> ActorSimulation.Definition.messages_for_pattern({:burst, 3, 500, :event})
      [:event, :event, :event]

  """
  def messages_for_pattern({:periodic, _interval, message}), do: [message]
  def messages_for_pattern({:rate, _per_second, message}), do: [message]
  def messages_for_pattern({:burst, count, _interval, message}) do
    List.duplicate(message, count)
  end
  def messages_for_pattern(nil), do: []
end
