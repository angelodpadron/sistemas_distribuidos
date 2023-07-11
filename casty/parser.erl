-module(parser).

-export([request/1, reply/1]).

request(Bin) ->
    case line(Bin) of
        {ok, "GET / HTTP/1.0", R1} ->
            io:format("GET / HTTP/1.0~n"),            
            case header(R1, []) of
                {ok, Header, R2} ->
                    io:format("Headers: ~p~n", [Header]),
                    {ok, Header, R2};
                more ->
                    io:format("Header: more~n"),
                    {more, fun(More) -> request(<<Bin/binary, More/binary>>) end}
            end;
        {ok, Req, _} ->
            {error, "invalid request: " ++ Req};
        more ->
            {more, fun(More) -> request(<<Bin/binary, More/binary>>) end}
    end.

reply(Bin) ->
    case line(Bin) of
        {ok, "ICY 200 OK", R1} ->
            case header(R1, []) of 
                {ok, Header, R2} ->
                    MetaInt = metaint(Header),
                    io:format("Detected metaint: ~p~n", [MetaInt]),
                    {ok, fun() -> data(R2, MetaInt) end, Header};
                more ->
                    {more, fun(More) -> reply(<<Bin/binary, More/binary>>) end}
            end;
        {ok, Resp, _} ->
            {error, "invalid reply:" ++ Resp};
        more ->
            {more, fun(More) -> reply(<<Bin/binary, More/binary>>) end}
    end.

line(Bin) ->
    line(Bin, []).
line(<<>>, _) ->
    more;
line(<<$\r, $\n, Rest/binary>>, Sofar) ->
    {ok, lists:reverse(Sofar), Rest};
line(<<C, Rest/binary>>, Sofar) ->
    line(Rest, [C | Sofar]).

header(Bin, Sofar) ->
    case line(Bin) of
        {ok, [], Rest} ->
            {ok, list_to_pairs(lists:reverse(Sofar)), Rest};
            % {ok, lists:reverse(Sofar), Rest};
        {ok, Line, Rest} ->
            header(Rest, [Line | Sofar]);
        more ->
            more
    end.

list_to_pairs(List) ->
    list_to_pairs(List, []).
list_to_pairs([], Acc) ->
    Acc;
list_to_pairs([H | T], Acc) ->
    case string:tokens(H, ":") of
        [Name | Arg] ->            
            list_to_pairs(T, [{list_to_atom(Name), string:strip(string:join(Arg, ":"), both, $ )} | Acc]);
        _ ->
            list_to_pairs(T, Acc)
    end.

metaint(Header) ->
    case proplists:get_value('icy-metaint', Header) of
        undefined ->
            0; % atado con alambre, pero se supone que el metaint siempre está incluido
        Value ->
            list_to_integer(Value)
    end.

data(Bin, M) ->
    audio(Bin, [], M, M).

audio(Bin, Sofar, N, M) ->
    Size = size(Bin),
    if
        Size >= N ->
            {Chunk, Rest} = split_binary(Bin, N),
            meta(Rest, lists:reverse([Chunk | Sofar]), M);
        true ->
            {more, fun(More) -> audio(More, [Bin | Sofar], N-Size, M) end}
    end.

meta(<<>>, Audio, M) ->
    {more, fun(More) -> meta(More, Audio, M) end};
meta(Bin, Audio, M) ->
    <<K/integer, R0/binary>> = Bin,
    Size = size(R0),
    H = K*16,
    if
        Size >= H ->
            {Padded, R2} = split_binary(R0, H),
            Meta = [C || C <- binary_to_list(Padded), C > 0],
            {ok, {Audio, Meta}, fun() -> data(R2, M) end};
        true ->
            {more, fun(More) -> meta(<<Bin/binary, More/binary>>, Audio, M) end}
    end.