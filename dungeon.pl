use_module(library(random)).

% generate a room with upperleft corner X-Y
% and random width / height
% Room is a rectangle with upperleft and bottomright corners defined
generate_room(coord(X,Y), WidthMin, WidthMax, HeightMin, HeightMax, Room) :-
    random_between(WidthMin, WidthMax, W),
    BRX #= X + W ,
    random_between(HeightMin, HeightMax, H),
    BRY #= Y + H,
    Room = rectangle(coord(X,Y), coord(BRX, BRY)).

assert_room(rectangle(coord(ULX,ULY), coord(BRX,BRY))) :-
    range(ULX, BRX, XRange),
    forall(member(X,XRange), assertz(wall(coord(X, ULY)))),
    forall(member(X,XRange), assertz(wall(coord(X, BRY)))),
    range(ULY, BRY, YRange),
    forall(member(Y,YRange), assertz(wall(coord(ULX, Y)))),
    forall(member(Y,YRange), assertz(wall(coord(BRX, Y)))).

range(Min, Max, Range) :-
    findall(X, between(Min, Max, X), Range).

% TODO: this is a crude approximation
rectangle_midpoint(rectangle(coord(ULX,ULY), coord(BRX,BRY)), Mid) :-
    Width #= BRX - ULX,
    Height #= BRY - ULY,
    MidX #= ULX + (Width // 2),
    MidY #= ULY + (Height // 2),
    Mid = coord(MidX, MidY).
