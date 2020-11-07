:- use_module(library(clpfd)).

:- ['ui.pl'].
:- ['monster.pl'].
:- ['dungeon.pl'].
:- ['path.pl'].
:- ['magic.pl'].

% parameters 
:- dynamic(map_size/2).

%% TODO game lags randomly on input, sometimes very slow to respond
game_loop :-
    update_winds_of_magic,
    draw_screen,
    get_single_char(X),
    char_code(C, X),
    (
        C = 'q' % q quits the game
    ->
        writeln("Thanks for playing")
    ;
        handle_command(C),
        forall(type(Instance,_), (
            %% TODO player now attacks everyone in range...
            attack_if_adjacent(player, Instance)
        )),
        %% TODO crash if monster died?
        forall(type(Instance,_), (
            handle_monster(Instance)
        )),
        game_loop
    ).

is_passable(Coord) :-
    tile(Coord),
    not(pos(_, Coord)).

% replacing this with some form of if-else without then
% slows everything down...
noop.

update_state(State, Unit, Value) :-
    Old =.. [State, Unit, _],
    retractall(Old),
    New =.. [State, Unit, Value],
    assertz(New).

add_player(Pos) :-
    assertz(health(player, 10)),
    assertz(pos(player, Pos)).

start_game :-
    assertz(map_size(70, 70)),
    assertz(messages([])),
    add_message(white, "Welcome to the lair of the Minotaur Wizard", []),
    generate_dungeon,
    initialize_magic,
    initialize_ui,
    game_loop.
