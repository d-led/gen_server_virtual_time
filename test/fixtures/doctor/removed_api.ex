defmodule MyApp.Stats do
  def enable do
    VirtualTimeGenServer.enable_stats_tracking()
  end
end
