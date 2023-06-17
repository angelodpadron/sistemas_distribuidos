-module(worker).
-export([start/4]).

start(Id, Manager, Sleep, Jitter) ->
  spawn(fun() -> init(Id, Manager, Sleep, Jitter) end).

init(Id, Manager, Sleep, Jitter) ->
  Manager ! {join, self(), Id, Jitter},

  receive
    {joined, Multicast} ->
      Gui = gui:start(Id),
      loop(Manager, Multicast, Gui, Sleep)
  end.

loop(Manager, Multicast, Gui, Sleep) ->
  receive
    {receive_message, Value} ->
      Gui ! {set, Value},
      loop(Manager, Multicast, Gui, Sleep);
    stop ->
      Manager ! {leave, Multicast},
      Gui ! stop,
      ok
  after Sleep ->
      Value = random:uniform(255),
      Multicast ! {send, Value},
      loop(Manager, Multicast, Gui, Sleep)
  end.