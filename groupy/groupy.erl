-module(groupy).

-export([start/3]).

start(Sleep, Jitter, Module) ->
  Pid = spawn(fun() -> init(Sleep, Jitter, Module) end),
  register(groupy, Pid).

init(Sleep, Jitter, Module) ->
  W1 = worker:start("W1", Module, Sleep, Jitter, 0),
  W2 = worker:start("W2", Module, W1, Sleep, Jitter, 1),
  W3 = worker:start("W3", Module, W2, Sleep, Jitter, 2),
  W4 = worker:start("W4", Module, W2, Sleep, Jitter, 3),
  W5 = worker:start("W5", Module, W4, Sleep, Jitter, 4),

  receive
    stop ->
      W1 ! stop,
      W2 ! stop,
      W3 ! stop,
      W4 ! stop,
      W5 ! stop,
      ok
  end.
