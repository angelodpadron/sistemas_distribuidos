-module(worker).
-export([start/5, start/6]).

% LEADER
start(Id, Gsm, Sleep, Jitter, Pos) ->
  io:format("starting worker.leader [~s] ~n", [Id]),
  spawn(fun() -> init(Id, Gsm, Sleep, Jitter, Pos) end).

init(Id, Gsm, Sleep, Jitter, Pos) ->
  {ok, Multicast} = apply(Gsm, start, [Id, Jitter]),
  Gui = gui:start(Id, Pos),
  loop(Multicast, Gui, Sleep).

% SLAVE
start(Id, Gsm, Peer, Sleep, Jitter, Pos) ->
  io:format("starting worker.slave [~s] ~n", [Id]),
  spawn(fun() -> init(Id, Gsm, Peer, Sleep, Jitter, Pos) end).

init(Id, Gsm, Peer, Sleep, Jitter, Pos) ->
  {ok, Multicast} = apply(Gsm, start, [Id, Peer, Jitter]),
  Gui = gui:start(Id, Pos),
  loop(Multicast, Gui, Sleep).


loop(Multicast, Gui, Sleep) ->
  receive
    {deliver, Value} ->
      Gui ! {set, Value},
      loop(Multicast, Gui, Sleep);
    {join, Wrk, Slave} ->
      io:format("worker.join ~n"),
      Multicast ! {join, Wrk, Slave},
      loop(Multicast, Gui, Sleep);
    stop ->
      Multicast ! stop,
      Gui ! stop,
      ok
  after Sleep ->
      Value = rand:uniform(255),
      Multicast ! {mcast, Value},
      loop(Multicast, Gui, Sleep)
  end.