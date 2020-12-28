:- dynamic([messages/1]).

:- table background_char/3.

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

draw_background(Screen) :-
    Screen = rectangle(coord(ULX, ULY), coord(LRX, LRY)),
    numlist(ULX, LRX, Xs),
    numlist(ULY, LRY, Ys),
    forall(member(Y, Ys), (
        maplist([X,C]>>background_char(X,Y,C), Xs, Cs),
        text_to_string(Cs, Str),
        Index #= Y - ULY,
        add_sidebar(Index, Str, S),
        writeln(S)
    )).

add_sidebar(Index, Str, Out) :-
    (
        Index #= 2,
        health(player, HP),
        format(string(Out), '~w  Player HP:   ~w/10', [Str, HP])
    ;
        Index #= 3,
        manapool(player, MP),
        format(string(Out), '~w  Player MP:   ~w', [Str, MP])
    ;
        Index #= 4,
        health(0, HP),
        format(string(Out), '~w  Minotaur HP: ~w/20', [Str, HP])
    ;
        Index #= 5,
        manapool(0, MP),
        format(string(Out), '~w  Minotaur MP: ~w', [Str, MP])
    ;
        Index #= 6,
        health(1, HP),
        format(string(Out), '~w  Minotaur HP: ~w/20', [Str, HP])
    ;
        Index #= 7,
        manapool(1, MP),
        format(string(Out), '~w  Minotaur MP: ~w', [Str, MP])
    ;
        (not(memberchk(Index, [2,3,4,5,6,7]))),
        Out = Str
    ).

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
    pos(player, PC),
    draw_on_screen(Screen, PC, [fg(yellow)], '@', []),
    % draw the minotaur if visible
    % TODO: if visible
    forall(type(Instance, _), (
        pos(Instance, MC),
        draw_on_screen(Screen, MC, [fg(red)], 'M', [])
    )).

draw_messages :-
    detect_screen_size(_, Height),
    NextY #= Height + 1,
    tty_goto(0, NextY),
    messages(MessageLog),
    take(5, MessageLog, Messages),
    reverse(Messages, RevMessages),
    forall(member(Colour-Str-Fmt, RevMessages), (
        ansi_format([fg(Colour)], Str, Fmt),
        write('\n')
    )).

draw_screen :-
    tty_clear,
    tty_goto(0, 0),
    detect_screen_size(Width, Height),
    screen(Width, Height, Screen),
    draw_background(Screen),
    draw_objects(Screen),
    draw_messages.

% tty_size detects terminal screen size and updates
% should enforce both Width and Height are uneven
% (so player is neatly in the middle)
detect_screen_size(Width, Height) :-
    tty_size(Rows, Columns),
    XOffset #= 30,
    YOffset #= 10,
    (
        Columns mod 2 #= 0
    ->
        Width #= Columns - XOffset - 1
    ;
        Width #= Columns - XOffset
    ),
    (
        Rows mod 2 #= 0
    ->
        Height #= Rows - YOffset - 1
    ;
        Height #= Rows - YOffset
    ).
% get the screen coordinates relative to player position
screen(Width, Height, Screen) :-
    pos(player, coord(PX, PY)),
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
    assertz(messages([Colour-String-FmtArgs|MessageLog])),
    draw_messages.

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
