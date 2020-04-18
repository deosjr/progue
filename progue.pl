:- use_module(library(clpfd)).

:- ['ui.pl'].
:- ['dungeon.pl'].

:- dynamic(player/1, wall/1).

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

is_passable(Coord) :-
    not(wall(Coord)).

move(X, Y) :-
    player(coord(PX, PY)),
    NPX #= PX + X,
    NPY #= PY + Y,
    NewPos = coord(NPX, NPY),
    (
        is_passable(NewPos)
    ->
        retractall(player(_)),
        assertz(player(NewPos))
    ;
        noop
    ).

noop.

start_game :-
    generate_room(coord(0,0), 4, 10, 4, 10, Room),
    assert_room(Room),
    rectangle_midpoint(Room, Mid),
    assertz(player(Mid)),
    game_loop.

