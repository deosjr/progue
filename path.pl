% very ugly first working version
dijkstra(From, To, Path) :-
    From = coord(_,_),
    To = coord(_,_),
    Start = 0-From,
    dijkstra(To, [Start], [Start], Path).

% goal, fringe, explored
dijkstra(Goal, [Current|ToExplore], Explored, Path) :-
    Current = Dis-Coord,
    neighbours(Coord, Neighbours),
    include([C]>>(
        tile(C), 
        not(memberchk(_-C, Explored))
    ), Neighbours, Unvisited),
    %format('~w ~w ~w\n', [Current, Explored, Unvisited]),
    (
        Unvisited = []
    ->
        dijkstra(Goal, ToExplore, Explored, Path)
    ;
        (
            memberchk(Goal, Unvisited)
        ->
            reconstruct_path(Dis, [Goal], Explored, Path)
        ;
            NewDis #= Dis + 1,
            bagof(NewDis-C, member(C, Unvisited), NewlyExplored),
            append(NewlyExplored, Explored, NextExplored),
            append(NewlyExplored, ToExplore, NextToExplore),
            keysort(NextToExplore, Sorted),
            dijkstra(Goal, Sorted, NextExplored, Path)
        )
    ).

reconstruct_path(N, PathSoFar, Nodes, Path) :-
    PathSoFar = [Last|_],
    neighbours(Last, Neighbours),
    member(Neighbour, Neighbours),
    memberchk(N-Neighbour, Nodes),
    NewPath = [Neighbour|PathSoFar],
    (
        N #> 0
    ->
        NN #= N - 1,
        reconstruct_path(NN, NewPath, Nodes, Path) 
    ;
        N #= 0,
        Path = NewPath
    ).

neighbours(Coord, Neighbours) :-
    move(Coord, 0, -1 , Up),
    move(Coord, 1, 0 , Right),
    move(Coord, 0, 1 , Down),
    move(Coord, -1, 0 , Left),
    Neighbours = [Up, Right, Down, Left].

:- begin_tests(dijkstra).

/*
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
    */

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
