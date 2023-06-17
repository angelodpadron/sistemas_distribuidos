- module(multicast_to).

- export ([start/4]).
%- export ([request/4, cast/3, insert/4, increment/1, increment/2, bestSequence/2, proposal/3, agree/3, update/3, agreed/2, deliver/2]). %Solo para pruebas.


start(Id, Master, Nodes, Jitter) ->
  spawn(fun() -> init(Id, Master, Nodes, Jitter) end).

init(Id, Master, Nodes, Jitter) ->
  Next = {initialSequence(), Id},
  server(Master, Next, Nodes, [], [], Jitter).


server(Master, Next, Nodes, Cast, Queue, Jitter) ->
  receive
    {nodeJoined, Node} ->
        server(Master, Next, [Node | Nodes], Cast, Queue, Jitter);
    {nodeRemoved, Node} ->
        server(Master, Next, [Node | Nodes], Cast, Queue, Jitter);
    
    {send, Msg} -> %el cliente envia un mensaje de broadcast para el grupo
      Ref = make_ref(),
      request([self() | Nodes], Ref, Msg, -1), % ?,?,?,?
      Cast2 = cast(Cast, Ref, length(Nodes) + 1), % ?,?,?
      server(Master, Next, Nodes, Cast2, Queue, Jitter);

    {request, From, Ref, Msg} -> %un nodo par envia un mensaje para solicitar propuesta de secuencia
      jitter(Jitter),
      From ! {proposal, Ref, Next}, %?,?
      Queue2 = insert(Queue, Next, Ref, Msg), %?,?,?,?
      Next2 = increment(Next), %?
      server(Master, Next2, Nodes, Cast, Queue2, Jitter);

    {proposal, Ref, Proposal} -> %recibo propuestas de secuencia de los nodos pares
      case proposal(Cast, Ref, Proposal) of %?,?,?
        {agreed, Seq, Cast2} ->
          agree(Nodes, Ref, Seq), %?,?,?
          server(Master, Next, Nodes, Cast2, Queue, Jitter);
        Cast2 ->
          server(Master, Next, Nodes, Cast2, Queue, Jitter)
      end;
    
    {agreed, Ref, Seq} -> %recibo confirmacion de secuencia aceptada
      Updated = update(Queue, Ref, Seq), %?,?,?
      {Agreed, Queue2} = agreed(Updated, -1), %?,?
      deliver(Master, Agreed), %?,?
      Next2 = increment(Next, Seq), %?,?
      server(Master, Next2, Nodes, Cast, Queue2, Jitter)
    
  end.



jitter(0) ->
  ok;
jitter(Jitter) ->
  timer:sleep(rand:uniform(Jitter)).




request(Nodes, Ref, Msg, _) ->
  lists:foreach(fun(Node) -> Node ! {request, self(), Ref, Msg} end, Nodes).
  
initialSequence() -> 1.
cast(Cast, Ref, PendingAgreements) ->
  Seq = {initialSequence(), "_"},
  [{Ref, PendingAgreements, Seq} | Cast].

insert(Queue, {Order, _}, Ref, Msg) -> %retorna Cast con el nuevo mensaje (o la referencia) sin secuencia final encolado
  [{{proposed, Order}, Ref, Msg} | Queue].

increment({Seq, Id}) -> {Seq + 1, Id}.

increment({Seq, Id}, AgreedSeq) -> {lists:max([Seq, AgreedSeq]) + 1, Id}.

bestSequence(ASeq, BSeq) ->
  lists:max([ASeq, BSeq]).
proposal(Cast, Ref, ProposedNodeSeq) ->
  case lists:foldl(fun({CastRef, PendingAgreements, CastSeq}, {AgreedSeq, RemainingCast}) -> 
                      if
                        CastRef == Ref ->
                          if
                            PendingAgreements == 1 ->
                              {Seq, _} = bestSequence(ProposedNodeSeq, CastSeq),
                              {Seq, RemainingCast};
                            true ->
                              {AgreedSeq, [{CastRef, PendingAgreements-1, bestSequence(ProposedNodeSeq, CastSeq)} | RemainingCast]}
                          end;
                        true ->
                          {AgreedSeq, [{CastRef, PendingAgreements, CastSeq} | RemainingCast]}
                      end
                    end, {0,[]}, Cast) of
    {0, Cast2} ->
      Cast2;
    {AgreedSeq, Cast2} ->
      {agreed, AgreedSeq, Cast2}
  end.
  
agree(Nodes, Ref, Seq) -> %envia confirmacion de secuencia aceptada a los demas nodos
  lists:foreach(fun(Node) -> Node ! {agreed, Ref, Seq} end, Nodes),
  self() ! {agreed, Ref, Seq}.

update(Queue, Ref, Seq) -> %actualiza la queue con la secuencia acordada
  Queue2 = lists:map(fun({Order, QRef, Msg}) -> 
                      if
                        QRef == Ref ->
                          {{agreed, Seq}, QRef, Msg};
                        true ->
                          {Order, QRef, Msg}
                      end
                     end, Queue),
  lists:sort(fun({{_, AOrder}, _, _}, {{_, BOrder}, _, _}) -> AOrder < BOrder end, Queue2).
                          
agreed(Queue, _) -> %retorna los mensajes listos para entregar y el resto de la queue
  lists:foldl(fun({Order, Ref, Msg}, {Agreed, Queue2}) -> 
                {OrderState, _} = Order,
                if
                  (Queue2 == []) and (OrderState == agreed) ->
                    {[ Msg | Agreed], Queue2};
                  true ->
                    {Agreed, [ {Order, Ref, Msg} | Queue2]}
                end
              end, {[],[]}, Queue).
  
deliver(Master, Agreed) ->
  lists:foreach(fun(Msg) -> Master ! {receive_message, Msg} end, Agreed).