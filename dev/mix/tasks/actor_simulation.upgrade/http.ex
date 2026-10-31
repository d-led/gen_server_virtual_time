defmodule Mix.Tasks.Templates.Upgrade.Http do
  @moduledoc """
  The one part of `mix templates.upgrade` that needs the network: an HTTP GET
  with certificate verification, plus a token when one is in the environment.

  It lives in its own module so the task around it stays testable: everything
  here is either a request (which cannot run in a test) or the request's
  configuration (which can, and which is worth pinning — asking for a package
  version over an unverified TLS connection is not something to leave to a
  default).

  Anonymous GitHub API requests are limited to 60 per hour and the task makes
  about a dozen, so `GH_TOKEN` or `GITHUB_TOKEN` is used when set.
  """

  # :httpc and :public_key come from :inets and :public_key, which the library
  # does not depend on: only maintainer environments declare them (see mix.exs).
  @compile {:no_warn_undefined, [:httpc, :public_key]}

  @user_agent ~c"gen_server_virtual_time templates.upgrade"
  @timeout 30_000
  @connect_timeout 15_000

  @doc """
  Fetches `url`, returning its body or an error.

  The body is returned as received; parsing is
  `ActorSimulation.TemplateVersions.Upgrade`'s job.
  """
  @spec get(String.t()) :: {:ok, binary()} | {:error, term()}
  def get(url) do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    case :httpc.request(:get, {String.to_charlist(url), headers()}, options(),
           body_format: :binary
         ) do
      {:ok, {{_version, 200, _reason}, _headers, body}} ->
        {:ok, body}

      {:ok, {{_version, status, reason}, _headers, _body}} ->
        {:error, {status, to_string(reason)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  The request headers, including an authorization header when `GH_TOKEN` or
  `GITHUB_TOKEN` is set.
  """
  @spec headers() :: [{charlist(), charlist()}]
  def headers do
    [{~c"user-agent", @user_agent}, {~c"accept", ~c"application/vnd.github+json"}] ++
      auth_header()
  end

  # TLS verification on purpose: a version read over an unverified connection is
  # a version someone else can choose.
  @doc """
  The request options: timeouts, and peer verification against the certificates
  OTP ships with.
  """
  @spec options() :: keyword()
  def options do
    [
      timeout: @timeout,
      connect_timeout: @connect_timeout,
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        depth: 4,
        customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]
      ]
    ]
  end

  defp auth_header do
    case System.get_env("GH_TOKEN") || System.get_env("GITHUB_TOKEN") do
      nil -> []
      token -> [{~c"authorization", String.to_charlist("Bearer #{token}")}]
    end
  end
end
