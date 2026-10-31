#!/usr/bin/env bash
# Gleam can only depend on Gleam packages, so the Elixir library is fetched and
# compiled by the rebar3 example next door, then handed to this project's code
# path through ERL_LIBS.
set -euo pipefail
cd "$(dirname "$0")"

(cd ../ticker_erlang && rebar3 compile > /dev/null)

elixir_libs=$(elixir -e 'IO.puts(:code.lib_dir(:elixir) |> Path.expand() |> Path.dirname())')

ERL_LIBS="$elixir_libs:$PWD/../ticker_erlang/_build/default/lib" gleam test "$@"
