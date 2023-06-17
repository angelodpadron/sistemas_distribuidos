-module(manager).

-export([start/1]).

-import(lists, [foreach/2]).

start(MulticastModule) ->
  spawn(fun() -> init(MulticastModule, []) end).

init(MulticastModule, Nodes) ->
  receive
    {join, Client, Id, Jitter} ->
      NewNode = apply(MulticastModule, start, [Id, Client, Nodes, Jitter]),
      foreach(fun(Pid) -> Pid ! {nodeJoined, NewNode} end, Nodes),
      Client ! {joined, NewNode},
      init(MulticastModule, [NewNode | Nodes]);
    {leave, Node} ->
      NewNodes = lists:delete(Node, Nodes),
      foreach(fun(Pid) -> Pid ! {nodeRemoved, Node} end, NewNodes),
      init(MulticastModule, NewNodes)
  end.
