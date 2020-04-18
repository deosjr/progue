:- use_module(library(clpfd)).

:- dynamic(player/2, wall/2).

% Y to draw, last Y to draw, start X, end X, player coords
draw(Y,Y,_,_,_).
draw(Y, EndY, StartX, EndX, PX-PY) :-
    Y #< EndY,
    drawline(StartX, EndX, Y, PX-PY),
    write('\n'),
    NY #= Y + 1,
    draw(NY, EndY, StartX, EndX, PX-PY).

% X to draw, last X to draw, current line Y, player coords
drawline(X,X,_,_).
drawline(X, EndX, Y, PX-PY) :-
    X #< EndX,
    (
        X #= PX, Y #= PY
    ->
        write('@')
    ;
        (
            wall(X,Y)
        ->
            write('#')
        ;
            write('.')
        )
    ),
    NX #= X + 1,
    drawline(NX, EndX, Y, PX-PY).

draw_screen :-
    tty_clear,
    tty_goto(0, 0),
    player(PX, PY),
    %tty_size(ScreenRows, ScreenColumns),
    ScreenRows #= 30,
    ScreenColumns #= 30,
    start_end_window(ScreenColumns, PX, StartX, EndX),
    start_end_window(ScreenRows, PY, StartY, EndY),
    draw(StartY, EndY, StartX, EndX, PX-PY).

start_end_window(Total, PCoord, Start, End) :-
    Half #= Total // 2,
    (
        is_even(Total),
        Start #= PCoord - Half + 1,
        End #= PCoord + Half - 1
    ;
        not(is_even(Total)),
        Start #= PCoord - Half,
        End #= PCoord + Half
    ).

game_loop :-
    draw_screen,
    get_single_char(X),
    char_code(C, X),
    (
        C = 'q' % q quits the game
    ->
        writeln("Thanks for playing")
    ;
        handle_command(C),
        game_loop
    ).

handle_command('k') :-
    move(0, -1).
handle_command('h') :-
    move(-1, 0).
handle_command('j') :-
    move(0, 1).
handle_command('l') :-
    move(1, 0).
handle_command(X) :-
    not(memberchk(X, ['k','h','j','l','q'])),
    format('Unrecognized command ~c\n', [X]).

is_passable(X, Y) :-
    not(wall(X,Y)).

move(X, Y) :-
    player(PX, PY),
    NPX #= PX + X,
    NPY #= PY + Y,
    (
        is_passable(NPX, NPY)
    ->
        retractall(player(_,_)),
        assertz(player(NPX, NPY))
    ;
        noop
    ).

noop.

start_game :-
    assertz(player(0, 0)),
    assertz(wall(-5, 5)),
    game_loop.

is_even(X) :-
    X mod 2 #= 0.
