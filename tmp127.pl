:- module(tmp127,[history_ask/1,hask/1,reset/0]).

:- use_module(library(http/http_client)).
:- use_module(library(http/http_json)).

:- dynamic context/1.
:- dynamic texterr/1.

hask(Q):- history_ask(Q).

history_ask(QuestionAtom):-
    Question= json([ role=user, content=QuestionAtom ]),

    ask(Question,Answer,'gpt-4o'),
    ground(Answer),
    history_question_answer(Question,Answer).

reset:-
    retractall(context(_)).

ask(Question,PreText,Model):-
    read_messages_json(JsonM),
    append( JsonM,[Question],List),

    Json=json([ model=Model,
                temperature= 0.5,
                top_p= 0.5,
                messages=List]),

    http_post(
        'https://api.openai.com/v1/chat/completions',
        json(Json),
        Answer,
        [
            authorization(bearer('use_here_your_own_openai_bearer')),
            status_code(_)
        ]),

    once(text_from_rawanswer(PreText,Answer)),

    json(List2)=PreText,
    memberchk(content=Text,List2),

    writeln(Text).

history_question_answer(Question,Answer):-
    asserta(context(Question)),
    asserta(context(Answer)).

read_messages_json(List):-
    findall(B,context(B),ListA),
    reverse(ListA,List).

text_from_rawanswer(D,json(R)):-
    (  member(error=json(A),R), asserta(texterr(R)),forall(member(M,A),writeln(M))
    ;
    tokencount_from_json(R,Count),
    write(Count),tab(2),
    member(choices=B,R),member(json(C),B),member(message=D,C)).

tokencount_from_json(R,Count):-
    memberchk(usage=json(Q),R),memberchk(total_tokens=Count,Q).













