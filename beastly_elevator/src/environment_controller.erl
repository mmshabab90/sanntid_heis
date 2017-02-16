-module(environment_controller).

-behaviour (gen_statem).
-define (NAME, environment_controller).

-export([start_link/1]).
-export([button_pressed/1,reached_new_floor/1]).
-export([init/1,callback_mode/0,terminate/3,code_change/4]).
-export([handle_event/4]).

start_link(Code) ->
    gen_statem:start_link({local,?NAME}, ?MODULE, Code, []).

button_pressed(Button) ->
    gen_statem:cast(?NAME, {button_pressed,Button}).
reached_new_floor(Floor) ->
    gen_statem:cast(?NAME, {reached_new_floor,Floor}).

init(Code) ->
    do_lock(),
    Data = #{code => Code, remaining => Code},
    {ok, locked, Data}.

callback_mode() ->
    handle_event_function.

handle_event(cast, {button,Digit}, State, #{code := Code} = Data) ->
    case State of
	locked ->
	    case maps:get(remaining, Data) of
		[Digit] -> % Complete
		    do_unlock(),
		    {next_state, open, Data#{remaining := Code},
                     {state_timeout,10000,lock}};
		[Digit|Rest] -> % Incomplete
		    {keep_state, Data#{remaining := Rest}};
		[_|_] -> % Wrong
            io:format("Wrong!~n"),
		    {keep_state, Data#{remaining := Code}}
	    end;
	open ->
            keep_state_and_data
    end;
handle_event(state_timeout, lock, open, Data) ->
    do_lock(),
    {next_state, locked, Data}.

do_lock() ->
    io:format("Lock~n", []).
do_unlock() ->
    io:format("Unlock~n", []).

terminate(_Reason, State, _Data) ->
    State =/= locked andalso do_lock(),
    ok.
code_change(_Vsn, State, Data, _Extra) ->
    {ok, State, Data}.