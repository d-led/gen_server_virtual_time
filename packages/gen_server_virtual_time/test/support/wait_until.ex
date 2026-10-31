defmodule WaitUntil do
  @moduledoc """
  Test helper for waiting on an observable effect of another process.

  Prefer this to a fixed `Process.sleep/1` before asserting: a sleep guesses how
  long the effect takes, so a loaded machine turns a correct test into a flaky
  one. Polling the effect itself makes the test slower under load instead of
  wrong.

  ## Example

      wait_until(fn -> VirtualClock.scheduled_count(clock) == 1 end)
  """

  import ExUnit.Assertions, only: [flunk: 1]

  @default_attempts 500

  @doc """
  Polls `condition` every millisecond until it returns a truthy value.

  Fails the test if the condition is still false after `attempts` milliseconds.
  """
  def wait_until(condition, attempts \\ @default_attempts)

  def wait_until(condition, attempts) when is_function(condition, 0) do
    poll(condition, attempts)
  end

  defp poll(condition, attempts_left) do
    cond do
      condition.() ->
        :ok

      attempts_left <= 0 ->
        flunk("condition was not met within #{@default_attempts}ms")

      true ->
        Process.sleep(1)
        poll(condition, attempts_left - 1)
    end
  end
end
