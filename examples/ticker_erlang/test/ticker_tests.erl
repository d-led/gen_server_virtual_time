%% A minute of ticks, on a clock that is ours to advance.
-module(ticker_tests).
-include_lib("eunit/include/eunit.hrl").

a_virtual_minute_of_ticks_takes_no_real_time_test() ->
    {ok, Clock} = 'Elixir.VirtualClock':start_link(),

    {Microseconds, TicksSeen} =
        timer:tc(fun() ->
            {ok, _Ticker} = ticker:start_link(Clock, 1000, 60),
            'Elixir.VirtualClock':advance(Clock, 60000),
            count_ticks(0)
        end),

    ?assertEqual(60, TicksSeen),
    ?assertEqual(60000, 'Elixir.VirtualClock':now(Clock)),
    ?assert(Microseconds < 500000).

%% Every tick was delivered before advance/2 returned: it does not return until
%% the clock's events have been handled and acknowledged.
count_ticks(Seen) ->
    receive
        {tick, _N} -> count_ticks(Seen + 1)
    after 0 -> Seen
    end.
