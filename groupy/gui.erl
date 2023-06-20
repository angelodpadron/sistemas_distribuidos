-module(gui).

-export([start/2, init/2]).

start(Name, Pos) ->
    spawn(gui, init, [Name, Pos]).

init(Name, Pos) ->
  Width = 200,
  Height = 200,
  X = Pos * 50,
  Y = Pos * 25 + 10,
  Server = wx:new(),
  Frame = wxFrame:new(Server, -1, Name, [ {pos, {X, Y}},
                                          {size, {Width, Height}} ]),
  InitialColor = {0, 0, 0},
  Pt = {X, Y},
  wxFrame:show(Frame),
  wxFrame:setBackgroundColour(Frame, InitialColor),
  loop(Name, Frame, InitialColor, Pt).

loop(Name, Frame, {R, G, B}, Pt) ->
  receive
    {set, Value} ->
      %io:format("gui[~s]: received message [~w] ~n", [Name,Value]),
      NewColour = {G, B, (R + Value) rem 256},
      wxFrame:setBackgroundColour(Frame, NewColour),
      wxFrame:move(Frame, Pt),
      wxFrame:refresh(Frame),
      loop(Name, Frame, NewColour, Pt);
    stop ->
      ok;
    Error ->
      io:format("gui: strange message ~w ~n", [Error]),
      loop(Name, Frame, {R, G, B}, Pt)
  end.