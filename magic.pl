:- dynamic(winds_of_magic/1).

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
        update_state(manapool, player, NewManaPool),
        forall(type(Instance, _), 
            update_state(manapool, Instance, NewManaPool)
        )
    ;
        NewTimer #= ResetTimer - 1
    ),
    assertz(winds_of_magic(NewTimer)).
