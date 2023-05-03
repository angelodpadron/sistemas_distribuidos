-module(client).
-export([open/1]).

open(Server) ->
  Server ! {open, self()},
  receive
    {transaction, Validator, Store} ->
      Handler = handler:start(self(), Validator, Store),
      spawn(fun() -> init(Handler) end)
  end.

init(Handler) ->
  client(Handler).
  
client(Handler) ->
  receive
    {read, N} ->
      Ref = make_ref(),
      Handler ! {read, Ref, N},
      receive %No entra nuca aca y no sigue
        {value, Ref, Value} -> 
          io:format("Value: ~w~n", [Value]) 
      end,
      client(Handler);
    {write, N, Value} ->
      Handler ! {write, N, Value},
      client(Handler);
    {commit} ->
      Ref = make_ref(),
      Handler ! {commit, Ref},
      receive  
        {Ref, ok} -> 
          io:format("Commiteado si nproblemas!!~n", []);
        {Ref, abort} -> 
          io:format("Error al hacer commit.~n", [])
      end,
      client(Handler);
    {abort} ->
      Handler ! abort,
      ok;
    {state} ->
      client(Handler)
  end.
    
