-module(rudy).
-export([init/1, handler/1, request/1]).

init(Port) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    case gen_tcp:listen(Port, Opt) of
        {ok, ListenSocket} ->
            handler(ListenSocket),
            ok;
        {error, Error} ->
            error
    end.

handler(ListenSocket) ->
    case gen_tcp:accept(ListenSocket) of
        {ok, Client} ->
            spawn(rudy, request, [Client]),
            handler(ListenSocket);
        {error, Error} ->
            io:format("rudy: error: ~w~n", [Error])
    end.
    % gen_tcp:close(ListenSocket).

request(Client) ->
    Recv = gen_tcp:recv(Client, 0),
    case Recv of
        {ok, Str} ->
            Request = http:parse_request(Str),
            Response = reply(Request),
            gen_tcp:send(Client, Response);
        {error, Error} ->
            io:format("rudy: error: ~w~n", [Error])
    end,
    gen_tcp:close(Client).

reply({{get, URI, _}, _, _}) ->
    http:ok(URI).
