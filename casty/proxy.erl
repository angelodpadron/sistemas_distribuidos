-module(proxy).

-export([init/1]).

-define(Timeout, 15000).

init(Cast) ->
    io:format("proxy: started~n"),
    receive
        {request, Client} ->
            io:format("proxy: received request: ~w~n", [Client]),
            Ref = erlang:monitor(process, Client),
            case attach(Cast, Ref) of
                {ok, Stream, Cont, Context} ->
                    Client ! {reply, 0, Context},
                    {ok, Msg} = loop(Cont, 0, Stream, Client, Ref),
                    io:format("proxy: terminating ~s~n", [Msg]);
                {error, Reason} ->
                    io:format("proxy: error ~s~n", [Reason])
            end
    end.

loop(Cont, N, Stream, Client, Ref) ->
    io:format("proxy: loop~n", []),
    case reader(Cont, Stream, Ref) of
        {ok, Data, Rest} ->
            Client ! {data, N, Data},
            loop(Rest, N + 1, Stream, Client, Ref);
        {error, Reason} ->
            io:format("proxy: error: ~s~n", [Reason]),
            {ok, Reason}
    end.

% {cast, "bassdrive.com", 8000, "/"}
attach({cast, Host, Port, Feed}, Ref) ->
    case gen_tcp:connect(Host, Port, [binary, {packet, 0}]) of
        {ok, Stream} ->
            io:format("proxy: stream: ~p~n", [Stream]),
            case send_request(Host, Feed, Stream) of
                ok ->
                    case reply(Stream, Ref) of
                        {ok, Cont, Context} ->
                            {ok, Stream, Cont, Context};
                        {error, Reason} ->
                            {error, Reason}
                    end;
                _ ->
                    {error, "unable to send request"}
            end;
        _ ->
            {error, "unable to connect to server"}
    end.

send_request(Host, Feed, Stream) ->
    icy:send_request(Host, Feed, fun(Bin) -> gen_tcp:send(Stream, Bin) end). % Stream no tiene ligadura aca, un error del pdf o lei mal?

reply(Stream, Ref) ->
    reader(fun() -> parser:reply(<<>>) end, Stream, Ref).
reader(Cont, Stream, Ref) ->
    case Cont() of
        {ok, Parsed, Rest} ->
            {ok, Parsed, Rest};
        {more, Fun} ->
            % io:format("proxy: awaiting data~n"),
            receive
                {tcp, Stream, More} ->
                    % io:format("proxy: received data~n"),
                    reader(fun() -> Fun(More) end, Stream, Ref);
                {tcp_closed, Stream} ->
                    {error, "icy server closed connection"};
                {'DOWN', Ref, process, _, _} ->
                    {error, "client died"}
            after ?Timeout ->
                {error, "timeout"}
            end;
        {error, Reason} ->
            {error, Reason}
    end.