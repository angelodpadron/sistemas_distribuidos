- module(multicast_b).

- export ([start/4]).

start(_, Master, Nodes, Jitter) ->
  spawn(fun() -> init(Master, Nodes, Jitter) end).

init(Master, Nodes, Jitter) ->
  server(Master, Nodes, Jitter).
                   
server(Master, Nodes, Jitter) ->
  jitter(Jitter),
  receive
  {nodeJoined, NewNode} ->
    server(Master, [NewNode | Nodes], Jitter);
  
  {send, Msg} ->
    lists:foreach(fun(Node) -> Node ! {deliver, Msg} 
                    end, [self() | Nodes]), 
      server(Master, Nodes, Jitter);

  {deliver, Msg} ->
    Master ! {receive_message, Msg},
    server(Master, Nodes, Jitter)
  end.


jitter(0) ->
    ok;
jitter(Jitter) ->
    timer:sleep(
        random:uniform(Jitter)).
