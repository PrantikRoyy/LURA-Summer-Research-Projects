/* system_action is called by transfinal-congolog.pl for built-in actions */
system_action(start_interrupts).
system_action(stop_interrupts).

/* calc_arg(+A,-A1,+H): evaluates fluent-valued args in action A against
   history H. Our actions have no fluent-valued args so this is identity. */
calc_arg(A, A, _H).

/* domain(+W,+D): enumerates values from a typed domain.
   We only use untyped pi(V,Body) so this always fails. */
domain(_, _) :- fail.

/* declares meeting1 a valid meeting*/
meeting(meeting1).

/* declares alice, bob, and charlie as valid participants of meeting1*/
potentialParticipant(alice,   meeting1).
potentialParticipant(bob,     meeting1).
potentialParticipant(charlie, meeting1).

/* Participant P has responded to meeting M with email content */
prim_fluent(responded(P,M,EC)).
/* Communication agent has successfully extracted the constraints from participant P's email content about meeting M */
prim_fluent(extractedConstraints(CA,P,M,EC)).
/* Participant P preferres time slot T for meeting M */
prim_fluent(preferred(P,T,M)).
/* Participant P is avaliable for meeting M time at slot T */
prim_fluent(available(P,T,M)).
/* Participant P can attent meeting M at time slot T if nesscary */
prim_fluent(ifNeedBe(P,T,M)).

/* Initilize all the values to false as the initial state of the scheduler */
initially(responded(_,_,_),              false).
initially(extractedConstraints(_,_,_,_), false).
initially(preferred(_,_,_),              false).
initially(available(_,_,_),              false).
initially(ifNeedBe(_,_,_),              false).

/* When participant P sends a email about meeting M, the fact that P responded becomes true unconditionally */
causes_val(responds(P,M,EC), responded(P,M,EC), true, true).

/* When constraints from P's email about meeting M are extracted, the fact that extraction happened becomes true unconditionally */
causes_val(extractConstraints(_CA,P,M,EC,_LA,_LP,_LI), extractedConstraints(ca,P,M,EC), true, true).

/* When constraints form P in meeting M are extracted, P's avaliable time at the specified time slot in the avability list becomes true*/
causes_val(extractConstraints(_CA,P,M,_EC,LA,_LP,_LI), available(P,T,M), true, member(T,LA)).

/* When constraints form P in meeting M are extracted, P's preferred time at the specified time slot in the preference list becomes true*/
causes_val(extractConstraints(_CA,P,M,_EC,_LA,LP,_LI), preferred(P,T,M), true, member(T,LP)).

/* When constraints form P in meeting M are extracted, P's needed time at the specified time slot in the ifNeedBe list becomes true*/
causes_val(extractConstraints(_CA,P,M,_EC,_LA,_LP,LI), ifNeedBe(P,T,M), true, member(T,LI)).

/* Define primitive actions */
prim_action(sendInvitationEmail(_,_,_)).
prim_action(queryConstraints(_,_,_,_)).
prim_action(acquireDelegatedConstraints(_,_,_)).
prim_action(injectExog(_)).

/* Defines exogenous actions*/
exog_action(responds(_,_,_)).
exog_action(extractConstraints(_,_,_,_,_,_,_)).

/* Communication agent can send an email to P to invite them to meeting M if P is actually a valid participant of meeting M*/
poss(sendInvitationEmail(_CA,P,M), potentialParticipant(P,M)).

/* Communication agent is allowed to query constraints from person P about meeting M, if P is a valid participant of meeting M.*/
poss(queryConstraints(_CA,P,M,_EC), potentialParticipant(P,M)).

/* Communication agent acquires the constraints of participant P if and only if P is a valid participant of meeting M*/
poss(acquireDelegatedConstraints(_CA,P,M), potentialParticipant(P,M)).

/* Action injectExog can always be executed unconditionally*/
poss(injectExog(_), true).

