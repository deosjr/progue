:- use_module(library(clpfd)).

:- ['ui.pl'].
:- ['dungeon.pl'].
:- ['path.pl'].
:- ['magic.pl'].

% object state
:- dynamic(player/1, minotaur/1, wall/1, tile/1).
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
        handle_minotaur,
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
    retractall(manapool(minotaur, _)),
    NewMana #= Mana - 7,
    assertz(manapool(minotaur, NewMana)),
    add_message(red, "The minotaur casts a spell!", []).

minotaur_moves_closer :-
    minotaur(Coord),
    player(PC),
    coord_from_to(PC, X, Y, Coord),
    (
        abs(X) + abs(Y) #=< 2,
        Message = "The minotaur catches up with you!",
        messages([_-LastMessage-_|_]),
        LastMessage \= Message
    ->
        add_message(red, Message, [])
    ;
        noop
    ),
    dijkstra(Coord, PC, [_,NewCoord|_]),
    move_absolute(minotaur, NewCoord).

is_passable(Coord) :-
    tile(Coord),
    not(player(Coord)),
    not(minotaur(Coord)).

move_relative(Unit, X, Y) :-
    call(Unit, OldPos),
    coord_from_to(OldPos, X, Y, NewPos),
    move_absolute(Unit, NewPos).

move_absolute(Unit, Pos) :-
    Pos = coord(_,_),
    (
        is_passable(Pos)
    ->
        Old =.. [Unit, _],
        retractall(Old),
        New =.. [Unit, Pos],
        assertz(New)
    ;
        noop
    ).

% replacing this with some form of if-else without then
% slows everything down...
noop.

start_game :-
    assertz(map_size(70, 70)),
    assertz(messages([])),
    add_message(white, "Welcome to the lair of the Minotaur Wizard", []),
    generate_dungeon,
    initialize_magic,
    initialize_ui,
    game_loop.
