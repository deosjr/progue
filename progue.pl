:- use_module(library(clpfd)).

:- ['ui.pl'].
:- ['dungeon.pl'].
:- ['path.pl'].

% object state
:- dynamic(player/1, wall/1, tile/1).
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
        game_loop
    ).

is_passable(Coord) :-
    tile(Coord).

move(X, Y) :-
    player(OldPos),
    move(OldPos, X, Y, NewPos),
    (
        is_passable(NewPos)
    ->
        retractall(player(_)),
        assertz(player(NewPos))
    ;
        noop
    ).

% the noop is used in if-then-else when we need an if-then
% with some side-effects. imperative prolog...
noop.

start_game :-
    assertz(map_size(70, 70)),
    generate_dungeon,
    initialize_ui,
    game_loop.

