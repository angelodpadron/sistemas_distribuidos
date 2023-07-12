-module(client).

-export([init/2]).

-define(Opt, [binary, {packet, 0}, {reuseaddr, true}, {active, true}, {nodelay, true}]).
-define(Timeout, 10000).

init(Proxy, Port) ->
    io:format("client: started~n"),
    case gen_tcp:listen(Port, ?Opt) of
        {ok, Listen} ->
            io:format("client: listening on port ~p~n", [Port]),
            case gen_tcp:accept(Listen) of
                {ok, Socket} ->
                    io:format("client: accepted connection~n"),
                    case read_request(Socket) of
                        {ok, _, _} ->
                            io:format("client: received request~n"),
                            case connect(Proxy) of
                                {ok, N, Context} ->
                                    send_reply(Context, Socket),
                                    {ok, Msg} = loop(N, Socket),
                                    io:format("client: terminating: ~s~n", [Msg]);
                                {error, Reason} ->
                                    io:format("client: error:  ~s~n", [Reason])
                            end;
                        {error, Reason} ->
                            io:format("client: error: ~s~n", [Reason])
                    end;
                {error, Reason} ->
                    io:format("client: socket error: ~s~n", [Reason]);
                Other ->
                    io:format("client: unexpected: ~p~n", [Other])
            end;
        {error, Reason} ->
            io:format("client: error: ~s~n", [Reason])
    end.

read_request(Socket) ->
    % reader(fun() -> parser:request(<<>>) end,
    %        Socket).
    reader(fun() -> icy:request(<<>>) end, Socket).

loop(_, Socket) ->
    receive
        {data, N, Data} ->
            io:format("client: packet ~p~n", [N]),
            send_data(Data, Socket),
            loop(N + 1, Socket);
        {tcp_closed, Socket} ->
            {ok, "player closed connection"}
    after ?Timeout ->
        {ok, "timeout"}
    end.

connect(Proxy) ->
    Proxy ! {request, self()},
    receive
        {reply, N, Context} ->
            {ok, N, Context}
    after ?Timeout ->
        {error, "connect: timeout"}
    end.

reader(Cont, Socket) ->
    io:format("client: reading request~n"),
    case Cont() of
        {ok, Parsed, Rest} ->
            {ok, Parsed, Rest};
        {more, Fun} ->
            receive
                {tcp, Socket, More} ->
                    reader(fun() -> Fun(More) end, Socket);
                {tcp_closed, Socket} ->
                    {error, "server closed connection"}
            after ?Timeout ->
                {error, "timeout"}
            end;
        {error, Reason} ->
            {error, Reason}
    end.

send_reply(Context, Socket) ->
    icy:send_reply(Context, fun(Bin) -> gen_tcp:send(Socket, Bin) end).

send_data(Data, Socket) ->
    icy:send_data(Data, fun(Bin) -> gen_tcp:send(Socket, Bin) end).
