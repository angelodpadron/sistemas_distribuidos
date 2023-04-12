-module(consumer).
-export([start/1, stop/0]).

start(Producer) ->
    Consumer = spawn(fun() -> init(Producer) end),
    register(consumer, Consumer).

stop() ->
    consumer ! stop.

init(Producer) ->
    Monitor = monitor(process, Producer),
    Producer ! {hello, self()},
    consumer(0, Monitor).

consumer(N, Monitor) ->
    receive
        {ping, Count} ->
            if
                N == Count -> 
                  io:format("Ping ~b~n", [N]);
                true ->
                  io:format("Warning: Expected ping ~b but received ping ~b instead~n", [N, Count])
            end,
            consumer(Count+1, Monitor);
        stop ->
            io:format("Stop message received. Bye!~n"),
            ok;
        bye ->
            io:format("Producer exited.~n"),
            ok;
        % monitor crash report
        {'DOWN', Monitor, process, Object, Info} ->
            io:format("~w died; ~w~n", [Object, Info]),
            consumer(N + 1, Monitor)
    end.
