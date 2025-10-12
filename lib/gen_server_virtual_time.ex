defmodule GenServerVirtualTime do
  @moduledoc """
  A library for testing time-dependent GenServers and simulating actor systems using virtual time.

  This library provides two main capabilities:

  1. **VirtualTimeGenServer**: A drop-in replacement for GenServer that supports virtual time,
     allowing you to test time-dependent behaviors instantly without waiting for real time to pass.

  2. **ActorSimulation**: A DSL for defining and simulating complex actor systems with message
     rates, patterns, and comprehensive statistics collection.

  ## Quick Example

      # Define a time-dependent GenServer
      defmodule MyServer do
        use VirtualTimeGenServer

        def init(_) do
          VirtualTimeGenServer.send_after(self(), :tick, 1000)
          {:ok, %{count: 0}}
        end

        def handle_info(:tick, state) do
          {:noreply, %{state | count: state.count + 1}}
        end
      end

      # Test it with virtual time (instant!)
      test "ticks 10 times in 10 seconds" do
        {:ok, clock} = VirtualClock.start_link()
        VirtualTimeGenServer.set_virtual_clock(clock)

        {:ok, server} = MyServer.start_link(nil)
        VirtualClock.advance(clock, 10_000)  # Instant!

        assert get_count(server) == 10
      end

  ## Modules

  - `VirtualClock` - Manages virtual time and scheduled events
  - `VirtualTimeGenServer` - GenServer with virtual time support
  - `ActorSimulation` - DSL for actor system simulation

  See the README for comprehensive examples and usage patterns.
  """

  @doc """
  Returns the version of the library.
  """
  def version, do: Mix.Project.config()[:version]
end
