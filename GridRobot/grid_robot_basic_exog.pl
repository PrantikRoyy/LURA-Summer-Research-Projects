execute(A, SR) :- ask_execute(A, SR).

/* An unadded flag variable that can be added or removed during execution to make sure the exogenous action happens only once */
:- dynamic sent_new_package/0.

/* Defines an external event that executes "A new package p4 appears at coordinates (X,Y)." mid execution if:
- It is NOT true that sent_new_package exists
- received coordinates for the new package from the user
- checked if the coordinates are valid using coord/1
- use assert to add sent_new_package so this exogenous action doesn't happen again */
exog_occurs(newPackage(p4, X, Y)) :-
    \+ sent_new_package,
    write('Enter X coordinate for p4: '),
    read(X),
    write('Enter Y coordinate for p4: '),
    read(Y),
    coord(X),
    coord(Y),
    assert(sent_new_package).

/* defines the grid as a 10x10 */
grid_size(10).

/* Defines legal coordinate values of positions x & y of the grid as only being 0-10 */
coord(N) :- grid_size(M), between(0, M, N).

/* Defines p1-3 and the input player package p4 being valid packages as facts */
package(p1).
package(p2).
package(p3).
package(p4).

/* defines an exogenous action for defining p4 */
exog_action(newPackage(_, _, _)).

/* defines all 4 directions that a robot can go in the grid coordinate */
prim_action(goN).
prim_action(goS).
prim_action(goE).
prim_action(goW).

/* Robot can add a package P with coordinate (X, Y) if P is a valid package and X & Y are valid coordinates */
prim_action(newPackage(P, X, Y)) :- package(P), coord(X), coord(Y).

/* Robot can pick up and dropoff package P if P is a valid package */
prim_action(pickup(P)) :- package(P).
prim_action(dropoff(P)) :- package(P).

prim_fluent(picked(_)).

/* Defines the values of the robot's current coordinates. */
prim_fluent(xpos).
prim_fluent(ypos).

/* Defines the values of package P's current coordinates. */
prim_fluent(xpos_pkg(_)).
prim_fluent(ypos_pkg(_)).

/* defines a fluent that outputs true or false if the robot is carrying package p */
prim_fluent(carrying(_)).

/* defines the initial position of the robot in the grid in position (0, 0) */
initially(xpos, 0).
initially(ypos, 0).

/* defines the initial position of package p1 in the grid in position (2, 3) */
initially(xpos_pkg(p1), 2).
initially(ypos_pkg(p1), 3).

/* defines the initial position of package p2 in the grid in position (7, 1) */
initially(xpos_pkg(p2), 7).
initially(ypos_pkg(p2), 1).

/* defines the initial position of package p3 in the grid in position (5, 8) */
initially(xpos_pkg(p3), 5).
initially(ypos_pkg(p3), 8).

/* In the start the robot is not carrying or picked up any valid packages */
initially(carrying(P), false) :- package(P).
initially(picked(P), false) :- package(P).

/* defines the affect of inputting an X-coordinate for newPackage P which assigns it as P's new X-coordinate */
causes_val(newPackage(P, X, _), xpos_pkg(P), X, true).

/* defines the affect of inputting a Y-coordinate for newPackage P which assigns it as P's new Y-coordinate */
causes_val(newPackage(P, _, Y), ypos_pkg(P), Y, true).

/* defines the affect of not inputting X or Y-coordinates for newPackage P to ensure the new package becomes "not picked" */
causes_val(newPackage(P, _, _), picked(P), false, true).

/* defines the affect of moving the robot north by incrementing its y-position in the grid */
causes_val(goN, ypos, N, N is ypos + 1).

/* defines the affect of moving the robot south by decrementing its y-position in the grid */
causes_val(goS, ypos, N, N is ypos - 1).

/* defines the affect of moving the robot east by incrementing its x-position in the grid */
causes_val(goE, xpos, N, N is xpos + 1).

/* defines the affect of moving the robot west by decrementing its x-position in the grid */
causes_val(goW, xpos, N, N is xpos - 1).

/* defines the affect of the robot picking up package P which makes the fluent of carrying(P) = true */
causes_val(pickup(P), carrying(P), true, true).

/* defines the affect of the robot dropping off package P which makes the fluent of carrying(P) = false */
causes_val(dropoff(P), carrying(P), false, true).

causes_val(pickup(P), picked(P), true, true).

/* defines the precondition of moving north which is possible if the robot's y-position isn't 10 */
poss(goN, neg(ypos = M)) :- grid_size(M).

/* defines the precondition of moving south which is possible if the robot's y-position isn't 0 */
poss(goS, neg(ypos = 0)).

/* defines the precondition of moving east which is possible if the robot's x-position isn't 10 */
poss(goE, neg(xpos = M)) :- grid_size(M).

/* defines the precondition of moving west which is possible if the robot's x-position isn't 0 */
poss(goW, neg(xpos = 0)).

/* defines the precondition of picking up package P which is possible if the (X, Y) coordinate of the robot is the same as that of the package P */
poss(pickup(P), and(xpos = X, and(ypos = Y, and(xpos_pkg(P) = X, and(ypos_pkg(P) = Y, carrying(P) = false))))).

/* defines the precondition of dropping off package P which is possible if the robot is carrying package P and is back at its starting location */
poss(dropoff(P), and(carrying(P) = true, and(xpos = 0, ypos = 0))).

