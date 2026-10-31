defmodule InstrumentationTest do
  use ExUnit.Case, async: true

  alias VirtualTimeGenServer.Instrumentation

  defmodule RecordingObserver do
    @behaviour VirtualTimeGenServer.Instrumentation

    @impl true
    def on_receive(event, %{context: %{collector: collector}}) do
      send(collector, {:received, event})
      :ok
    end

    @impl true
    def on_send(event, %{context: %{collector: collector}}) do
      send(collector, {:sent, event})
      :ok
    end

    @impl true
    def snapshot(_context), do: self()
  end

  defmodule CountingObserver do
    @behaviour VirtualTimeGenServer.Instrumentation

    @impl true
    def on_receive({_kind, _message}, _meta) do
      counters = Process.get(:counters, %{sent: 0, received: 0})
      Process.put(:counters, %{counters | received: counters.received + 1})
      :ok
    end

    @impl true
    def on_send({_kind, _message}, _meta) do
      counters = Process.get(:counters, %{sent: 0, received: 0})
      Process.put(:counters, %{counters | sent: counters.sent + 1})
      :ok
    end

    @impl true
    def snapshot(_context), do: Process.get(:counters, %{sent: 0, received: 0})
  end

  defmodule OpaqueObserver do
    @behaviour VirtualTimeGenServer.Instrumentation

    @impl true
    def on_receive(_event, _meta), do: :ok

    @impl true
    def on_send(_event, _meta), do: :ok

    @impl true
    def snapshot(_context), do: %{anything: :goes}
  end

  defmodule EchoServer do
    use VirtualTimeGenServer

    def start_link(opts), do: VirtualTimeGenServer.start_link(__MODULE__, :ok, opts)

    def init(:ok), do: {:ok, %{}}

    def handle_call(:ping, _from, state), do: {:reply, :pong, state}

    def handle_cast(:notify, state) do
      VirtualTimeGenServer.cast(self(), :notified)
      {:noreply, state}
    end

    def handle_cast(_message, state), do: {:noreply, state}

    def handle_info(_message, state), do: {:noreply, state}
  end

  defmodule TickServer do
    use VirtualTimeGenServer

    def start_link(opts), do: VirtualTimeGenServer.start_link(__MODULE__, :ok, opts)

    def init(:ok) do
      VirtualTimeGenServer.send_after(self(), :tick, 10)
      {:ok, %{}}
    end

    def handle_info(:tick, state), do: {:noreply, state}
  end

  describe "observing a server" do
    test "reports every message it handles, in the order it handled them" do
      server = start_recording_server()

      VirtualTimeGenServer.call(server, :ping)
      VirtualTimeGenServer.cast(server, :nudge)
      send(server, :chatter)

      assert received_events(3) == [{:call, :ping}, {:cast, :nudge}, {:info, :chatter}]
    end

    test "reports a scheduled message as the message the server handled" do
      {:ok, clock} = VirtualClock.start_link()

      {:ok, _server} =
        TickServer.start_link(
          virtual_clock: clock,
          instrumentation: {RecordingObserver, %{collector: self()}}
        )

      VirtualClock.advance(clock, 10)

      assert_receive {:received, {:info, :tick}}
      refute_receive {:received, {:info, {:__vtgs_delivered__, _token, :tick}}}
    end

    test "does not report the library's own query about the observer" do
      server = start_recording_server()
      VirtualTimeGenServer.call(server, :ping)

      VirtualTimeGenServer.snapshot(server)
      VirtualTimeGenServer.snapshot(server)

      assert received_events(1) == [{:call, :ping}]
    end

    test "asking for the snapshot does not change what the observer collected" do
      {:ok, server} = EchoServer.start_link(instrumentation: CountingObserver)
      VirtualTimeGenServer.call(server, :ping)

      assert VirtualTimeGenServer.snapshot(server) == {:ok, %{sent: 0, received: 1}}
      assert VirtualTimeGenServer.snapshot(server) == {:ok, %{sent: 0, received: 1}}
    end

    test "runs the observer in the observed server process" do
      server = start_recording_server()

      assert VirtualTimeGenServer.snapshot(server) == {:ok, server}
    end

    test "hands the observer's term back unchanged" do
      {:ok, server} = EchoServer.start_link(instrumentation: OpaqueObserver)

      assert VirtualTimeGenServer.snapshot(server) == {:ok, %{anything: :goes}}
    end

    test "a server without an observer is not instrumented" do
      {:ok, server} = EchoServer.start_link([])

      assert VirtualTimeGenServer.snapshot(server) == {:error, :not_instrumented}
    end
  end

  describe "observing a process that sends" do
    test "reports the messages it sends through the library" do
      server = start_recording_server()
      VirtualTimeGenServer.instrument({RecordingObserver, %{collector: self()}})

      VirtualTimeGenServer.call(server, :ping)
      VirtualTimeGenServer.cast(server, :nudge)

      assert sent_events(2) == [{:call, :ping}, {:cast, :nudge}]
    end

    test "a server reports what it sends itself" do
      server = start_recording_server()

      VirtualTimeGenServer.cast(server, :notify)

      assert_receive {:sent, {:cast, :notified}}
    end

    test "stops reporting once the process is no longer instrumented" do
      server = start_recording_server()
      VirtualTimeGenServer.instrument({RecordingObserver, %{collector: self()}})
      VirtualTimeGenServer.call(server, :ping)
      assert sent_events(1) == [{:call, :ping}]

      VirtualTimeGenServer.instrument(nil)
      VirtualTimeGenServer.call(server, :ping)

      refute_receive {:sent, {:call, :ping}}
    end
  end

  describe "the instrumentation spec" do
    test "a bare module means a module with no context" do
      assert Instrumentation.normalize(RecordingObserver) == {RecordingObserver, %{}}
    end

    test "a module with context keeps that context" do
      assert Instrumentation.normalize({OpaqueObserver, %{a: 1}}) == {OpaqueObserver, %{a: 1}}
    end

    test "nothing means no instrumentation" do
      assert Instrumentation.normalize(nil) == nil
    end
  end

  defp start_recording_server(opts \\ []) do
    {:ok, server} =
      EchoServer.start_link(
        Keyword.put(opts, :instrumentation, {RecordingObserver, %{collector: self()}})
      )

    server
  end

  # Messages are matched from the mailbox in arrival order, so comparing the
  # collected list asserts the order as well as the content.
  defp received_events(count), do: collect(:received, count)

  defp sent_events(count), do: collect(:sent, count)

  defp collect(tag, count) do
    for _ <- List.duplicate(:event, count) do
      receive do
        {^tag, event} -> event
      after
        500 -> flunk("expected #{count} #{tag} event(s)")
      end
    end
  end
end
