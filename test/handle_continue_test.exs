defmodule HandleContinueTest do
  use ExUnit.Case, async: false

  defmodule ContinueServer do
    use VirtualTimeGenServer

    def start_link(opts) do
      VirtualTimeGenServer.start_link(__MODULE__, opts, [])
    end

    def init(mode) do
      case mode do
        :use_continue ->
          # OTP 21+ pattern - continue after init
          {:ok, %{step: :init}, {:continue, :setup}}

        :normal ->
          {:ok, %{step: :init}}
      end
    end

    def handle_continue(:setup, state) do
      # Perform additional setup
      {:noreply, %{state | step: :setup_complete}}
    end

    def handle_continue(:next_step, state) do
      {:noreply, %{state | step: :next_complete}, {:continue, :final_step}}
    end

    def handle_continue(:final_step, state) do
      {:noreply, %{state | step: :all_done}}
    end

    def handle_call(:get_step, _from, state) do
      {:reply, state.step, state}
    end

    def handle_call(:trigger_continue, _from, state) do
      {:reply, :ok, state, {:continue, :next_step}}
    end
  end

  describe "handle_continue/2 support" do
    test "init can return {:continue, arg}" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = ContinueServer.start_link(:use_continue)

      # Give time for continue to execute
      Process.sleep(10)

      step = GenServer.call(server, :get_step)
      assert step == :setup_complete

      GenServer.stop(clock)
    end

    test "handle_call can return {:continue, arg}" do
      {:ok, clock} = VirtualClock.start_link()
      VirtualTimeGenServer.set_virtual_clock(clock)

      {:ok, server} = ContinueServer.start_link(:normal)

      # Trigger continue chain
      GenServer.call(server, :trigger_continue)
      Process.sleep(20)

      step = GenServer.call(server, :get_step)
      assert step == :all_done

      GenServer.stop(clock)
    end

    test "works without virtual time too" do
      {:ok, server} = ContinueServer.start_link(:use_continue)

      Process.sleep(10)

      step = GenServer.call(server, :get_step)
      assert step == :setup_complete

      GenServer.stop(server)
    end
  end
end
