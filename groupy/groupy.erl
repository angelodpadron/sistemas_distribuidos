-module(groupy).

- export([start/2]).

start(Sleep, Jitter) ->
  W1 = worker:start("W1", gsm3, Sleep, Jitter, 0),
  W2 = worker:start("W2", gsm3, W1, Sleep, Jitter, 1),
  W3 = worker:start("W3", gsm3, W2, Sleep, Jitter, 2),
  W4 = worker:start("W4", gsm3, W2, Sleep, Jitter, 3),
  W5 = worker:start("W5", gsm3, W4, Sleep, Jitter, 4),

  receive
    stop ->
      W1 ! stop,
      W2 ! stop,
      W3 ! stop,
      W4 ! stop,
      W5 ! stop,
      ok
  end.