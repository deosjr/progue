:- dynamic([wall/1, tile/1, visible/1, seen/1]).

% TODO: cool stuff like divide-and-conquer delaunay etc

generate_dungeon :-
    % generate starting room
    generate_room(coord(35,35), 4, 10, 4, 10, StartingRoom),
    assert_room(StartingRoom),
    rectangle_midpoint(StartingRoom, PlayerPos),
    add_player(PlayerPos),
    % generate 10 more rooms
    generate_connected_rooms(10, [StartingRoom], Rooms),
    % take the last one and place the minotaur there
    Rooms = [MinotaurRoom, SecondRoom|_],
    rectangle_midpoint(MinotaurRoom, MinotaurPos),
    add_monster(minotaur, MinotaurPos),
    rectangle_midpoint(SecondRoom, SecondPos),
    add_monster(minotaur, SecondPos),
    % this is an assertion: if true we would have screwed up in dungeon gen
    not((tile(Coord), wall(Coord))).

% cannot backtrack over random so we have to generate and test
generate_connected_rooms(0, X, X).
generate_connected_rooms(N, Rooms, TotalRooms) :-
    N #> 0,
    RoomMaxX #= 10,
    RoomMaxY #= 10,
    map_size(MapX, MapY),
    MaxX #= MapX - RoomMaxX,
    MaxY #= MapY - RoomMaxY,
    random_between(0, MaxX, X),
    random_between(0, MaxY, Y),
    generate_room(coord(X,Y), 4, RoomMaxX, 4, RoomMaxY, NewRoom),
    (
        forall(member(Room,Rooms), not(rectangles_overlap(Room, NewRoom)))
    ->
        assert_room(NewRoom),
        Rooms = [LastRoom|_],
        assert_corridor(LastRoom, NewRoom),
        NN #= N - 1,
        generate_connected_rooms(NN, [NewRoom|Rooms], TotalRooms)
    ;
        generate_connected_rooms(N, Rooms, TotalRooms)
    ).

% generate a room with upperleft corner X-Y and random width/height
% Room is a rectangle with upperleft and lowerright corners defined
generate_room(ULHC, WidthMin, WidthMax, HeightMin, HeightMax, Room) :-
    random_between(WidthMin, WidthMax, W),
    random_between(HeightMin, HeightMax, H),
    DX #= W - 1,
    DY #= H - 1,
    coord_from_to(ULHC, DX, DY, LRHC),
    Room = rectangle(ULHC, LRHC).

assert_room(rectangle(ULHC, LRHC)) :-
    ULHC = coord(ULX, ULY),
    LRHC = coord(LRX, LRY),
    % paint the walls, one step outside the room bounds
    coord_from_to(ULHC, -1, -1, WULHC),
    coord_from_to(LRHC, 1, 1, WLRHC),
    WULHC = coord(WULX, WULY),
    WLRHC = coord(WLRX, WLRY),
    range(WULX, WLRX, WXRange),
    forall(member(X,WXRange), assert_wall_unless_tile(coord(X, WULY))),
    forall(member(X,WXRange), assert_wall_unless_tile(coord(X, WLRY))),
    range(WULY, WLRY, WYRange),
    forall(member(Y,WYRange), assert_wall_unless_tile(coord(WULX, Y))),
    forall(member(Y,WYRange), assert_wall_unless_tile(coord(WLRX, Y))),
    % now paint all the tiles in between
    range(ULX, LRX, XRange),
    range(ULY, LRY, YRange),
    forall(member(X,XRange), (forall(member(Y,YRange), assert_tile(coord(X,Y))))).

assert_corridor(Room1, Room2) :-
    rectangle_midpoint(Room1, coord(M1X, M1Y)),
    rectangle_midpoint(Room2, coord(M2X, M2Y)),
    MinX #= min(M1X, M2X),
    MaxX #= max(M1X, M2X),
    MinY #= min(M1Y, M2Y),
    MaxY #= max(M1Y, M2Y),
    assert_horizontal_corridor(MinX, MaxX, M1Y),
    assert_vertical_corridor(MinY, MaxY, M2X).

assert_horizontal_corridor(Min, Max, Y) :-
    range(Min, Max, XRange),
    forall(member(X,XRange), assert_tile(coord(X, Y))),
    forall(member(X,XRange), (
        UY #= Y-1, 
        LY #= Y+1, 
        assert_wall_unless_tile(coord(X, UY)), 
        assert_wall_unless_tile(coord(X, LY)))
    ).

assert_vertical_corridor(Min, Max, X) :-
    range(Min, Max, YRange),
    forall(member(Y,YRange), assert_tile(coord(X, Y))),
    forall(member(Y,YRange), (
        LX #= X-1, 
        RX #= X+1, 
        assert_wall_unless_tile(coord(LX, Y)), 
        assert_wall_unless_tile(coord(RX, Y)))
    ).

% will remove wall if present
assert_tile(Coord) :-
    retractall(wall(Coord)),
    assertz(tile(Coord)).

% will remove tile if present
assert_wall(Coord) :-
    retractall(tile(Coord)),
    assertz(wall(Coord)).

% will not remove tile if present
assert_wall_unless_tile(Coord) :-
    (
        tile(Coord)
    -> 
        true
    ;
        assertz(wall(Coord))
    ).

range(Min, Max, Range) :-
    numlist(Min, Max, Range).

rectangle(coord(ULX, ULY), coord(LRX, LRY)) :-
    ULX #< LRX,
    ULY #< LRY.

% integer midpoint, rounding to upper left hand corner
rectangle_midpoint(rectangle(coord(ULX,ULY), coord(LRX,LRY)), Mid) :-
    Width #= LRX - ULX,
    Height #= LRY - ULY,
    MidX #= ULX + (Width // 2),
    MidY #= ULY + (Height // 2),
    Mid = coord(MidX, MidY).

rectangles_overlap(rectangle(ULHC1, LRHC1), rectangle(ULHC2, LRHC2)) :-
    ULHC1 = coord(ULX1, ULY1),
    LRHC1 = coord(LRX1, LRY1),
    ULHC2 = coord(ULX2, ULY2),
    LRHC2 = coord(LRX2, LRY2),
    ULX1 #=< LRX2,
    ULX2 #=< LRX1,
    ULY1 #=< LRY2,
    ULY2 #=< LRY1.

% coordinate system with X to the right, Y pointing down
coord_from_to(coord(CX,CY), X, Y, coord(NX,NY)) :-
    NX #= CX + X,
    NY #= CY + Y.

% floodfill is simplest, but FoV should be some ray- or shadowcasting algo
update_visible :-
    foreach(visible(C), (
        (seen(C) -> true ; assertz(seen(C)))
    )),
    retractall(visible(_)),
    pos(player, Pos),
    floodfill(10, [Pos], Visible),
    foreach(member(V, Visible),
        assertz(visible(V))
    ).

floodfill(0, X, X).
floodfill(N, Old, New) :-
    N #> 0,
    NN #= N-1,
    exclude(wall, Old, Floors),
    maplist(neighbours, Floors, Neighbours),
    flatten(Neighbours, Flat),
    list_to_set(Flat, Set),
    union(Old, Set, Newer),
    floodfill(NN, Newer, New).
