-module(worker).
-export([start/5, stop/1, peers/2]).

start(Name, Logger, Seed, Sleep, Jitter) ->
  spawn_link(fun() -> init(Name, Logger, Seed, Sleep, Jitter) end).

stop(Worker) ->
  Worker ! stop.

init(Name, Log, Seed, Sleep, Jitter) ->
  random:seed(Seed, Seed, Seed),
  receive
    {peers, Peers} ->
      loop(Name, Log, Peers, Sleep, Jitter, time:zero());
    stop ->
      ok
  end.

peers(Wrk, Peers) ->
  Wrk ! {peers, Peers}.

loop(Name, Log, Peers, Sleep, Jitter, Time) ->
  Wait = random:uniform(Sleep),
  receive
    {msg, MsgTime, Msg} -> 
      NewTime = time:inc(sarasa, time:merge(Time, MsgTime)),
      Log ! {log, Name, NewTime, {received, Msg}},
      loop(Name, Log, Peers, Sleep, Jitter, NewTime);
    stop ->
      ok;
    Error ->
      Log ! {log, Name, time, {error, Error}}
  after Wait -> 
      Selected = select(Peers),
      NewtTime = time:inc(sarasa, Time),
      Message = {hello, random:uniform(100)},
      Selected ! {msg, NewtTime, Message},
      jitter(Jitter),
      Log ! {log, Name, NewtTime, {sending, Message}},
      loop(Name, Log, Peers, Sleep, Jitter, NewtTime)
  end.

select(Peers) ->
  lists:nth(random:uniform(length(Peers)), Peers).

jitter(0) ->
  ok;
jitter(Jitter) ->
  timer:sleep(random:uniform(Jitter)).