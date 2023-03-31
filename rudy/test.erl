-module(test).
-export([bench/2, request/3]).

bench(Host, Port) ->
    {ok, TotalTime} = run(100, Host, Port, 0),
    io:format("~nAverage requests completion time: ~w ms. ~n", [TotalTime / 1000 / 100]),
    io:format("Total requests completion time: ~w ms. ~n", [TotalTime / 1000]).

run(0, _, _, Acc) ->
    {ok, Acc};
run(N, Host, Port, Acc) ->
    spawn(test, request, [Host, Port, self()]),
    receive
        {time, Time} ->
            io:format("Request took ~w ms to complete.~n", [Time / 1000]),
            run(N - 1, Host, Port, Acc + Time)
    end.

request(Host, Port, PID) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    Start = erlang:system_time(micro_seconds),
    {ok, Server} = gen_tcp:connect(Host, Port, Opt),
    gen_tcp:send(Server, http:get("foo")),
    case gen_tcp:recv(Server, 0) of
        {ok, _} ->
            ok;
        {error, Error} ->
            io:format("test: error: ~w~n", [Error])
    end,
    gen_tcp:close(Server),
    Finish = erlang:system_time(micro_seconds),
    PID ! {time, Finish - Start}.
