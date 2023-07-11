-module(casty).

-export([test/0]).

test() ->
    % Socket = 8000,
    % Sender = fun(Bin) -> io:format("Request:~n~s~n", [Bin]) end,
    % icy:send_request("http://www.bassdrive.com", "/", Sender).
    % Headers =
    %     [{'icy-notice', "This stream requires Winamp .."},
    %      {'icy-name', "Virgin Radio ..."},
    %      {'icy-genre', "Adult Pop Rock"},
    %      {'icy-url', "http://www.virginradio.co.uk/"},
    %      {'content-type', "audio/mpeg"},
    %      {'icy-pub', "1"},
    %      {'icy-metaint', "8192"},
    %      {'icy-br', "128"}],
    % Sender = fun(Bin) -> io:format("Reply:~n~s~n", [Bin]) end,
    % icy:send_reply(Headers, Sender).
    % AudioAndMeta = {[], "hello"},
    % Sender = fun(Bin) -> io:format("Data:~n~s~n", [Bin]) end,
    % icy:send_data(AudioAndMeta, Sender).
    % {K, Padded} = icy:padding("hello"),
    % io:format("~p~n", [<<K/integer, Padded/binary>>]).
    % RequestString = "GET / HTTP/1.0\r\nHost: mp3-vr-128.smgradio.com\r\nUser-Agent: Casty\r\nIcy-MetaData: 1\r\n\r\n",
    % parser:request(list_to_binary(RequestString)).
    
    Port = 8080,
    Cast = {cast, "str45.streamakaci.com", 8014, "/"},
    Proxy = spawn(fun() -> proxy:init(Cast) end),
    spawn(fun() -> client:init(Proxy, Port) end).
