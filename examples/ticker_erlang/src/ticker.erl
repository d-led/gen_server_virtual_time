%% A ticker on virtual time, written as a VirtualTimeGenServer.
%%
%% It ticks every IntervalMs of *virtual* time: a minute of ticking costs the
%% clock nothing, because nothing sleeps. Advancing the clock is what makes it
%% tick, and every tick is reported as `{tick, N}` to the caller of start_link/3.
-module(ticker).
-export([start_link/3]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-spec start_link(pid(), pos_integer(), non_neg_integer()) -> {ok, pid()}.
start_link(Clock, IntervalMs, Ticks) ->
    InitArg = {self(), IntervalMs, Ticks},
    'Elixir.VirtualTimeGenServer':start_link(?MODULE, InitArg, [{virtual_clock, Clock}]).

init({Report, IntervalMs, Ticks}) ->
    arm(IntervalMs),
    {ok, {Report, IntervalMs, Ticks, 1}}.

handle_info(tick, {Report, IntervalMs, Ticks, Tick}) when Tick >= Ticks ->
    Report ! {tick, Tick},
    {stop, normal, {Report, IntervalMs, Ticks, Tick}};
handle_info(tick, {Report, IntervalMs, Ticks, Tick}) ->
    Report ! {tick, Tick},
    arm(IntervalMs),
    {noreply, {Report, IntervalMs, Ticks, Tick + 1}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

%% Asking the backend to wake us is what puts this process on the clock: with
%% virtual time it schedules an event, with real time it schedules a timer.
arm(IntervalMs) ->
    'Elixir.VirtualTimeGenServer':send_after(self(), tick, IntervalMs).
