{:ok, clock} = VirtualClock.start_link()
{:ok, server} = VirtualTimeGenServer.start_link(
  fn() ->
    use VirtualTimeGenServer
    
    def init(_) do
      VirtualTimeGenServer.send_after(self(), :tick, 100)
      {:ok, %{count: 0}}
    end
    
    def handle_info(:tick, state) do
      IO.puts "TICK fired! count=#{state.count}"
      VirtualTimeGenServer.send_after(self(), :tick, 100)
      {:noreply, %{state | count: state.count + 1}}
    end
    
    def handle_call(:get_count, _from, state) do
      {:reply, state.count, state}
    end
  end,
  :ok,
  virtual_clock: clock
)

IO.puts "Starting advance..."
VirtualClock.advance(clock, 500)
IO.puts "Advance complete"
count = VirtualTimeGenServer.call(server, :get_count)
IO.puts "Final count: #{count}"
