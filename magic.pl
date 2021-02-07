:- dynamic(winds_of_magic/1).
:- dynamic(spell_in_slot/3).

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

cast_spell(Slot) :-
    ( spell_in_slot(player, Spell, Slot)
    ->
        manapool(player, CurrentMP),
        spell(Spell, Manacost),
        ( Manacost #=< CurrentMP
        ->
            add_message(blue, "player casts ~w!", [Spell]),
            NewMP #= CurrentMP - Manacost,
            update_state(manapool, player, NewMP),
            cast_spell(player, Spell)
        ;
            add_message(blue, "not enough mana", [])
        )
    ;
        add_message(blue, "invalid spellslot", [])
    ).

% name, manacost
spell(heal, 7).

cast_spell(player, heal) :-
    health(player, CurrentHP),
    NewHP #= min(100, CurrentHP + 5),
    update_state(health, player, NewHP).
