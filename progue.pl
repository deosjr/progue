:- use_module(library(clpfd)).

:- ['ui.pl'].
:- ['dungeon.pl'].
:- ['path.pl'].

% object state
:- dynamic(player/1, minotaur/1, wall/1, tile/1).
% parameters 
:- dynamic(map_size/2).

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
        handle_minotaur,
        game_loop
    ).

handle_minotaur :-
    minotaur(Coord),
    player(PC),
    dijkstra(Coord, PC, [_,NewCoord|_]),
    retractall(minotaur(_)),
    assertz(minotaur(NewCoord)).

is_passable(Coord) :-
    tile(Coord).

move(Unit, X, Y) :-
    call(Unit, OldPos),
    move(OldPos, X, Y, NewPos),
    (
        is_passable(NewPos)
    ->
        Old =.. [Unit, _],
        retractall(Old),
        New =.. [Unit, NewPos],
        assertz(New)
    ;
        noop
    ).

% replacing this with some form of if-else without then
% slows everything down...
noop.

start_game :-
    assertz(map_size(70, 70)),
    generate_dungeon,
    initialize_ui,
    game_loop.

