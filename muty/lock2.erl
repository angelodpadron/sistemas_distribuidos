% lock that complies with safety and liveness

-module(lock2).

-export([start/1]).

start(Id) ->
    spawn(fun() -> init(Id) end).

init(Id) ->
    receive
        {peers, Peers} ->
            open(Peers, Id);
        stop ->
            ok
    end.

open(Nodes, Id) ->
    receive
        {take, Master} ->
            Refs = requests(Nodes, Id),
            wait(Nodes, Master, Refs, [], Id);
        {requests, From, Ref, _} ->
            From ! {ok, Ref},
            open(Nodes, Id);
        stop ->
            ok
    end.

requests(Nodes, Id) ->
    lists:map(fun(P) ->
                 R = make_ref(),
                 P ! {request, self(), R, Id},
                 R
              end,
              Nodes).

wait(Nodes, Master, [], Waiting, Id) ->
    Master ! taken,
    held(Nodes, Waiting, Id);
wait(Nodes, Master, Refs, Waiting, Id) ->
    receive
        {request, From, Ref, LockId} ->
            
            if
                Id < LockId ->
                    wait(Nodes, Master, Refs, [{From, Ref} | Waiting], Id);   
                true ->
                    From ! {ok, Ref},
                    wait(Nodes, Master, Refs, Waiting, Id)
            end;

        {ok, Ref} ->
            Refs2 = lists:delete(Ref, Refs),
            wait(Nodes, Master, Refs2, Waiting, Id);
        release ->
            broadcast_ok(Waiting),
            open(Nodes, Id)
    end.


broadcast_ok(Waiting) ->
    lists:foreach(fun({F, R}) -> F ! {ok, R} end, Waiting).

held(Nodes, Waiting, Id) ->
    receive
        {request, From, Ref, _} ->            
            held(Nodes, [{From, Ref} | Waiting], Id);
        release ->
            broadcast_ok(Waiting),
            open(Nodes, Id)
    end.
