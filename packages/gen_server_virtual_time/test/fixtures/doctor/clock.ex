defmodule MyApp.Clock do
  def tick do
    {:ok, clock} = VirtualClock.start_link()
    VirtualClock.advance(clock, 1000)
  end
end
