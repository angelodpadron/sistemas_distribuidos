% ICY encoding and decoding

-module(icy).

-export([send_request/3, send_reply/2, send_data/2, request/1, reply/1]).

send_request(Host, Feed, Sender) ->
    Request =
        "GET "
        ++ Feed
        ++ " HTTP/1.0\r\n"
        ++ "Host: "
        ++ Host
        ++ "\r\n"
        ++ "User-Agent: Ecast\r\n"
        ++ "Icy-MetaData: 1\r\n"
        ++ "\r\n",
    Sender(list_to_binary(Request)).

send_reply(Header, Sender) ->
    Status = "ICY 200 OK\r\n",
    Reply = Status ++ header_to_list(Header),
    Sender(list_to_binary(Reply)).

header_to_list([]) ->
    "\r\n";
header_to_list([{Name, Arg} | Rest]) ->
    atom_to_list(Name) ++ ": " ++ Arg ++ "\r\n" ++ header_to_list(Rest).

send_data({Audio, Meta}, Sender) ->
    send_audio(Audio, Sender),
    send_meta(Meta, Sender).

send_audio([], _) ->
    ok;
send_audio([Chunk | Rest], Sender) ->
    Sender(Chunk),
    send_audio(Rest, Sender).

send_meta(Meta, Sender) ->
    {K, Padded} = padding(Meta),
    Sender(<<K/integer, Padded/binary>>).

padding(Meta) ->
    N = length(Meta),
    K = (N + 15) div 16,
    Padding = (16 - (N rem 16)) * 8,
    Binary = list_to_binary(Meta),
    Padded = <<Binary/binary, 0:(Padding)>>,
    {K, Padded}.

request(Binary) ->
    parser:request(Binary).

reply(Binary) ->
    parser:reply(Binary).