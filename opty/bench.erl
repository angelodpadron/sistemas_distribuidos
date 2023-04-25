-module(bench).

-export([start_write_bench/2, start_read_bench/2]).

start_write_bench(Server, NumberOfTransactions) ->
    Server ! {open, self()},
    receive
        {Validator, Store} ->
            Handlers = create_handlers(Validator, Store, NumberOfTransactions),
            Refs = [make_ref() || _ <- lists:seq(1, NumberOfTransactions)],
            start_write_transactions(Handlers, Refs)
    end.

start_read_bench(Server, NumberOfTransactions) ->
    Server ! {open, self()},
    receive
        {Validator, Store} ->
            Handlers = create_handlers(Validator, Store, NumberOfTransactions),
            Refs = [make_ref() || _ <- lists:seq(1, NumberOfTransactions)],
            start_read_transactions(Handlers, Refs)
    end.

start_read_transactions(Handlers, Refs) ->
    io:format("Sending transactions~n", []),
    RefsHandlers = lists:zip(Refs, Handlers),
    StartTime = erlang:system_time(micro_seconds),
    lists:foreach(fun({Ref, Handler}) ->
                     lists:foreach(fun(N) -> read_transaction(Handler, Ref, N) end,
                                   lists:seq(1, length(RefsHandlers)))
                  end,
                  RefsHandlers),

    io:format("Awaiting confirmations~n", []),
    wait_transactions(Refs, StartTime, length(Refs)).

start_write_transactions(Handlers, Refs) ->
    io:format("Sending transactions~n", []),
    RefsHandlers = lists:zip(Refs, Handlers),
    StartTime = erlang:system_time(micro_seconds),
    lists:foreach(fun({Ref, Handler}) ->
                     lists:foreach(fun(N) -> write_transaction(Handler, N, rand:uniform(100), Ref)
                                   end,
                                   % read_transaction(Handler, Ref, N)
                                   lists:seq(1, length(RefsHandlers)))
                  end,
                  RefsHandlers),

    io:format("Awaiting confirmations~n", []),
    wait_transactions(Refs, StartTime, length(Refs)).

create_handlers(_, _, 0) ->
    [];
create_handlers(Validator, Store, N) ->
    [handler:start(self(), Validator, Store) | create_handlers(Validator, Store, N - 1)].

read_transaction(Handler, Ref, N) ->
    Handler ! {read, Ref, N},
    Handler ! {commit, Ref}.

write_transaction(Handler, Entry, Value, Ref) ->
    Handler ! {write, Entry, Value},
    Handler ! {commit, Ref}.

wait_transactions([], StartTime, NumberOfTransactions) ->
    EndTime = erlang:system_time(micro_seconds),
    io:format("All transactions finished in ~p ms ~n", [(EndTime - StartTime) / 1000]),
    io:format("Average transaction time: ~p ms~n",
              [(EndTime - StartTime) / NumberOfTransactions / 1000]),
    io:format("Throughput: ~p transactions per second~n",
              [NumberOfTransactions / ((EndTime - StartTime) / 1000000)]),
    ok;
wait_transactions([Ref | Refs], StartTime, NumberOfTransactions) ->
    receive
        {Ref, abort} ->
            io:format("Transaction ~p aborted~n", [Ref]),
            wait_transactions(Refs, StartTime, NumberOfTransactions);
        {Ref, ok} ->
            io:format("Transaction ~p finished~n", [Ref]),
            wait_transactions(Refs, StartTime, NumberOfTransactions)
    after 10000 ->
        io:format("Timeout waiting for transaction ~p~n", [Ref]),
        wait_transactions(Refs,
                          StartTime + 10000 * 1000,
                          NumberOfTransactions) % mental gymnastics right here
    end.
