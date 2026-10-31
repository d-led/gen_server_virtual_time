defmodule GenServerVirtualTime do
  @moduledoc """
  Virtual time for `GenServer` and `:gen_statem`: test time-dependent processes
  by advancing a clock a test owns, instead of sleeping through the timeline.

  This package is the clock and the OTP wrappers, and nothing else. The rest of
  the library is published separately, with the same module names, so what you
  need is a dependency rather than a rewrite:

  | Package | Add it when |
  | --- | --- |
  | `gen_server_virtual_time` (this one) | you test code with timers |
  | `actor_simulation` | you model parts of a system talking to each other |
  | `actor_simulation_codegen` | you want the same model in C++, Go, Pony, Rust, Java or OMNeT++ |

  `mix virtual_time.doctor` reads a project and says which of them a missing
  module needs.

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

  - `VirtualClock` - the virtual timeline and its scheduled events
  - `VirtualTimeGenServer` - a `GenServer` that schedules on that timeline
  - `VirtualTimeGenStateMachine` - the same for `:gen_statem`
  - `VirtualTimeGenServer.Instrumentation` - the port for measuring a server
  - `VirtualTimeGenServer.Doctor` - reports modules a project is missing

  See the README for examples and the design docs for the clock.
  """

  @app_version Mix.Project.config()[:version]

  @doc """
  Returns the version of the library.
  """
  def version, do: @app_version
end
