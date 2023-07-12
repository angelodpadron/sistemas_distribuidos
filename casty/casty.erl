-module(casty).

-export([single_mode/0, dist_mode/0, dummy/0, just_proxy/0, just_client/2]).

single_mode() ->
    io:format("casty: starting in single mode~n", []),
    % Cast = {cast, "localhost", 4000, "/stream"},
    Cast = {cast, "str45.streamakaci.com", 8014, "/"},
    Port = 8081,
    Proxy = spawn(fun() -> proxy:init(Cast) end),
    spawn(fun() -> client:init(Proxy, Port) end).

dist_mode() ->
    io:format("casty: starting in dist mode~n", []),
    Cast = {cast, "str45.streamakaci.com", 8014, "/"},
    Proxy = spawn(fun() -> proxy:init(Cast) end),
    Dist = spawn(fun() -> dist:init(Proxy) end),
    spawn(fun() -> client:init(Dist, 8080) end),
    spawn(fun() -> client:init(Dist, 8081) end),
    spawn(fun() -> client:init(Dist, 8082) end).

dummy() ->
    io:format("casty: starting in dummy mode~n", []),
    Cast = {cast, "str45.streamakaci.com", 8014, "/"},
    Proxy = spawn(fun() -> proxy:init(Cast) end),
    Dist = spawn(fun() -> dist:init(Proxy) end),
    lists:foreach(fun(_) -> spawn(fun() -> dummy:init(Dist) end) end, lists:seq(1, 50)).

just_proxy() ->
    io:format("casty: starting in just proxy mode~n", []),
    Cast = {cast, "str45.streamakaci.com", 8014, "/"},
    Proxy = spawn(fun() -> proxy:init(Cast) end),
    global:register_name(proxy, Proxy).

just_client(Proxy, Port) ->
    io:format("casty: starting in just client mode~n", []),
    spawn(fun() -> client:init(Proxy, Port) end),
    global:register_name(client, self()).
