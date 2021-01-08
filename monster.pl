% object state
:- dynamic([pos/2, health/2, manapool/2, type/2]).
:- dynamic(instance_counter/1).

% basically reinventing pointers. Im sorry.
instance_counter(0).
new_instance(X) :-
    instance_counter(X),
    Y #= X+1,
    retractall(instance_counter(_)),
    assertz(instance_counter(Y)).

name(player, player).
name(Instance, Name) :-
    type(Instance, Name).

handle_monster(Instance) :-
    (
        manapool(Instance, X),
        X #>= 7
    ->
        monster_casts_spell(Instance)
    ;
        monster_moves_closer(Instance)
    ),
    attack_if_adjacent(Instance, player).

monster_casts_spell(Instance) :-
    manapool(Instance, Mana),
    NewMana #= Mana - 7,
    update_state(manapool, Instance, NewMana),
    name(Instance, Type),
    add_message(red, "The ~w casts a spell!", [Type]).

monster_moves_closer(Instance) :-
    pos(Instance, Coord),
    pos(player, PC),
    dijkstra(Coord, PC, Path),
    (
        Path = "NoPathFound"
    ->
        true
    ;
        Path = [_,NewCoord|_],
        move_absolute(Instance, NewCoord)
    ).

% TODO should only be used by monsters
% player attacks by walking into monsters
% monsters get a move+attack combo
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
        name(Attacker, NA), name(Defender, ND),
        add_message(white, "~w hits ~w!", [NA, ND]),
        (
            NewHP #= 0
        ->
            add_message(red, "~w dies!", [ND]),
            (
                Defender \= player
            ->
                remove_monster(Defender)
            ;
                fail
            )
        ;
            true
        )
    ;
        true
    ).

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
        true
    ).

add_monster(Type, Pos) :-
    new_instance(X),
    assertz(type(X, Type)),
    assertz(health(X, 20)),
    assertz(pos(X, Pos)).

remove_monster(Instance) :-
    retractall(type(Instance, _)),
    retractall(health(Instance, _)),
    retractall(pos(Instance, _)).
