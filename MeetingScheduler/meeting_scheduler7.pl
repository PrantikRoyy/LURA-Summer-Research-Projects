% Built-in system actions used internally by IndiGolog.
system_action(start_interrupts).
system_action(stop_interrupts).
% Identity calculation used by the interpreter when evaluating action arguments.
calc_arg(A,A,_H).
% No external domain-specific calculations are required, therefore all calls fail.
domain(_,_) :- fail.

% Meeting M exists.
prim_fluent(meeting(_)).
% Person P participates in meeting M.
prim_fluent(participant(_,_)).
% Participant P has responded to meeting M with email content EC.
prim_fluent(responded(_,_,_)).
% The communication agent (CA) has successfully extracted constraints from email EC.
prim_fluent(extractedConstraints(_,_,_,_)).
% Participant P prefers Slot for meeting M.
prim_fluent(preferred(_,_,_)).
% Participant P is available during Slot.
prim_fluent(available(_,_,_)).
% Participant P can attend during Slot only if necessary.
prim_fluent(ifNeedBe(_,_,_)).
% Person P is known to the meeting scheduler.
prim_fluent(knownParticipant(_)).

% no meetings exist
initially(meeting(_),              false).
% no participants have been registered
initially(participant(_,_),        false).
% no constraints have been collected
initially(responded(_,_,_),        false).
% no scheduling constraints have been collected
initially(extractedConstraints(_,_,_,_), false).
initially(preferred(_,_,_),        false).
initially(available(_,_,_),        false).
initially(ifNeedBe(_,_,_),         false).
% Alice, Bob, and Charlie are known participants.
initially(knownParticipant(alice), true).
initially(knownParticipant(bob), true).
initially(knownParticipant(charlie), true).

% All other participants are initially unknown.
initially(knownParticipant(_), false).

% Creating a meeting makes meeting(M) true.
causes_val(createMeeting(M), meeting(M), true, true).
% Adding participant P to meeting M makes participant(P,M) true.
causes_val(addParticipant(P,M), participant(P,M), true, true).
% Receiving an email response records the response content EC.
causes_val(responds(P,M,EC), responded(P,M,EC), true, true).
% Successful extraction records that constraints have been extracted from email EC.
causes_val(extractConstraints(CA,P,M,EC,_LA,_LP,_LI), extractedConstraints(CA,P,M,EC), true, true).
% Every time slot T in the availability list LA becomes an available slot.
causes_val(extractConstraints(_CA,P,M,_EC,LA,_LP,_LI), available(P,T,M), true, member(T,LA)).
% Records Monday morning as a preferred meeting time.
causes_val(extractConstraints(_CA,P,M,_EC,_LA,[monday_morning],_LI), preferred(P,monday_morning,M), true, true).
% Records Tuesday afternoon as a preferred meeting time.
causes_val(extractConstraints(_CA,P,M,_EC,_LA,[tuesday_afternoon],_LI), preferred(P,tuesday_afternoon,M), true, true).
% Every time slot T in the if-need-be list LI becomes conditionally available.
causes_val(extractConstraints(_CA,P,M,_EC,_LA,_LP,LI), ifNeedBe(P,T,M), true, member(T,LI)).

% Primitive action that creates a new meeting in the system.
prim_action(createMeeting(_)).
% Primitive action that registers a participant for a meeting.
prim_action(addParticipant(_,_)).
% Primitive action that sends an invitation email to a participant.
prim_action(sendInvitationEmail(_,_,_)).
% Primitive action that retrieves or displays a participant's response.
prim_action(queryConstraints(_,_,_,_)).
% Primitive action that assigns constraint collection to a delegated agent.
prim_action(acquireDelegatedConstraints(_,_,_)).
% Primitive action used to inject an exogenous event into the event queue.
prim_action(injectExog(_)).
% Primitive action that reports all collected scheduling preferences.
prim_action(reportPreferredSlotsAction(_)).

% Exogenous action representing a participant submitting a response.
exog_action(responds(_,_,_)).
% Exogenous action representing LLM extraction of scheduling constraints.
exog_action(extractConstraints(_,_,_,_,_,_,_)).

