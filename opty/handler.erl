-module(handler).

-export([start/3]).

start(Client, Validator, Store) ->
  spawn_link(fun() -> init(Client, Validator, Store) end).

init(Client, Validator, Store) ->
  handler(Client, Validator, Store, [], []).

handler(Client, Validator, Store, Reads, Writes) ->
  io:format("Handler reads: ~p~n", [Reads]),
  io:format("Handler writes: ~p~n", [Writes]),
  receive
    {read, Ref, N} ->
      case lists:keysearch(N, 1, Writes) of
        {value, {N, _, Value}} ->
          io:format("Value loaded from writes: ~p~n", [Value]),
          Client ! {value, Ref, Value},
          handler(Client, Validator, Store, Reads, Writes);
        false ->
          io:format("Value loaded from store~n", []),
          Entry = store:lookup(N, Store),
          Entry ! {read, Ref, self()},
          handler(Client, Validator, Store, Reads, Writes)
      end;
    {Ref, Entry, Value, Time} ->
      Client ! {value, Ref, Value},
      handler(Client, Validator, Store, [{Entry, Time} | Reads], Writes);
    {write, N, Value} ->
      Entry = store:lookup(N, Store),
      Added = [{N, Entry, Value} | Writes],
      handler(Client, Validator, Store, Reads, Added);
    {commit, Ref} ->
      Validator ! {validate, Ref, Reads, Writes, Client};
    abort ->
      ok
  end.
