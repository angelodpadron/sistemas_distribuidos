-module(server).

-export([start/1, open/1, stop/1]).

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
      io:format("Open: ~p~n", [Client]),
      Client ! {Validator, Store},
      server(Validator, Store);
    stop ->
      io:format("Stopping server~n", []),
      store:stop(Store)
  end.

open(Server) ->
  Server ! {open, self()},
  receive
    {transaction, Validator, Store} ->
      handler:start(self(), Validator, Store)
  end.
