% caching helps performance a lot here
:- dynamic(background/1, messages/1).

% setup background
initialize_ui :-
    map_size(MapX, MapY), 
    range(0, MapX, XRange),
    range(0, MapY, YRange),
    maplist([Y,YY]>>(
        maplist([X,XX]>>(
            background_char(X,Y,XX)
        ), XRange, CharList),
        text_to_string(CharList, YY)
    ), YRange, Background),
    retractall(background(_)),
    assertz(background(Background)).
   
background_char(X, Y, C) :-
    (
        wall(coord(X,Y))
    ->
        C = '#'
    ;
        (
            tile(coord(X,Y))
        ->
            C = '.'
        ;
            C = ' '
        )
    ).

% bunch of stuff happening in here, lots of bugs. needs cleanup
% NOTE: ULX and ULY can be negative, meaning screen is bigger than map
% similarly, LRX and LRY can run out of the map bounds
% need to buffer all of that with blank lines
% KNOWN BUGS: incorrect padding, walls at coordinates -1 dont get drawn
draw_background(Width, Height, Screen) :-
    Screen = rectangle(coord(ULX, ULY), coord(_, LRY)),
    % MULX and MULY are the upper left coordinates but with lower bound 0 
    % use those to take the slice out of background that we can draw
    (
        ULX #< 0
    -> 
        MULX #= 0,
        % if ULX is negative we need to pad each line with some spaces
        DX #= ULX * -1,
        length(XBlanks, DX),
        subset(XBlanks, [' ']),
        text_to_string(XBlanks, XBuff)
    ;
        MULX #= ULX,
        XBuff = ""
    ),
    (
        ULY #< 0
    -> 
        MULY #= 0,
        % if ULY is negative we need to pad the top with newlines
        DY #= (ULY * -1) - 1,
        range(0, DY, YR),
        forall(member(_,YR), write('\n'))
    ;
        MULY #= ULY,
        DY #= 0
    ),
    background(TotalBackground),
    length(Prefix, MULY),
    append(Prefix, Rest, TotalBackground),
    % background is a list of strings
    % find the correct slice to fit the screen
    % NOTE: we can run over the mapY limit
    map_size(MapX, MapY),
    (
        SHeight #= Height - DY,
        MULY + SHeight #< MapY 
    ->
        length(Background, SHeight),
        append(Background, _, Rest)
    ;
        Background = Rest
    ),
    (
        MULX + Width #< MapX
    ->
        % draw the slice of the line starting at MULX with len Width
        forall(member(Line, Background), (
            sub_string(Line, MULX, Width, _, Sub),
            format('~w~w\n', [XBuff, Sub])
        ))
    ;
        % if we run over the mapX limit just draw the entire suffix
        forall(member(Line, Background), (
            sub_string(Line, MULX, _, 0, Sub),
            format('~w~w\n', [XBuff, Sub])
        ))
    ),
    % add blank lines if the map runs out at the bottom
    (
        MapY #< LRY
    ->
        LDY #= LRY - MapY + 1,
        range(1, LDY, LYR),
        forall(member(_,LYR), write('\n'))
    ;
        noop
    ),
    messages(MessageLog),
    take(5, MessageLog, Messages),
    reverse(Messages, RevMessages),
    forall(member(Colour-Str-Fmt, RevMessages), (
        ansi_format([fg(Colour)], Str, Fmt),
        write('\n')
    )),
    %%%
    % debug statements
    player(PC),
    minotaur(MC),
    (
        dijkstra(PC, MC, Path)
    ->
        forall(member(C, Path), (
            draw_on_screen(Screen, C, [bg(red)], ' ', [])
        ))
    ;
        noop
    ),
    tty_goto(0, Height).
    %%% 

% draw at relative position based on screen coords
draw_on_screen(Screen, coord(X,Y), Args, Str, Fmt) :-
    Screen = rectangle(coord(ULX, ULY), coord(LRX, LRY)),
    (
        X #>= ULX, X #=< LRX,
        Y #>= ULY, Y #=< LRY
    ->
        DX #= X - ULX,
        DY #= Y - ULY,
        tty_goto(DX, DY),
        ansi_format(Args, Str, Fmt)
    ;
        noop
    ).

draw_objects(Screen) :-
    player(PC),
    draw_on_screen(Screen, PC, [fg(yellow)], '@', []),
    % draw the minotaur if visible
    % TODO: if visible
    minotaur(MC),
    draw_on_screen(Screen, MC, [fg(red)], 'M', []).

draw_screen :-
    tty_clear,
    tty_goto(0, 0),
    detect_screen_size(Width, Height),
    screen(Width, Height, Screen),
    draw_background(Width, Height, Screen),
    draw_objects(Screen),
    % TODO: rest of the ui like messages and such
    NextY #= Height + 1,
    tty_goto(0, NextY).

% tty_size detects terminal screen size and updates
% should enforce both Width and Height are uneven
% (so player is neatly in the middle)
detect_screen_size(Width, Height) :-
    tty_size(Rows, Columns),
    Offset #= 10,
    (
        Columns mod 2 #= 0
    ->
        Width #= Columns - Offset - 1
    ;
        Width #= Columns - Offset
    ),
    (
        Rows mod 2 #= 0
    ->
        Height #= Rows - Offset - 1
    ;
        Height #= Rows - Offset
    ).
% get the screen coordinates relative to player position
screen(Width, Height, Screen) :-
    player(coord(PX, PY)),
    Screen = rectangle(coord(ULX, ULY), coord(LRX, LRY)),
    % TODO: definition of rectangle_midpoint, get instantiation err without it
    % should be able to just call rectangle_midpoint and be done
    %%%
    Width #= LRX - ULX,
    Height #= LRY - ULY,
    PX #= ULX + (Width // 2),
    PY #= ULY + (Height // 2),
    %%%
    rectangle_midpoint(Screen, coord(PX, PY)).

handle_command('k') :-
    move_relative(player, 0, -1).
handle_command('h') :-
    move_relative(player, -1, 0).
handle_command('j') :-
    move_relative(player, 0, 1).
handle_command('l') :-
    move_relative(player, 1, 0).
handle_command(X) :-
    not(memberchk(X, ['k','h','j','l','q'])),
    format('Unrecognized command ~w\n', [X]).

add_message(Colour, String, FmtArgs) :-
    messages(MessageLog),
    retractall(messages(_)),
    assertz(messages([Colour-String-FmtArgs|MessageLog])).

take(N, List, Pref) :-
    length(List, Len),
    (
     	N #>= Len
    ->
    	Pref = List
    ;
    	length(Pref, N),
    	prefix(Pref, List)
    ).
