-module(server).
-export([start/1, stop/1]).

start(N) ->
  Server = spawn(fun() -> init(N) end),
  register(server, Server).

stop(Server) ->
  Server ! stop.

init(N) ->
  Store = store:new(N),
  Validator = validator:start(),
  server(Validator, Store).

server(Validator, Store) ->
  receive
    {open, Client} ->
      Client ! {transaction, Validator, Store},
      server(Validator, Store);
    {store, Validator} ->
      Validator ! {store, Store},
      server(Validator, Store);
    {updateStore, NewStore} ->
      server(Validator, NewStore);
    stop ->
       store:stop(Store)
  end.

