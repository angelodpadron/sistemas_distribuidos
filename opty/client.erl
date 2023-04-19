-module(client).

-export([start/1]).

start(Server) ->
  Server ! {open, self()},
  receive
    {Validator, Store} ->
      spawn_link(fun() -> init(Validator, Store) end)         
  end.

init(Validator, Store) ->
  Handler = handler:start(self(), Validator, Store),
  client(Handler).

client(Handler) ->
  io:format("Client started~n", []),
  receive
    {read, Ref, N} ->
      Handler ! {read, Ref, N}, 
      client(Handler);
    {write, N, Value} ->
      Handler ! {write, N, Value},
      io:format("Entry added~n", []),
      client(Handler);
    {value, Ref, Value} ->
      io:format("Value: ~p~n", [Value]),
      io:format("Ref: ~p~n", [Ref]),
      client(Handler);
    {commit, Ref} ->
      Handler ! {commit, Ref},
      client(Handler);
    stop ->
      ok
  end.

  
  


% transaccion_1(Handler, M) ->

%   Ref1 = make_ref();
%   Ref2 = make_ref();
%   Ref3 = make_ref();
  
%   handler ! {read, Ref1, 1};
%   handler ! {read, Ref2, 2};
%   handler ! {read, Ref3, 3};
    
%   receive 
%     {value, Ref1, V1}
%   end;

%   receive
%     {value, Ref2, V2}
%   end;

%   receive
%     {value, Ref3, V3}
%   end;

%   handler ! {write, 4, V1 * V2 + V3};

%   handler ! {commit, make_ref()};

% read(Handler, N) ->
%   Ref = make_ref();
%   handler ! {read, Ref, N};
%   receive
%     {value, Ref, Value}
%   end;
%   Value