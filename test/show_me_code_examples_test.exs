defmodule ShowMeCodeExamplesTest do
  use ExUnit.Case, async: false

  describe "Show Me The Code examples" do
    test "GenServerVirtualTime example works" do
      defmodule MyServer do
        use VirtualTimeGenServer

        def start_link(state) do
          VirtualTimeGenServer.start_link(__MODULE__, state, [])
        end

        def init(state) do
          VirtualTimeGenServer.send_after(self(), :work, 1000)
          {:ok, state}
        end

        def handle_call(:get_count, _from, state) do
          {:reply, state.count, state}
        end

        def handle_info(:work, state) do
          VirtualTimeGenServer.send_after(self(), :work, 1000)
          {:noreply, %{state | count: state.count + 1}}
        end
      end

      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = MyServer.start_link(%{count: 0})
      VirtualClock.advance(clock, 10_000)  # 10s virtual, fast real

      Process.sleep(20)  # Let messages process

      count = GenServer.call(server, :get_count)
      assert count >= 9  # Should have ~10 work items

      GenServer.stop(clock)
    end

    test "Actor DSL with aliases works" do
      alias ActorSimulation, as: Sim

      simulation = Sim.new()
      |> Sim.add_actor(:producer,
          send_pattern: {:rate, 50, :data},  # 50/sec
          targets: [:consumer])
      |> Sim.add_actor(:consumer,
          on_receive: fn :data, s -> {:ok, %{s | count: s.count + 1}} end,
          initial_state: %{count: 0})
      |> Sim.run(duration: 5_000)  # 5 seconds

      stats = Sim.get_stats(simulation)

      # Should have sent ~250 messages (50/sec * 5sec)
      assert stats.actors[:producer].sent_count >= 200
      assert stats.actors[:consumer].received_count >= 200

      Sim.stop(simulation)
    end

    test "aliased actor DSL is more concise" do
      alias ActorSimulation, as: S

      # Ultra-concise pub-sub
      sim = S.new()
      |> S.add_actor(:pub, send_pattern: {:periodic, 100, :event}, targets: [:sub1, :sub2])
      |> S.add_actor(:sub1)
      |> S.add_actor(:sub2)
      |> S.run(duration: 500)

      stats = S.get_stats(sim)

      assert stats.actors[:pub].sent_count == 10  # 5 ticks * 2 targets
      assert stats.actors[:sub1].received_count == 5
      assert stats.actors[:sub2].received_count == 5

      S.stop(sim)
    end
  end
end
