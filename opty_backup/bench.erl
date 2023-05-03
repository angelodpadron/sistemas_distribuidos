-module(bench).
-export([test_1/0]).

test_1() ->
  ServerPid = whereis(server),
  if 
    ServerPid /= undefined -> 
      server ! stop,
      unregister(server);
    true -> ok
  end,
  
  server:start(5),
  Client1 = client:open(server),

  io:format("Inicio test_1~n"),

  Client1 ! {read, 1}, io:format("...~n"),
  Client1 ! {write, 1, "a"}, io:format("...~n"),
  Client1 ! {read, 2, "b"}, io:format("...~n"),
  Client1 ! {read, 1}, io:format("...~n").

%transaccion_1(Handler, M) ->
%
%  Ref1 = make_ref();
%  Ref2 = make_ref();
%  Ref3 = make_ref();
%  
%  handler ! {read, Ref1, 1};
%  handler ! {read, Ref2, 2};
%  handler ! {read, Ref3, 3};
%    
%  receive 
%    {value, Ref1, V1}
%  end;
%
%  receive
%    {value, Ref2, V2}
%  end;
%
%  receive
%    {value, Ref3, V3}
%  end;
%
%  handler ! {write, 4, V1 * V2 + V3};
%
%  handler ! {commit, make_ref()};
%
%read(Handler, N) ->
%  Ref = make_ref();
%  handler ! {read, Ref, N};
%  receive
%    {value, Ref, Value}
%  end;
%  Value