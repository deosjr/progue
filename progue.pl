:- use_module(library(clpfd)).

:- ['ui.pl'].
:- ['monster.pl'].
:- ['dungeon.pl'].
:- ['path.pl'].
:- ['magic.pl'].

% parameters 
:- dynamic(map_size/2).

game_loop :-
    update_winds_of_magic,
    update_visible,
    draw_screen,
    get_command(C),
    (
        C = 'q' % q quits the game
    ->
        message_box("Thanks for playing")
    ;
        forall(type(Instance,_), (
            handle_monster(Instance)
        )),
        game_loop
    ).

is_passable(Coord) :-
    tile(Coord),
    not(pos(_, Coord)).

update_state(State, Unit, Value) :-
    Old =.. [State, Unit, _],
    retractall(Old),
    New =.. [State, Unit, Value],
    assertz(New).

add_player(Pos) :-
    assertz(health(player, 100)),
    assertz(spell_in_slot(player, heal, 1)),
    assertz(pos(player, Pos)).

start_game :-
    assertz(map_size(70, 70)),
    assertz(messages([])),
    add_message(white, "Welcome to the lair of the Minotaur Wizard", []),
    generate_dungeon,
    initialize_magic,
    game_loop.
