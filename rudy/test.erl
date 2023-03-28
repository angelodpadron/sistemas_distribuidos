-module(test).
-export([bench/2]).

bench(Host, Port) ->
    Start = erlang:system_time(micro_seconds),
    run(100, Host, Port),
    Finish = erlang:system_time(micro_seconds),
    io:format("Bench results: ~w ms. ~n", [(Finish - Start) / 1000]).

run(N, Host, Port) ->
    if
        N == 0 ->
            ok;
        true ->
            request(Host, Port),
            run(N-1, Host, Port)
    end.

request(Host, Port) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    io:format("Sending request to ~w:~B...~n", [Host, Port]),
    {ok, Server} = gen_tcp:connect(Host, Port, Opt),
    io:format("OK~n"),
    gen_tcp:send(Server, http:get("foo")),
    Recv = gen_tcp:recv(Server, 0),
    case Recv of
        {ok, _} ->
            ok;
        {error, Error} ->
            io:format("test: error: ~w~n", [Error])
    end,
    gen_tcp:close(Server).
