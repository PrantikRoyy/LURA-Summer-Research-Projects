:- dir(indigolog_plain, F), consult(F).

:- [grid_robot7].

main :-
    reset_packages,
    retractall(sent_new_packages),
    findall(C, proc(control(C), _), L),
    repeat,
    format('Controllers available: ~w\n', [L]),
    write('Select controller: '),
    read(S), nl,
    member(S, L),
    format('Executing controller: *~w*\n', [S]), !,
    indigolog(control(S)).

main(C) :-
    reset_packages,
    retractall(sent_new_packages),
    indigolog(control(C)).