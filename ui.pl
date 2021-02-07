:- dynamic([messages/1]).

background_char(X, Y, C) :-
    (
        wall(coord(X,Y))
    ->
        (visible(coord(X,Y)) -> C = '#' ; (seen(coord(X,Y)) -> C = 'x' ; C = ' '))
    ;
        (
            tile(coord(X,Y))
        ->
            (visible(coord(X,Y)) -> C = '.' ; (seen(coord(X,Y)) -> C = ' ' ; C = ' '))
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
        writeln(Str)
    )).

draw_sidebar(Width) :-
    tty_goto(Width, 2),
    health(player, HP),
    format(' Player HP:   ~w/10', [HP]),
    tty_goto(Width, 3),
    manapool(player, MP),
    format(' Player MP:   ~w', [MP]),
    tty_goto(Width, 4),
    (health(0, X) -> M1HP = X ; M1HP = 0),
    format(' Minotaur HP: ~w/20', [M1HP]),
    tty_goto(Width, 5),
    (manapool(0, X) -> M1MP = X ; M1MP = 0),
    format(' Minotaur MP: ~w', [M1MP]),
    tty_goto(Width, 6),
    (health(1, X) -> M2HP = X ; M2HP = 0),
    format(' Minotaur HP: ~w/20', [M2HP]),
    tty_goto(Width, 7),
    (manapool(1, X) -> M2MP = X ; M2MP = 0),
    format(' Minotaur MP: ~w', [M2MP]).

pos_on_screen(Screen, coord(X,Y)) :-
    Screen = rectangle(coord(ULX, ULY), coord(LRX, LRY)),
    X #>= ULX, X #=< LRX,
    Y #>= ULY, Y #=< LRY.

% draw at relative position based on screen coords
draw_on_screen(Screen, Pos, Args, Str, Fmt) :-
    Screen = rectangle(coord(ULX, ULY), _),
    (
        pos_on_screen(Screen, Pos)
    ->
        Pos = coord(X,Y),
        DX #= X - ULX,
        DY #= Y - ULY,
        tty_goto(DX, DY),
        ansi_format(Args, Str, Fmt)
    ;
        true
    ).

draw_objects(Screen) :-
    pos(player, PC),
    draw_on_screen(Screen, PC, [fg(yellow)], '@', []),
    forall(type(Instance, _), (
        pos(Instance, MC),
        (visible(MC) ->
        draw_on_screen(Screen, MC, [fg(red)], 'M', [])
        ; true)
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
    draw_sidebar(Width),
    draw_objects(Screen),
    draw_messages.

% tty_size detects terminal screen size and updates
% should enforce both Width and Height are uneven
% (so player is neatly in the middle)
detect_screen_size(Width, Height) :-
    tty_size(Rows, Columns),
    % params for ui
    XOffset #= 30, % offset to the right
    YOffset #= 10, % offset on the bottom
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

get_command(C) :-
    get_single_char(X),
    char_code(C, X),
    handle_command(C).

handle_command('q').
handle_command('k') :-
    move_player(0, -1).
handle_command('h') :-
    move_player(-1, 0).
handle_command('j') :-
    move_player(0, 1).
handle_command('l') :-
    move_player(1, 0).
handle_command('1') :-
    cast_spell(1).
handle_command('2') :-
    cast_spell(2).
handle_command('3') :-
    cast_spell(3).
handle_command(X) :-
    not(memberchk(X, ['k','h','j','l','1','2','3','q'])),
    format('Unrecognized command ~w\n', [X]).

message_box(Message) :-
    detect_screen_size(Width, Height),

    % draw message box
    BoxsizeX #= Width - 20,
    length(Chars, BoxsizeX),
    maplist(=('#'), Chars),
    string_chars(TopBottom, Chars),
    tty_goto(10, 10),
    writeln(TopBottom),

    XMin2 #= BoxsizeX - 2,
    length(Chars2, XMin2),
    maplist(=(' '), Chars2),
    string_chars(Spaces, Chars2),
    string_concat(Spaces, "#", Temp),
    string_concat("#", Temp, Middle),

    BoxsizeY #= Height - 10,
    YMin1 #= BoxsizeY - 1,
    numlist(11, YMin1, Ys),
    forall(member(Y, Ys), (
        tty_goto(10, Y) ,
        writeln(Middle)
    )),
    tty_goto(10, BoxsizeY),
    writeln(TopBottom),

    tty_goto(12, 13),
    writeln(Message),

    % stay until user presses any key
    get_single_char(_).

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
