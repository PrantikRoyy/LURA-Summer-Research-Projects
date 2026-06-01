/* Interface to the outside world via read and write */
execute(A, SR) :- ask_execute(A, SR).

/* Declare sent_new_packages as dynamic so it can be used during runtime
   to flag packages that have been sent to users */
:- dynamic sent_new_packages/0.

/* Declare dynamic_package as dynamic to use to add new packages during runtime */
:- dynamic dynamic_package/1.

/* Declare initially as dynamic so to label newly added packages with the initial status */
:- dynamic initially/2.

/* Resets all dynamically added packages and their states from the previous run so the program can be
   run again cleanly with a fresh set of packages */
reset_packages :-
    /* Remove all dynamically added packages */
    retractall(dynamic_package(_)),
    /* Remove all dynamically added initially facts for package positions */
    retractall(initially(xpos_pkg(_), _)),
    retractall(initially(ypos_pkg(_), _)),
    /* Remove the sent_new_packages flag so exog_occurs can fire again */
    retractall(sent_new_packages),
    /* Re-insert the three original packages */
    assertz(dynamic_package(p1)),
    assertz(dynamic_package(p2)),
    assertz(dynamic_package(p3)),
    /* Re-insert original package positions */
    assertz(initially(xpos_pkg(p1), 2)),
    assertz(initially(ypos_pkg(p1), 3)),
    assertz(initially(xpos_pkg(p2), 7)),
    assertz(initially(ypos_pkg(p2), 1)),
    assertz(initially(xpos_pkg(p3), 5)),
    assertz(initially(ypos_pkg(p3), 8)).

:- reset_packages.

/* prompts the user to enter new packages mid-execution if:
   - It isn't true that sent_new_packages exists
   - Asserts sent_new_packages so this action can't fire again
   - Calls read_new_packages to collect newly inputted package from the user */
exog_occurs(newPackages) :-
    \+ sent_new_packages,
    assert(sent_new_packages),
    read_new_packages.

read_new_packages :-
    /* Prompts the user for the package name */
    write('Enter new package name (or done to stop): '),
    read(Name),
    /* If the name given is 'done' end the recursive loop by outputting true*/
    (Name = done -> true;
        /* Else, prompts the user for the X and Y coordinates*/
        write('Enter X coordinate for '), write(Name), write(': '),
        read(X),
        write('Enter Y coordinate for '), write(Name), write(': '),
        read(Y),
        /* If the coordinates are valid via coord, set the inputted package's name, initial coordinates, carrying status,
           and picked status mid-execution using assertz*/
        (coord(X), coord(Y) ->
            assertz(dynamic_package(Name)),
            assertz(initially(xpos_pkg(Name), X)),
            assertz(initially(ypos_pkg(Name), Y)),
            assertz(initially(carrying(Name), false)),
            assertz(initially(picked(Name), false));
            /* If coordinates are invalid, prompt for them again */
            write('Invalid coordinates, try again.'), nl),
        /* Recursively repeat read_new_packages to get the next package */
        read_new_packages).

/* defines the grid as a 10x10 */
grid_size(10).

/* Defines legal coordinate values of positions x & y of the grid as only being 0-10 */
coord(N) :- grid_size(M), between(0, M, N).

package(P) :- dynamic_package(P).

exog_action(newPackages).

/* defines all 4 directions that a robot can go in the grid coordinate */
prim_action(goN).
prim_action(goS).
prim_action(goE).
prim_action(goW).

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
initially(carrying(P), false) :- dynamic_package(P).
initially(picked(P), false) :- dynamic_package(P).

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
/* If a package is already picked skip it and go on to the next package */
pairs_from_status([_-_-_-true|Rest], RX, RY, Pairs) :- pairs_from_status(Rest, RX, RY, Pairs).

/* Given a list of packages, for each package P get their (x, y) coords and picked status as variables
   to build a PackageInfoList of P-PX-PY-S terms for pairs_from_status. */
build_status_tests([], [], []).
build_status_tests(
    [P|Rest],
    [?(xpos_pkg(P) = PX),
      ?(ypos_pkg(P) = PY),
      ?(picked(P) = S)
      | RestTests],
    [P-PX-PY-S | RestInfo]
    ) :- build_status_tests(Rest, RestTests, RestInfo).

/* Recursively checks if all the packages in a list of packages have been picked. */
build_all_picked_cond([P], picked(P) = true).
build_all_picked_cond([P|Rest], and(picked(P) = true, RestCond)) :- build_all_picked_cond(Rest, RestCond).

/* Recursively checks if all the packages in a list of packages are not being carried currently. */
build_carrying_cond([P], carrying(P) = false).
build_carrying_cond([P|Rest], and(carrying(P) = false, RestCond)) :- build_carrying_cond(Rest, RestCond).

/* A nondeterministic program that recursively dropsoff all the packages that are currently being carried
   in a list of packages. */
build_dropoff_ndet([P], [?(carrying(P) = true), dropoff(P)]).
build_dropoff_ndet([P|Rest], ndet([?(carrying(P) = true), dropoff(P)], RestProg)) :- build_dropoff_ndet(Rest, RestProg).

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
[?(xpos_pkg(P) = X),
 ?(ypos_pkg(P) = Y),
  go_to(X, Y),
  pickup(P)]).

/* Finds the closest unpicked package from a list of packages */
proc(fetch_closest_package(Pkgs), Prog) :-
    /* Get each packages x-position, y-position, and picked status and
       use it to build a InfoList containing terms of the form: Package-X-Y-Status */
    build_status_tests(Pkgs, StatusTests, InfoList),

    /* Concatenate two lists of steps and procedures executed to form a dynamic program represented by the list Prog.*/
    append(
        /* Append the robots X and Y coordinates into the StatusTests list generated above */
        [?(xpos = RX), ?(ypos = RY) | StatusTests],

        /* Build a list of Distance-Package pairs using the robot's position and package info using pairs_from_status.*/
        [?((pairs_from_status(InfoList, RX, RY, Pairs),
        /* Ensures at least one candidate package exists*/
        Pairs \= [],
        /* Sort the resulting distance-package pairs by distance and get the first pairs which represent the
           package with the smallest distance to the robot */
        sort(Pairs, [_D-P|_]))),
        /* fetch the closest package selected above. */
        fetch_package(P)], Prog
    ).

/* Main controller, built dynamically from current packages in dynamic_package */
proc(control(basic), Prog) :-
    /* Collect all known package names into Pkgs */
    findall(P, dynamic_package(P), Pkgs),
    /* makes an exit condition for the fetch loop when all packages are picked */
    build_all_picked_cond(Pkgs, AllPickedCond),
    /* makes an exit condition for the dropoff loop when robot is carrying nothing */
    build_carrying_cond(Pkgs, CarryingCond),
    /* makes an ndet program to drop off whatever packages are currently being carried */
    build_dropoff_ndet(Pkgs, DropoffNdet),
    /* Make a dynamically built program in the form of a list of steps and procedures that the program runs called Prog */
    Prog = [
        /* Fetch closest unpicked package until all are picked */
        while(neg(AllPickedCond), fetch_closest_package(Pkgs)),
        /* Return home */
        go_to(0, 0),
        /* Drop off all the currently carried packages at the end */
        while(neg(CarryingCond), DropoffNdet)
    ].