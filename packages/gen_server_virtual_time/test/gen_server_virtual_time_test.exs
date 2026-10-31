defmodule GenServerVirtualTimeTest do
  use ExUnit.Case
  doctest GenServerVirtualTime

  test "returns version" do
    assert is_binary(GenServerVirtualTime.version())
    # Version should match mix.exs
    assert GenServerVirtualTime.version() == Mix.Project.config()[:version]
  end
end
