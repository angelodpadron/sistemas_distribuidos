-module(handler).
-export([start/3]).

start(Client, Validator, Store) ->
  spawn_link(fun() -> init(Client, Validator, Store) end).

init(Client, Validator, Store) ->
  handler(Client, Validator, Store, [], []).

handler(Client, Validator, Store, Reads, Writes) ->
  receive
    {read, Ref, N} ->
      case lists:keysearch(N, 1, Writes) of
        {value, {N, _, Value}} ->
          Client ! {value, Ref, Value},
          handler(Client, Validator, Store, Reads, Writes);
        false ->
          Entry = store:lookup(N, Store),
          Entry ! {read, Ref, self()},
          handler(Client, Validator, Store, Reads, Writes)
      end;
    {Ref, Entry, Value, Time} -> 
      Client ! {value, Ref, Value},
      handler(Client, Validator, Store, [{Entry, Time}|Reads], Writes);
    {write, N, Value} ->
      Entry = store:lookup(N, Store),
      Added = [{N, Entry, Value}|Writes],
      handler(Client, Validator, Store, Reads, Added);
    {commit, Ref} ->
      Validator ! {validate, Ref, Reads, Writes, self()},
      receive  
        {Ref, ok, NewStore} -> 
          Client ! {Ref, ok},
          server ! {store, self()},
            receive
              {store, NewStore} -> handler(Client, Validator, NewStore, [], [])
            end;
        {Ref, abort} -> 
          Client ! {Ref, abort},
          handler(Client, Validator, Store, Reads, Writes)
      end;
    abort -> ok
  end.
