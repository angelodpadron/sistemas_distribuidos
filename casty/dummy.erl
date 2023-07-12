-module(dummy).

-export([init/1]).

-define(TimeOut, 10000).

init(Proxy) ->
    Proxy ! {request, self()},
    receive
        {reply, N, _Context} ->
            io:format("dummy: connected~n", []),
            {ok, Msg} = loop(N),
            io:format("dummy: ~s~n", [Msg])
    after 5000 ->
        io:format("dummy: time-out~n", [])
    end.

loop(N) ->
    receive
        {data, N, _} ->
            loop(N + 1);
        {data, E, _} ->
            io:format("dummy: received ~w, expected ~w~n", [E, N]),
            loop(E + 1);
        stop ->
            {ok, "stoped"}
    after ?TimeOut ->
        {ok, "time out"}
    end.
