-module(toty).

% - export([start/3, testMethods/0]).
-export([start/3]).

start(MulticastModule, Sleep, Jitter) ->
  case MulticastModule of
    multicast_b ->
      io:format("Toty will run with basic multicast.~n", []);
    multicast_to ->
      io:format("Toty will run with total ordering multicast.~n", [])
  end,

  Pid = spawn(fun() -> init(MulticastModule, Sleep, Jitter) end),
  register(toty, Pid).

init(MulticastModule, Sleep, Jitter) ->
  Manager = manager:start(MulticastModule),

  Client1 = worker:start("John", Manager, Sleep, Jitter),
  Client2 = worker:start("Joe", Manager, Sleep, Jitter),
  Client3 = worker:start("Michael", Manager, Sleep, Jitter),
  Client4 = worker:start("Dani", Manager, Sleep, Jitter),
  Client5 = worker:start("Zoe", Manager, Sleep, Jitter),

  receive
    stop ->
      io:format("Stopping clients"),
      Client1 ! stop,
      Client2 ! stop,
      Client3 ! stop,
      Client4 ! stop,
      Client5 ! stop,
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
