
:- dynamic(winds_of_magic/1).

% TODO: consolidate state (its all over the place for now)
:- dynamic(manapool/2).

initialize_magic :-
    assertz(winds_of_magic(0)).

% winds of magic reset the shared mana pool at random intervals
update_winds_of_magic :-
    winds_of_magic(ResetTimer),
    retractall(winds_of_magic(_)),
    (
        ResetTimer = 0
    ->
        random_between(0, 10, NewTimer),
        random_between(0, 10, NewManaPool),
        retractall(manapool(_,_)),
        assertz(manapool(player, NewManaPool)),
        assertz(manapool(minotaur, NewManaPool))
    ;
        NewTimer #= ResetTimer - 1
    ),
    assertz(winds_of_magic(NewTimer)).
