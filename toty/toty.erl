-module(toty).

% - export([start/3, testMethods/0]).
-export([start/4]).

start(MulticastModule, Sleep, Jitter, ClientCount) ->
  case MulticastModule of
    multicast_b ->
      io:format("Toty will run with basic multicast.~n", []);
    multicast_to ->
      io:format("Toty will run with total ordering multicast.~n", [])
  end,

  Pid = spawn(fun() -> init(MulticastModule, Sleep, Jitter, ClientCount) end),
  register(toty, Pid).

init(MulticastModule, Sleep, Jitter, ClientCount) ->
  Manager = manager:start(MulticastModule),

  Clients =
    lists:map(fun(Id) ->
                 worker:start("Client" ++ io_lib:format("~B", [Id]), Manager, Sleep, Jitter)
              end,
              lists:seq(1, ClientCount)),
  receive
    stop ->
      lists:foreach(fun(Client) -> Client ! stop end, Clients),
      ok
  end.

% testMethods() ->
%   case multicast:cast([], 456, 5) of
%     [{456, 5, 0}] -> io:format("multicast:cast/3 -> OK ~n");
%     true -> io:format("multicast:cast/3 -> ERROR ~n")
%   end,
%   case multicast:insert([], {1, "asd"}, 456, 15) of
%     [{{proposed, 1}, 456, 15}] -> io:format("multicast:insert/2 -> OK ~n");
%     true -> io:format("multicast:insert/2 -> ERROR ~n")
%   end,
%   case multicast:increment({1, "asd"}) of
%     {2, "asd"} -> io:format("multicast:increment/1 -> OK ~n");
%     true -> io:format("multicast:increment/1 -> ERROR ~n")
%   end,
%   case multicast:increment({1, "asd"}, 3) of
%     {4, "asd"} -> io:format("multicast:increment/2 -> OK ~n");
%     true -> io:format("multicast:increment/2 -> ERROR ~n")
%   end.
