:- use_module(library(clpfd)).

:- ['ui.pl'].
:- ['dungeon.pl'].
:- ['path.pl'].
:- ['magic.pl'].

% object state
:- dynamic(pos/2, health/2, manapool/2).
% parameters 
:- dynamic(map_size/2).

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
        attack_if_adjacent(player, minotaur),
        handle_minotaur,
        attack_if_adjacent(minotaur, player),
        game_loop
    ).

% start of monster logic. I will build it out from here
handle_minotaur :-
    (
        manapool(minotaur, X),
        X #>= 7
    ->
        minotaur_casts_spell
    ;
        minotaur_moves_closer
    ).

minotaur_casts_spell :-
    manapool(minotaur, Mana),
    NewMana #= Mana - 7,
    update_state(manapool, minotaur, NewMana),
    add_message(red, "The minotaur casts a spell!", []).

minotaur_moves_closer :-
    pos(minotaur, Coord),
    pos(player, PC),
    dijkstra(Coord, PC, [_,NewCoord|_]),
    move_absolute(minotaur, NewCoord).

attack_if_adjacent(Attacker, Defender) :-
    pos(Attacker, APos),
    pos(Defender, DPos),
    (
        coord_from_to(APos, X, Y, DPos),
        abs(X) + abs(Y) #= 1
    ->
        health(Defender, HP),
        NewHP #= HP - 1,
        update_state(health, Defender, NewHP),
        add_message(white, "~w hits ~w!", [Attacker, Defender]),
        (
            NewHP #= 0
        ->
            add_message(red, "~w dies!", [Defender])
        ;
            noop
        )
    ;
        noop
    ).

is_passable(Coord) :-
    tile(Coord),
    not(pos(player, Coord)),
    not(pos(minotaur, Coord)).

move_relative(Unit, X, Y) :-
    pos(Unit, OldPos),
    coord_from_to(OldPos, X, Y, NewPos),
    move_absolute(Unit, NewPos).

move_absolute(Unit, Pos) :-
    Pos = coord(_,_),
    (
        is_passable(Pos)
    ->
        update_state(pos, Unit, Pos)
    ;
        noop
    ).

% replacing this with some form of if-else without then
% slows everything down...
noop.

update_state(State, Unit, Value) :-
    Old =.. [State, Unit, _],
    retractall(Old),
    New =.. [State, Unit, Value],
    assertz(New).

start_game :-
    assertz(map_size(70, 70)),
    assertz(messages([])),
    assertz(health(player, 10)),
    assertz(health(minotaur, 20)),
    add_message(white, "Welcome to the lair of the Minotaur Wizard", []),
    generate_dungeon,
    initialize_magic,
    initialize_ui,
    game_loop.
