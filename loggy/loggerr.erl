-module(loggerr).
-export([start/1, stop/1]).

start(Nodes) ->
  spawn_link(fun() -> init(Nodes) end).

stop(Logger) -> 
  Logger ! stop.

init(Nodes) ->
  loop([], time:clock(Nodes)).

loop(Log, Clock) ->
  receive
    {log, From, Time, Msg} ->
      NewClock = time:update(From, Time, Clock),
      NewLog = safeLog(concatMsg(Log, {From, Time, Msg}), NewClock),
      loop(NewLog, NewClock);
    stop ->
      lists:foreach(
        fun({From, Time, Msg}) -> 
          io:format("stop log: ~w ~w ~p~n", [Time, From, Msg]) 
        end, Log),
      ok
  end.

% Concatena el nuevo mensaje ordenado en el Log
concatMsg([], {NewFrom, NewTime, NewMsg}) -> [{NewFrom, NewTime, NewMsg}];
concatMsg([{From, Time, Msg} | Tail], {NewFrom, NewTime, NewMsg}) -> 
  if
    NewTime < Time ->
      [{NewFrom, NewTime, NewMsg} , {From, Time, Msg} | Tail];
    true ->
      [{From, Time, Msg} | concatMsg(Tail, {NewFrom, NewTime, NewMsg})]
  end.

% Imprime los mensajes seguros y retorna el resto del log
safeLog([], _) -> [];
safeLog([{From, Time, Msg} | Tail], Clock) -> 
  PuedeImprimir = time:safe(Time, Clock),
  if
    PuedeImprimir ->
      io:format("safe log: ~w ~w ~p~n", [Time, From, Msg]),
      safeLog(Tail, Clock);
    true ->
      [{From, Time, Msg} | Tail]
  end.
