-module(dist).
-export([init/1]).

-define(Timeout, 10000).

init(Proxy) ->
    Proxy ! {request, self()},
    receive
        {reply, N, Context} ->
            io:format("dist: started~n"),
            loop([], N, Context)          
    after ?Timeout ->
        ok
    end.

loop(Clients, N, Context) ->
    receive
        {data, N, Data} ->
            lists:foreach(fun({Pid, _}) -> Pid ! {data, N, Data} end, Clients),
            loop(Clients, N + 1, Context);
        {request, From} ->
            io:format("dist: client ~p connected (serving to ~p clients)~n", [From, length(Clients) + 1]),
            Ref = erlang:monitor(process, From),
            From ! {reply, N, Context},
            loop([{From, Ref} | Clients], N, Context);
        {'DOWN', Ref, process, Pid, _} ->
            Clients2 = lists:filter(fun({_, Ref2}) -> Ref2 /= Ref end, Clients),
            io:format("dist: client ~p terminated~n", [Pid]),
            loop(Clients2, N, Context);
        stop ->
            {ok, "dist: stoped"};
        stat ->
            io:format("dist: serving ~p clients~n", [length(Clients)]),
            loop(Clients, N, Context)
    end.