
:- dynamic(explored/1, from/2).

dijkstra(From, To, Path) :-
    From = coord(_,_),
    To = coord(_,_),
    Start = 0-From,
    assertz(explored(From)),
    % VERY much not Prolog style but I need this to be FAST
    % so I can do cool Prolog things somewhere else :)
    (
        dijkstra([Start], To)
    ->
        reconstruct_path(From, [To], Path)
    ;
        Path = "NoPathFound"
    ),
    % have to do this to not pollute mem with asserted stuff
    % even if dijkstra/1 fails
    retractall(explored(_)),
    retractall(from(_,_)).

% goal, fringe, explored
dijkstra(ToExplore, Goal) :-
    min_member(Current, ToExplore),
    selectchk(Current, ToExplore, RestToExplore),
    Current = Dis-Coord,
    neighbours(Coord, Neighbours),
    include([C]>>(
        tile(C), 
        not(explored(C))
    ), Neighbours, Unvisited),
    (
        Unvisited = []
    ->
        dijkstra(RestToExplore, Goal)
    ;
        (
            memberchk(Goal, Unvisited)
        ->
            assertz(from(Coord, Goal))
        ;
            forall(member(C, Unvisited), (
                assertz(from(Coord, C)),
                assertz(explored(C))
            )),
            NewDis #= Dis + 1,
            bagof(NewDis-C, member(C, Unvisited), NewlyExplored),
            append(NewlyExplored, RestToExplore, NextToExplore),
            dijkstra(NextToExplore, Goal)
        )
    ).

reconstruct_path(From, PathSoFar, Path) :-
    PathSoFar = [Last|_],
    from(Prev, Last),
    NewPathSoFar = [Prev|PathSoFar],
    (
        Prev = From,
        Path = NewPathSoFar
    ;
        Prev \= From,
        reconstruct_path(From, NewPathSoFar, Path)
    ).

neighbours(Coord, Neighbours) :-
    coord_from_to(Coord, 0, -1 , Up),
    coord_from_to(Coord, 1, 0 , Right),
    coord_from_to(Coord, 0, 1 , Down),
    coord_from_to(Coord, -1, 0 , Left),
    Neighbours = [Up, Right, Down, Left].

:- begin_tests(dijkstra).

test(no_path) :-
    retractall(tile(_)),
    Tiles = [0-0,1-0,0-1,1-1],
    forall(member(X-Y, Tiles), (
        assert_tile(coord(X,Y))
    )),
    dijkstra(coord(0,0), coord(4,2), Path),
    assertion(Path = "NoPathFound"),
    retractall(tile(_)).

test(short_path) :-
    retractall(tile(_)),
    Tiles = [0-0,1-0,0-1,1-1],
    forall(member(X-Y, Tiles), (
        assert_tile(coord(X,Y))
    )),
    dijkstra(coord(0,0), coord(1,1), Path),
    length(Path, N),
    assertion(N = 3),
    retractall(tile(_)).

test(longer_path) :-
    retractall(tile(_)),
    Tiles = [0-0,1-0,0-1,1-1,0-2,1-2,2-2,2-0,2-1],
    forall(member(X-Y, Tiles), (
        assert_tile(coord(X,Y))
    )),
    dijkstra(coord(0,0), coord(2,2), Path),
    length(Path, N),
    assertion(N = 5),
    retractall(tile(_)).

:- end_tests(dijkstra).