% A meeting can always be created.
poss(createMeeting(_), true).
% A participant can only be added if the meeting already exists.
poss(addParticipant(_,M), meeting(M)).
% An invitation email can only be sent to a registered participant.
poss(sendInvitationEmail(_CA,P,M), participant(P,M)).
% Constraints can only be queried from a registered participant.
poss(queryConstraints(_CA,P,M,_EC), participant(P,M)).
% Delegated constraint collection is only possible for a registered participant.
poss(acquireDelegatedConstraints(_CA,P,M), participant(P,M)).
% Exogenous events can always be injected into the event queue.
poss(injectExog(_), true).
% Preference reporting can always be executed.
poss(reportPreferredSlotsAction(_), true).

% Executes the createMeeting action by displaying that a meeting was created.
execute(createMeeting(M),_) :-
    format("Meeting created: ~w~n",[M]).

% Executes the addParticipant action by displaying that a participant was added.
execute(addParticipant(P,M),_) :-
    format("Participant ~w added to ~w~n",[P,M]).

% Executes the sendInvitationEmail action by displaying that an invitation email was sent.
execute(sendInvitationEmail(CA,P,M),_) :-
    format("~w sending invitation email to ~w for ~w~n",[CA,P,M]).

% Executes the queryConstraints action by displaying the participant's email response.
execute(queryConstraints(_CA,P,_M,EC),_) :-
    format("~nEmail response received from ~w:~n",[P]),
    format("  \"~w\"~n",[EC]).

% Executes the acquireDelegatedConstraints action by logging that the CA
% has taken responsibility for collecting constraints from participant P in meeting M.
execute(acquireDelegatedConstraints(CA,P,M),_) :-
    format("~w acquired delegated task for ~w in ~w~n",[CA,P,M]).

% Executes the injectExog action by inserting an exogenous event into the event queue.
execute(injectExog(Event),_) :-
    exog_queue_add(Event).

% Executes the reporting action by displaying all extracted scheduling preferences,
% availability constraints, and if-needed availability for meeting M.
execute(reportPreferredSlotsAction(M),H) :-
    nl, write('=== Preferred slots collected ==='), nl,
    (has_val(preferred(alice,monday_morning,M),   true,H) -> format("  alice prefers ~w~n",[monday_morning])    ; true),
    (has_val(preferred(bob,tuesday_afternoon,M),  true,H) -> format("  bob prefers ~w~n",[tuesday_afternoon])   ; true),
    nl, write('=== Available slots ==='), nl,
    (has_val(available(alice,monday,M),           true,H) -> format("  alice available ~w~n",[monday])          ; true),
    (has_val(available(alice,tuesday,M),          true,H) -> format("  alice available ~w~n",[tuesday])         ; true),
    (has_val(available(bob,tuesday_afternoon,M),  true,H) -> format("  bob available ~w~n",[tuesday_afternoon]) ; true),
    nl, write('=== If-Need-Be slots ==='), nl,
    (has_val(ifNeedBe(charlie,wednesday,M),       true,H) -> format("  charlie available if needed ~w~n",[wednesday]) ; true).

% Declares exog_queue/1 as a dynamic predicate so events can
% be added and removed during execution.
:- dynamic exog_queue/1.

% Adds an exogenous event to the queue.
exog_queue_add(Event) :- assertz(exog_queue(Event)).

% Removes the next exogenous event from the queue and makes
% it available to the IndiGolog interpreter.
exog_occurs(Event) :- retract(exog_queue(Event)), !.

% Simulates Alice submitting her availability response.
proc(simulateResponse(alice,meeting1),
    injectExog(responds(alice,meeting1,
        "Available Monday/Tuesday. Prefer Monday morning."))).

% Simulates Bob submitting his availability response.
proc(simulateResponse(bob,meeting1),
    injectExog(responds(bob,meeting1,
        "Tuesday afternoon works best."))).

% Simulates Charlie submitting his availability response.
proc(simulateResponse(charlie,meeting1),
    injectExog(responds(charlie,meeting1,
        "Only Wednesday if needed."))).

% Simulates an LLM extracting structured scheduling constraints
% from a participant's natural-language response.
proc(runLLMExtraction(CA,P,M,EC),
    ndet(
        [?(EC="Available Monday/Tuesday. Prefer Monday morning."),
         injectExog(extractConstraints(CA,P,M,EC,[monday,tuesday],[monday_morning],[]))],
    ndet(
        [?(EC="Tuesday afternoon works best."),
         injectExog(extractConstraints(CA,P,M,EC,[tuesday_afternoon],[tuesday_afternoon],[]))],
        [?(EC="Only Wednesday if needed."),
         injectExog(extractConstraints(CA,P,M,EC,[],[],[wednesday]))]
    ))).