/* Builds a list of Distance-Package pairs for every package that has not yet been picked up.
   Each element of PackageInfoList is Pkg-PX-PY-Status where Status is true (picked) or false (not picked).
   Picked packages are skipped, unpicked packages have their Manhattan distance to robot coords: (RX, RY) computed. */
pairs_from_status([], _, _, []).
pairs_from_status([Pkg-PX-PY-false|Rest], RX, RY, [D-Pkg|Pairs]) :- D is abs(PX - RX) + abs(PY - RY), pairs_from_status(Rest, RX, RY, Pairs).
/*If a package is already picked skip it and go on to the next package*/
pairs_from_status([_-_-_-true|Rest], RX, RY, Pairs) :-pairs_from_status(Rest, RX, RY, Pairs).

/* Defines a procedure that tells the robot to go to coordinate position (X, Y) */
proc(go_to(X, Y),
[
    /* While the robot's current x-position != target X position, move horizontally east or west until it reaches the desired position */
    while(neg(xpos = X),
        /* get the robot's current X-coordinate as CX and move robot east if CX < target X-position and west otherwise */
        pi(CX, [?(xpos = CX), if(CX < X, goE, goW)])
    ),
    /* While the robot's current y-position != target Y position, move vertically north or south until it reaches the desired position */
    while(neg(ypos = Y),
        /* get the robot's current Y-coordinate as CY and move robot north if CY < target Y-position and south otherwise */
        pi(CY, [?(ypos = CY), if(CY < Y, goN, goS)])
    )
]).

/* Defines a procedure that gets the (X, Y) coordinate of package P
   and orders the robot to go to that location to pick up the package. */
proc(fetch_package(P),
[
    ?(xpos_pkg(P) = X),
    ?(ypos_pkg(P) = Y),
    go_to(X, Y),
    pickup(P)
]).

/* picks all unpicked packages using at most Max remaining moves including the return trip home, always fetching the 
   closest unpicked package first by computing their distances and sorting them with pairs_from_status. */
proc(handle_packages(Max),
    ndet(
        /* Base case: all packages have been picked up */
        [/* Check that every package has been picked */
         ?(and(picked(p1) = true, and(picked(p2) = true, and(picked(p3) = true, picked(p4) = true)))),
         /* Get the robot's current X-coordinate as HX */
         ?(xpos = HX),
         /* Get the robot's current Y-coordinate as HY */
         ?(ypos = HY),
         /* Compute the Manhattan distance R from the robot back to home (0,0) */
         ?(R is abs(HX) + abs(HY)),
         /* Only succeed if the remaining budget Max is enough to cover the return trip */
         ?(Max >= R),
         /* Return the robot home */
         go_to(0, 0)],

        /* Recursive case: there are still unpicked packages within budget pairs_from_status is used to find the closest
           unpicked package without needing multifile or global variables. */
        [/* Get the robot's current position */
         ?(xpos = RX), ?(ypos = RY),
         /* Get each package's current coordinates */
         ?(xpos_pkg(p1) = PX1), ?(ypos_pkg(p1) = PY1),
         ?(xpos_pkg(p2) = PX2), ?(ypos_pkg(p2) = PY2),
         ?(xpos_pkg(p3) = PX3), ?(ypos_pkg(p3) = PY3),
         ?(xpos_pkg(p4) = PX4), ?(ypos_pkg(p4) = PY4),
         /* Get each package's current picked status */
         ?(picked(p1) = S1), ?(picked(p2) = S2),
         ?(picked(p3) = S3), ?(picked(p4) = S4),
         /* Build Distance-Package pairs for unpicked packages, sorts them,
            and extract the first pair of the list which is the closest package P at distance D from the robot. */
         ?((pairs_from_status([p1-PX1-PY1-S1, p2-PX2-PY2-S2, p3-PX3-PY3-S3, p4-PX4-PY4-S4], RX, RY, Pairs), Pairs \= [],
             sort(Pairs, [D-P|_]))),
         /* Subtract the distance to P from the remaining budget */
         ?(M is Max - D),
         /* Only proceed if the remaining budget M is non-negative */
         ?(M >= 0),
         /* Navigate to P's location and pick it up */
         fetch_package(P),
         /* Recurse with the updated remaining budget M */
         handle_packages(M)]
    )
).

/* An iterative deepening search that tries to pick up all packages in Max moves,
   and if that's not possible, increments Max by 1 and tries again. */
proc(minimize_motion(Max),
    ndet(
        handle_packages(Max),
        pi(M, [?(M is Max + 1), minimize_motion(M)])
    )
).

/* Main robot controller procedure. */
proc(control(basic),
[
    /* Use iterative deepening search to find the shortest pickup order */
    search(minimize_motion(0)),

    /* Drop off all carried packages at home */
    while(neg(and(carrying(p1) = false, and(carrying(p2) = false, and(carrying(p3) = false, carrying(p4) = false)))),
        /* Non-deterministically choose a package that the robot is currently carrying and drop it off */
        ndet(
            [?(carrying(p1) = true), dropoff(p1)],
            ndet(
                [?(carrying(p2) = true), dropoff(p2)],
                ndet(
                    [?(carrying(p3) = true), dropoff(p3)],
                    [?(carrying(p4) = true), dropoff(p4)]
                )
            )
        )
    )
]).