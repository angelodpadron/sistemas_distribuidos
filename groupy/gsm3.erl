- module(gsm3).

- export([start/2, start/3]).

-define(timeout, 1000).
-define(arghh, 500).

start(Id, Jitter) ->
  Self = self(),
  {ok, spawn_link(fun()-> init(Id, Self, Jitter) end)}.

init(Id, Master, Jitter) ->
  leader(Id, Master, 1, [], [Master], Jitter).


start(Id, Grp, Jitter) -> 
  Self = self(),
  {ok, spawn_link(fun() -> init(Id, Grp, Self, Jitter) end)}.

init(Id, Grp, Master, Jitter) ->
  Self = self(),
  Grp ! {join, Master, Self},
  receive
    {view, N, [Leader | Slaves], Group} ->
      Master ! {view, Group},
      erlang:monitor(process, Leader),
      slave(Id, Master, Leader, N+1, {view, N, [Leader | Slaves], Group}, Slaves, Group, Jitter)
    after ?timeout ->
      Master ! {error, "no reply from leader"}
  end.


leader(Id, Master, N, Slaves, Group, Jitter) ->
  receive
    {mcast, Msg} ->
      jitter(Jitter),
      bcast(Id, {msg, N, Msg}, Slaves),
      Master ! {deliver, Msg},
      leader(Id, Master, N+1, Slaves, Group, Jitter);
    {join, Wrk, Peer} ->
      jitter(Jitter),
      Slaves2 = lists:append(Slaves, [Peer]),
      Group2 = lists:append(Group, [Wrk]),
      bcast(Id, {view, N, [self()|Slaves2], Group2}, Slaves2),
      Master ! {view, Group2},
      leader(Id, Master, N+1, Slaves2, Group2, Jitter);
    stop -> ok
  end.

slave(Id, Master, Leader, N, Last, Slaves, Group, Jitter) ->
  receive
    {mcast, Msg} ->
      Leader ! {mcast, Msg},
      slave(Id, Master, Leader, N, Last, Slaves, Group, Jitter);
    {join, Wrk, Peer} ->
      Leader ! {join, Wrk, Peer},
      slave(Id, Master, Leader, N, Last, Slaves, Group, Jitter);
    {msg, I, _} when I < N ->
      slave(Id, Master, Leader, N, Last, Slaves, Group, Jitter);
    {msg, I, Msg} ->
      jitter(Jitter),
      Master ! {deliver, Msg},
      slave(Id, Master, Leader, I + 1, {msg, I, Msg}, Slaves, Group, Jitter);
    {view, N, [Leader|Slaves2], Group2} ->
      jitter(Jitter),
      Master ! {view, Group2},
      slave(Id, Master, Leader, N + 1, {view, N, [Leader|Slaves2], Group2}, Slaves2, Group2, Jitter);
    {'DOWN', _Ref, process, Leader, _Reason} ->
      election(Id, Master, N, Last, Slaves, Group, Jitter);
    stop ->
      ok
  end.


bcast(Id, Msg, Nodes) ->
  lists:foreach(fun(Node) -> Node ! Msg, crash(Id) end, Nodes).
crash(Id) ->
  case rand:uniform(?arghh) of
    ?arghh ->
      io:format("leader ~s: crash~n", [Id]),
      exit(no_luck);
    _ -> ok
  end.

election(Id, Master, N, Last, Slaves, Group, Jitter) ->
  Self = self(),
  case Slaves of
    [Self|Rest] ->
      bcast(Id, Last, Rest),
      bcast(Id, {view, N, Slaves, Group}, Rest),
      Master ! {view, Group},
      leader(Id, Master, N+1, Rest, Group, Jitter);
    [Leader|Rest] ->
      erlang:monitor(process, Leader),
      slave(Id, Master, Leader, N, Last, Rest, Group, Jitter)
  end.



jitter(0) ->
  ok;
jitter(Jitter) ->
  timer:sleep(rand:uniform(Jitter)).