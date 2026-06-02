execute(A, SR) :- ask_execute(A, SR).
exog_occurs(_) :- fail.

/* defines the grid as a 10x10 */
grid_size(10).

/* Defines legal coordinate values of positions x & y of the grid as only being 1-10 */
coord(N) :- grid_size(M), between(0, M, N).

/* Defines p1-3 being valid packages as facts*/
package(p1).
package(p2).
package(p3).


/* defines all 4 direcions that a robot can go in the grid coordinate */
prim_action(goN).
prim_action(goS).
prim_action(goE).
prim_action(goW).

/* Robot can pick up and dropoff package P if P is a valid package*/
prim_action(pickup(P)) :- package(P).
prim_action(dropoff(P)) :- package(P).

prim_fluent(picked(_)).

/*Defines the values of the robot's current coordinates.*/
prim_fluent(xpos).
prim_fluent(ypos).

/*Defines the values of package P's current coordinates.*/
prim_fluent(xpos_pkg(_P)).
prim_fluent(ypos_pkg(_P)).

/* defines a fluent that outputs true or flase if the robot is carraying package p */
prim_fluent(carrying(_P)).

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

/* In the start the robot is not carrying any valid packages */
initially(carrying(P), false) :- package(P).

initially(picked(P), false) :- package(P).

/* defines the affect moving the robot north by incrementing its y-position in the grid*/
causes_val(goN, ypos, N, N is ypos + 1).

/* defines the affect moving the robot south by decrementing its y-position in the grid*/
causes_val(goS, ypos, N, N is ypos - 1).

/* defines the affect moving the robot east by incrementing its x-position in the grid*/
causes_val(goE, xpos, N, N is xpos + 1).

/* defines the affect moving the robot west by decrementing its x-position in the grid*/
causes_val(goW, xpos, N, N is xpos - 1).

/* defines the affect of the robot picking up of a package P which makes the fluet of carrying(P) = true*/
causes_val(pickup(P), carrying(P), true, true).

/* defines the affect of the robot dropping off of a package P which makes the fluet of carrying(P) = false*/
causes_val(dropoff(P), carrying(P), false, true).

causes_val(pickup(P), picked(P), true, true).

/* defines the precondition of moving north which is possible if the robot's y-position isn't 10*/
poss(goN, neg(ypos = M)) :- grid_size(M).

/* defines the precondition of moving south which is possible if the robot's y-position isn't 0*/
poss(goS, neg(ypos = 0)).

/* defines the precondition of moving east which is possible if the robot's x-position isn't 10*/
poss(goE, neg(xpos = M)) :- grid_size(M).

/* defines the precondition of moving west which is possible if the robot's x-position isn't 0*/
poss(goW, neg(xpos = 0)).

/* defines the precondition of picking up package P which is possible if the (X, Y) coordinate of the robot is the same as that of the package P*/
poss(pickup(P), and(xpos = X, and(ypos = Y, and(xpos_pkg(P) = X, and(ypos_pkg(P) = Y, carrying(P) = false))))).

/* defines the precondition of dropping off up package P which is possible if the robot is carraying package P and its back at it's starting location*/
poss(dropoff(P), and(carrying(P) = true, and(xpos = 0, ypos = 0))).

domain(P, package) :- package(P).

/* Define a helper condition that determines if a robot is in positions (X, Y) */
proc(at(X, Y), and(xpos = X, ypos = Y)).

/* Defines a procedure that tells the robot to go coordinate position (X, Y)*/
proc(go_to(X, Y),
[
   /* While the robot's current x-position != target X position, move horizontally east or west until it reaches the desried position*/
   while(neg(xpos = X),
      /* get the robots current X-coordinate as CX and move robot east if CX < target X-position and west otherwise*/
      pi(CX, [?(xpos = CX), if(CX < X, goE, goW)])
   ),
   /* While the robot's current y-position != target Y position, move vertically north or south until it reaches the desried position*/
   while(neg(ypos = Y),
      /* get the robots current Y-coordinate as CY and move robot north if CY < target Y-position and south otherwise*/
      pi(CY, [?(ypos = CY), if(CY < Y, goN, goS)])
   )
]).

/* Defines a procedure that gets the (X, Y) coordinate of package P 
   and orders to robot to go to that location to pick up the package. */
proc(fetch_package(P),
[
   ?(xpos_pkg(P) = X),
   ?(ypos_pkg(P) = Y),
   go_to(X, Y),
   pickup(P)
]).

/* Main robot controller procedure. */
proc(control(basic),
[
   /* Continue fetching packages until all packages p1, p2, p3, and p4 have been picked up. */
   while(neg(and(picked(p1) = true, and(picked(p2) = true, picked(p3) = true))),
      ndet(
         [?(picked(p1) = false), fetch_package(p1)],
         ndet(
            [?(picked(p2) = false), fetch_package(p2)],
            [?(picked(p3) = false), fetch_package(p3)]
         )
      )
   ),
   /* After collecting all packages, robot returns to original position (0,0) to dropoff its contents. */
   go_to(0, 0),
   /*Continue dropping off packages until the robot no longer carries any packages*/
   while(neg(and(carrying(p1) = false, and(carrying(p2) = false, carrying(p3) = false))),
      /* Non-deterministically choose a package that the robot is currently carrying and drop it off */
      ndet(
         [?(carrying(p1) = true), dropoff(p1)],
         ndet(
            [?(carrying(p2) = true), dropoff(p2)],
            [?(carrying(p3) = true), dropoff(p3)]
         )
      )
   )
]).