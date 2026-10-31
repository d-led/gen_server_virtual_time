defmodule VirtualTimeGenServer.Instrumentation do
  @moduledoc """
  A port for observing what an instrumented process does.

  The virtual clock and the server wrappers know how to hand an event to an
  observer and nothing about what the observer does with it. That separation is
  the point: measuring a system — counters, traces, diagrams — is a different
  concern from controlling its time, and a library that owns the clock should
  not have to know what a counter is.

  An observer is installed per process:

    * with the `:instrumentation` option of `VirtualTimeGenServer.start_link/3`,
      which instruments the started server, and enables `on_send/2` for the
      messages that server sends itself;
    * with `VirtualTimeGenServer.instrument/1` around code that sends messages
      through `VirtualTimeGenServer.call/3` or `VirtualTimeGenServer.cast/2`.

  Callbacks run **inside the observed process**, so keeping state is the
  observer's own business: one observer keeps counters in the process
  dictionary, another forwards events to a collector process, a third does
  nothing. The library never inspects that state; it only hands it back from
  `VirtualTimeGenServer.snapshot/1` if the observer produced it.

  An observer that raises raises in the process running it, like any other code
  running there. The library does not swallow the error.

  ## Example

      defmodule MessageCounter do
        @behaviour VirtualTimeGenServer.Instrumentation

        @impl true
        def on_receive({_kind, _message}, _meta) do
          Process.put(:received, Process.get(:received, 0) + 1)
          :ok
        end

        @impl true
        def on_send({_kind, _message}, _meta) do
          Process.put(:sent, Process.get(:sent, 0) + 1)
          :ok
        end

        @impl true
        def snapshot(_context) do
          %{sent: Process.get(:sent, 0), received: Process.get(:received, 0)}
        end
      end

      {:ok, clock} = VirtualClock.start_link()

      {:ok, server} =
        VirtualTimeGenServer.start_link(MyServer, :ok,
          virtual_clock: clock,
          instrumentation: MessageCounter
        )

      {:ok, %{received: 1}} = VirtualTimeGenServer.snapshot(server)
  """

  @typedoc """
  A message the observed process handled or sent: the kind of OTP callback
  (`:call`, `:cast` or `:info`) and the payload.
  """
  @type event :: {kind :: :call | :cast | :info, payload :: term()}

  @typedoc """
  Where the callback is running and what the observer was installed with.

  `:context` is the map the installer passed next to the module; `:module` is
  the observed server's own module; `:server` or `:sender` is the process the
  callback runs in.
  """
  @type meta :: %{
          required(:context) => map,
          optional(:module) => module,
          optional(:server) => pid,
          optional(:sender) => pid
        }

  @typedoc """
  What `start_link/3`'s `:instrumentation` option and `instrument/1` accept:
  a module, or a module with the context its callbacks receive.
  """
  @type t :: nil | module | {module, map}

  @doc """
  Called in the observed server process for every message it receives, before
  the server's own callback runs.

  The event carries the message the server is about to handle — not the
  library's transport for it. A message the clock delivered at a scheduled
  virtual time arrives as the message itself.
  """
  @callback on_receive(event, meta) :: :ok

  @doc """
  Called in the sending process for every message it sends through
  `VirtualTimeGenServer.call/3` or `VirtualTimeGenServer.cast/2`.

  The library's own queries (`VirtualTimeGenServer.snapshot/1`) are not
  reported: an observer sees the traffic of the observed code only.
  """
  @callback on_send(event, meta) :: :ok

  @doc """
  Called in the observed server process when someone asks
  `VirtualTimeGenServer.snapshot/1` what this observer collected.

  The returned term is the observer's business; the library hands it back
  unchanged.
  """
  @callback snapshot(context :: map) :: term

  @doc """
  Normalizes an instrumentation spec to `nil` or `{module, context}`.

  Used by the library to accept both the bare-module and the module-with-context
  form.
  """
  @spec normalize(t) :: nil | {module, map}
  def normalize(nil), do: nil
  def normalize(module) when is_atom(module), do: {module, %{}}
  def normalize({module, context}) when is_atom(module) and is_map(context), do: {module, context}
end