/* When CA sends an invitation to P for M, print a message */
execute(sendInvitationEmail(CA,P,M), _) :-
    format("~w sending invitation email to ~w for ~w~n",[CA,P,M]).

/* The communication agent processes the email content's of P's response for meeting M by:
   1. Running fakeLLMExtract to parse EC into structured constraint lists
   2. Queuing an extractConstraints exogenous event to update the fluents
   3. Printing the email content and extracted results */
execute(queryConstraints(CA,P,M,EC), _) :-
    fakeLLMExtract(EC, Avail, Pref, IfNeed),
    exog_queue_add(extractConstraints(CA,P,M,EC,Avail,Pref,IfNeed)),
    format("~nEmail response received from ~w:~n",[P]),
    format("  \"~w\"~n",[EC]),
    format("LLM extraction result:~n",[]),
    format("  Available  : ~w~n",[Avail]),
    format("  Preferred  : ~w~n",[Pref]),
    format("  If-Need-Be : ~w~n~n",[IfNeed]).

/* Informs the user that Communication agent CA has acquired responsibility for collecting scheduling
   constraints of participant P in meeting M from the scheduling agent. */
execute(acquireDelegatedConstraints(CA,P,M), _) :- format("~w acquired delegated task for ~w in ~w~n",[CA,P,M]).

/* This action fires exogenous event E */
execute(injectExog(Event), _) :- exog_queue_add(Event).

:- dynamic exog_queue/1.

/* Queues an exogenous event at the end of the database via assertz */
exog_queue_add(Event) :- assertz(exog_queue(Event)).

/* Called by indigo between steps to drain the event queue */
exog_occurs(Event) :- retract(exog_queue(Event)), !.

/* Alice's email response to meeting1 */
simulateParticipantResponse(alice, meeting1, "Available Monday/Tuesday. Prefer Monday morning.").
/* Bob's email response to meeting1 */
simulateParticipantResponse(bob, meeting1, "Tuesday afternoon works best.").
/* Charlie's email response to meeting1 */
simulateParticipantResponse(charlie, meeting1, "Only Wednesday if needed.").

/* If email says: "Available Monday/Tuesday. Prefer Monday morning."
   Then extract: Available=[monday,tuesday] | Preferred=[monday_morning] | IfNeeded=[] */
fakeLLMExtract("Available Monday/Tuesday. Prefer Monday morning.", [monday,tuesday],[monday_morning],[]).

/* If email says: "Tuesday afternoon works best."
   Then extract: Available=[tuesday_afternoon] | Preferred=[tuesday_afternoon] | IfNeeded=[] */
fakeLLMExtract("Tuesday afternoon works best.", [tuesday_afternoon],[tuesday_afternoon],[]).

/* If email says: "Only Wednesday if needed."
   Then extract: Available=[] | Preferred=[] | IfNeeded=[wednesday] */
fakeLLMExtract("Only Wednesday if needed.", [],[],[wednesday]).

/* Defines the basic logical connectives */
holds(neg(P), H)     :- !, \+ holds(P, H).
holds(and(P1,P2), H) :- !, holds(P1, H), holds(P2, H).
holds(or(P1,_), H)   :- holds(P1, H).
holds(or(_,P2), H)   :- holds(P2, H).
holds(some(V,P), H)  :- !, copy_term(V-P, V2-P2), subv(V2,_,P2,P3), holds(P3, H).
holds(true, _H)      :- !.
holds(false, _H)     :- !, fail.

/* potentialParticipant holds at any history if it's a static domain fact */
holds(potentialParticipant(P,M), _H) :- potentialParticipant(P,M).

/* simulateParticipantResponse holds at any history if it's in the hardcoded response table*/
holds(simulateParticipantResponse(P,M,EC), _H) :- simulateParticipantResponse(P,M,EC).

/* member holds at any history if X is an element of list L */
holds(member(X,L), _H) :- member(X,L).

/* Tells whether there's an unprocessed participant for meeting M in history H
   whose constraints have not yet been extracted */
