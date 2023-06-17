-module(gui).

-export([start/1, init/1]).

-include_lib("wx/include/wx.hrl").

start(Name) ->
    spawn(gui, init, [Name]).

init(Name) ->
    Width = 350,
    Height = 200,
    Server = wx:new(),
    Frame = wxFrame:new(Server, -1, Name, [{size, {Width, Height}}]),
    InitialColor = {0, 0, 0},
    wxFrame:show(Frame),
    wxFrame:setBackgroundColour(Frame, InitialColor),
    loop(Name, Frame, InitialColor).

loop(Name, Frame, {R, G, B}) ->
    receive
        {set, Value} ->
            NewColour = {G, B, (R + Value) rem 256},
            io:format("~s new color: ~p~n", [Name, NewColour]),
            wxFrame:setBackgroundColour(Frame, NewColour),
            wxFrame:refresh(Frame),
            loop(Name, Frame, NewColour);
        stop ->
            ok;
        Error ->
            io:format("gui: strange message ~w ~n", [Error]),
            loop(Name, Frame, {R, G, B})
    end.