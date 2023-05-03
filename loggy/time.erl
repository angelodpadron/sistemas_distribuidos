-module(time).
-export([zero/0, inc/2, merge/2, leq/2, clock/1, update/3, safe/2]).

zero() ->
  0.

inc(Name, T) ->
  T + 1.

merge(Ti, Tj) ->
  if Ti < Tj -> 
      Tj;
  true ->
      Ti
  end.

leq(Ti, Tj) ->
  Ti < Tj.

clock(Nodes) -> 
  lists:map(fun(Node) -> {Node, time:zero()} end, Nodes).

update(Node, Time, Clock) -> 
  lists:map(fun({CNode, CTime}) -> {CNode, iif(Node==CNode, Time, CTime)} end, Clock).

safe(Time, Clock) -> 
  lists:foldl(fun({_, CTime}, Acc) -> (CTime >= Time) and Acc end, true, Clock).


iif(Exp, TrueValue, FalseValue) -> 
  case Exp of
    true -> 
     TrueValue;
    false ->
     FalseValue
  end.