holds(someUnprocessed(M), H) :- potentialParticipant(P,M), \+ has_val(extractedConstraints(ca,P,M,_), true, H).

/* Records that participant P has responded to meeting M in history H */
holds(someResponded(P,M), H) :- has_val(responded(P,M,_), true, H).

/* Records in history H that participant P responded to meeting M with the specific email content */
holds(responded(P,M,EC), H) :- has_val(responded(P,M,EC), true, H).

/* Records in history H that communication agent CA has extracted constraints for participant P in meeting M */
holds(someExtracted(CA,P,M), H) :- has_val(extractedConstraints(CA,P,M,_), true, H).

/* Collect all preferred slots from the history and print them out by:
   1. Using findall to go through every participant and each of their possible time slots T in
      meeting M from history H to get all P-T pairs where preferred(P,T,M) is true, stored in list L
   2. Print all participant-preferred time slot pairs from L and if L is empty write "none",
      otherwise loop through with forall printing each preference */
holds(collectAndPrint(M,L), H) :- 
    findall(P-T, (potentialParticipant(P,M), has_val(preferred(P,T,M), true, H)), L),
    nl,
    write('=== Preferred slots collected ==='), nl,
    (L = [] ->  write('(none)'), nl; forall(member(P-T, L), format("  ~w prefers ~w~n",[P,T]))).

/* The scheduling agent organises a meeting by first collecting everyone's constraints and then identifying a meeting time. */
proc(meetingOrganized(SA,M), [constraintsCollected(SA,M), meetingTimeIdentified(SA,M) ]).

/* The scheduling agent collects constraints either by email or by Doodle poll */
proc(constraintsCollected(SA,M), ndet(constraintsCollectedByEmail(SA,M), constraintsCollectedByDoodle(SA,M))).

/* Scheduling agent processes participants one at a time until every participant's constraints have been extracted. */
proc(constraintsCollectedByEmail(_SA,M),
    while(
        someUnprocessed(M),
        pi(P, [ ?(and(potentialParticipant(P,M),
        neg(someExtracted(ca,P,M)))), individualConstraintsCollectedByEmail(ca,P,M) ]))).

/* Doodle strategy for collecting constraints is blocked since we're only getting emails */
proc(constraintsCollectedByDoodle(_SA,_M), ?(false)).

/* To collect constraints from a participant by email: send them an invitation and wait for and process
   the email content of their response. */
proc(individualConstraintsCollectedByEmail(CA,P,M), [sendInvitationEmail(CA,P,M), receiveAndProcessResponse(CA,P,M) ]).

/* The communication agent receives and processes a response from participant P by:
   1. Simulating an email response arriving
   2. Verifying it's in the history
   3. Extracting the email content with constraints, then verifying that the extraction succeeded */
proc(receiveAndProcessResponse(CA,P,M),
    [simulateResponse(P,M), ?(someResponded(P,M)), pi(EC, [?(responded(P,M,EC)), queryConstraints(CA,P,M,EC), ?(someExtracted(CA,P,M)) ]) ]).

/* Simulates a response from participant P about meeting M by picking email content,
   verifying it exists in the response table, then firing it as an exogenous event */
proc(simulateResponse(P,M), pi(EC, [?(simulateParticipantResponse(P,M,EC)), injectExog(responds(P,M,EC)) ])).

/* Identifies a meeting time for M by reporting the preferred slots */
proc(meetingTimeIdentified(_SA,M), reportPreferredSlots(M)).

/* Reports preferred slots for meeting M by picking a list and verifying that collecting and printing it succeeds */
proc(reportPreferredSlots(M), pi(L, [?(collectAndPrint(M,L))])).

run_demo :-
    retractall(exog_queue(_)),
    nl,
    write('IndiGolog Meeting Scheduler'), nl,
    write('================================================='), nl, nl,
    indigolog(meetingOrganized(sa,meeting1)).