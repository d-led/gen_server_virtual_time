defmodule GenServerVirtualTimeTest do
  use ExUnit.Case
  doctest GenServerVirtualTime

  test "returns version" do
    assert is_binary(GenServerVirtualTime.version())
    assert GenServerVirtualTime.version() == "0.1.0"
  end
end
