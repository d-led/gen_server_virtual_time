defmodule Mix.Tasks.Templates.Upgrade.HttpTest do
  @moduledoc """
  The task's HTTP client is the only part of the upgrade tooling that needs the
  network, so it is the part worth checking: that requests identify the tool,
  that a token is used when one is available, that the peer's certificate is
  verified rather than trusted, and that a real server's answers — and refusals —
  come back as data instead of exceptions.

  The server these tests talk to is a local one serving a temporary directory, so
  nothing here depends on the internet.
  """

  use ExUnit.Case, async: false

  alias Mix.Tasks.Templates.Upgrade.Http

  setup do
    %{url: serve(%{"versions.json" => ~s({"version":"1.2.3"})})}
  end

  describe "get" do
    test "returns the body of a successful response", %{url: url} do
      assert Http.get("#{url}/versions.json") == {:ok, ~s({"version":"1.2.3"})}
    end

    test "reports a status other than ok instead of returning whatever came with it", %{url: url} do
      assert {:error, {404, _reason}} = Http.get("#{url}/missing.json")
    end

    test "reports a connection that cannot be made" do
      assert {:error, {:failed_connect, _reason}} = Http.get("http://127.0.0.1:1/")
    end
  end

  describe "headers" do
    test "identify the tool and ask for JSON" do
      headers = Http.headers() |> Map.new(fn {name, value} -> {name, to_string(value)} end)

      assert headers[~c"user-agent"] =~ "gen_server_virtual_time"
      assert headers[~c"accept"] =~ "json"
    end

    test "carry a bearer token when one is in the environment" do
      with_env("GH_TOKEN", "secret-token", fn ->
        headers = Http.headers() |> Map.new(fn {name, value} -> {name, to_string(value)} end)

        assert headers[~c"authorization"] == "Bearer secret-token"
      end)
    end

    test "stay anonymous when no token is available" do
      with_env("GH_TOKEN", nil, fn ->
        refute Enum.any?(Http.headers(), fn {name, _value} -> name == ~c"authorization" end)
      end)
    end
  end

  describe "options" do
    test "verify the peer's certificate instead of trusting the connection" do
      ssl = Http.options()[:ssl]

      assert ssl[:verify] == :verify_peer
      assert ssl[:cacerts] != nil
      assert ssl[:customize_hostname_check][:match_fun]
    end

    test "give up rather than hang when an upstream does not answer" do
      options = Http.options()

      assert options[:timeout] > 0
      assert options[:connect_timeout] > 0
    end
  end

  # Serves `files` (name -> content) over HTTP on an ephemeral port and returns
  # the base URL, stopping the server when the test ends.
  defp serve(files) do
    {:ok, _} = Application.ensure_all_started(:inets)

    root = Path.join(System.tmp_dir!(), "http_client_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    Enum.each(files, fn {name, content} -> File.write!(Path.join(root, name), content) end)

    {:ok, httpd} =
      :inets.start(:httpd,
        port: 0,
        bind_address: {127, 0, 0, 1},
        server_root: String.to_charlist(root),
        document_root: String.to_charlist(root),
        modules: [:mod_get]
      )

    on_exit(fn ->
      :inets.stop(:httpd, httpd)
      File.rm_rf(root)
    end)

    "http://127.0.0.1:#{:httpd.info(httpd) |> Keyword.fetch!(:port)}"
  end

  defp with_env(name, value, fun) do
    previous = System.get_env(name)
    if value, do: System.put_env(name, value), else: System.delete_env(name)

    try do
      fun.()
    after
      if previous, do: System.put_env(name, previous), else: System.delete_env(name)
    end
  end
end