% Initializes the meeting by creating the meeting and registering all participants.
proc(initializeMeeting,
% Begin the sequence of initialization actions.
[
    % Create the meeting named meeting1.
    createMeeting(meeting1),
    % Repeat while there exists a participant who has not yet been added.
    while(
        % Check if there is some participant P satisfying the following conditions.
        some(P,
            % Both conditions below must hold.
            and([% P is a known participant.
                knownParticipant(P),
                % P has not yet been registered for meeting1.
                neg(participant(P,meeting1))
            ])),
        % Select one qualifying participant P.
        pi(P,
            % Perform the following actions for the selected participant.
            [% Verify that P is still a known participant who has not been added.
            ?(and([knownParticipant(P),
              % Ensure P has not already been registered.
              neg(participant(P,meeting1))])),
            % Register participant P for meeting1.
            addParticipant(P,meeting1),
            % Assign the communication agent (CA) to collect P's scheduling constraints.
            acquireDelegatedConstraints(ca,P,meeting1)]
        )
    )
]).

% Organizes a meeting by collecting constraints then identifying meeting time.
proc(meetingOrganized(SA,M),
    [constraintsCollected(SA,M),
     meetingTimeIdentified(SA,M)]).

% Tries email strategy first; Doodle always fails so email wins.
proc(constraintsCollected(SA,M),
    ndet(constraintsCollectedByEmail(SA,M),
         constraintsCollectedByDoodle(SA,M))).

% Collects scheduling constraints from all participants via email.
proc(constraintsCollectedByEmail(_SA,M),
    % Continue until every participant has submitted extracted constraints.
    while(
        % Find a participant P that still has no extracted constraints.
        some(P,
            % Both conditions below must hold.
            and([% P must be a known participant.
                knownParticipant(P),
                % No extracted constraints currently exist for participant P.
                neg(some(EC,
                        % Check whether constraints have already been extracted.
                        extractedConstraints(ca,P,M,EC)
                    )
                )
            ])
        ),
        % Select one participant satisfying the above conditions.
        pi(P,
            % Execute the following actions.
            [% Verify that P still requires constraint collection.
                ?(
                    and([
                        knownParticipant(P),
                        % Ensure extracted constraints are still absent.
                        neg(
                            some(
                                EC,
                                extractedConstraints(ca,P,M,EC)
                            )
                        )
                    ])
                 ),
                % Send the invitation, receive the response,
                % and process the participant's scheduling constraints.
                individualConstraintsCollectedByEmail(ca,P,M)]
        )
    )
).

% Placeholder for a Doodle-based collection method. Currently disabled.
proc(constraintsCollectedByDoodle(_SA,_M), ?(false)).

% Collects constraints from a single participant using email:
% send invitation then receive and process their response.
proc(individualConstraintsCollectedByEmail(CA,P,M),
    [sendInvitationEmail(CA,P,M),
     receiveAndProcessResponse(CA,P,M)]).

% Receives a participant response, displays it, runs the
% simulated LLM extraction, and verifies extraction success.
proc(receiveAndProcessResponse(CA,P,M),
    [simulateResponse(P,M),
     pi(EC,
        [?(responded(P,M,EC)),
         queryConstraints(CA,P,M,EC),
         runLLMExtraction(CA,P,M,EC),
         ?(extractedConstraints(CA,P,M,EC))])]).

% Determines the meeting time after all constraints have been collected.
proc(meetingTimeIdentified(_SA,M), reportPreferredSlots(M)).

% Reports all preferred, available, and fallback time slots.
proc(reportPreferredSlots(M), reportPreferredSlotsAction(M)).

% Main program: initialize the meeting then organize it.
proc(main,
    [initializeMeeting,
     meetingOrganized(sa,meeting1)]).

run_demo :-
    retractall(exog_queue(_)),
    nl,
    write('IndiGolog Meeting Scheduler'), nl,
    write('================================================='), nl, nl,
    once(indigolog(main)).