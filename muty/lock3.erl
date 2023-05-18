-module(lock3).

-export([start/1]).

start(Id) ->
    spawn(fun() -> init(Id) end).

init(Priority) ->
    receive
        {peers, Peers} ->
            InitialTime = time:zero(),
            open(Peers, Priority, InitialTime);
        stop ->
            ok
    end.

open(Nodes, Priority, Time) ->
    receive
        {take, Master} ->
            NewTime = time:inc(Time),
            Refs = requests(Nodes, Priority, NewTime),
            wait(Nodes, Priority, Master, Refs, [], NewTime);
        {request, From, _, Ref, MsgTime} ->
            NewTime = time:merge(Time, MsgTime),
            From ! {ok, Ref},
            open(Nodes, Priority, NewTime);
        stop ->
            ok
    end.

requests(Nodes, Priority, Time) ->
    lists:map(fun(P) ->
                 R = make_ref(),
                 P ! {request, self(), Priority, R, Time},
                 R
              end,
              Nodes).

wait(Nodes, Priority, Master, [], Waiting, Time) ->
    Master ! taken,
    held(Nodes, Priority, Waiting, Time);
wait(Nodes, Priority, Master, Refs, Waiting, Time) ->
    receive
        {request, From, FromPriority, Ref, MsgTime} ->
            MsgTimeLower = time:leq(MsgTime, Time),
            EqualTimes = time:eq(MsgTime, Time),
            if MsgTimeLower or (EqualTimes and (FromPriority < Priority)) ->
                   From ! {ok, Ref},
                   R = make_ref(),
                   From ! {request, self(), Priority, R, Time},
                   wait(Nodes, Priority, Master, [R | Refs], Waiting, Time);
               true ->
                   wait(Nodes, Priority, Master, Refs, [{From, Ref} | Waiting], Time)
            end;
        {ok, Ref} ->
            Refs2 = lists:delete(Ref, Refs),
            wait(Nodes, Priority, Master, Refs2, Waiting, Time);
        release ->
            ok(Waiting),
            open(Nodes, Priority, Time)
    end.

ok(Waiting) ->
    lists:foreach(fun({F, R}) -> F ! {ok, R} end, Waiting).

held(Nodes, Priority, Waiting, Time) ->
    receive
        {request, From, Priority, Ref, MsgTime} ->
            NewTime = time:merge(Time, MsgTime),
            held(Nodes, Priority, [{From, Ref} | Waiting], NewTime);
        release ->
            ok(Waiting),
            open(Nodes, Priority, Time)
    end.
