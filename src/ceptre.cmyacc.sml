
functor ParseFn
   (structure Streamable : STREAMABLE
    structure Arg :
       sig
          type string
          type int
          type top
          type tops
          type syn
          type syns
          type ign

          val Ign : unit -> ign
          val Num : int -> syn
          val Pred : unit -> syn
          val Wild : unit -> syn
          val Id : string -> syn
          val One : unit -> syn
          val Braces : syn -> syn
          val parens : syn -> syn
          val Cons : syn * syns -> syns
          val Nil : unit -> syns
          val app : syn * syns -> syn
          val StagePred : string -> syn
          val Dollar : syn -> syn
          val Bang : syn -> syn
          val Differ : syn * syn -> syn
          val Unify : syn * syn -> syn
          val Comma : syn * syn -> syn
          val Star : syn * syn -> syn
          val Arrow : syn * syn -> syn
          val LolliOne : syn -> syn
          val Lolli : syn * syn -> syn
          val ArrowL : syn * syn -> syn
          val LolliL : syn * syn -> syn
          val Ascribe : syn * syn -> syn
          val ConsT : top * tops -> tops
          val NilT : unit -> tops
          val Special : string * syns -> top
          val Context : string * syn -> top
          val Stage : string * tops -> top
          val Decl : syn -> top

          datatype terminal =
             PRED
           | STAGE
           | CONTEXT
           | IDENT of string
           | NUM of int
           | HASHDENT of string
           | LBRACE
           | RBRACE
           | LPAREN
           | RPAREN
           | PERIOD
           | COLON
           | COMMA
           | EQUALS
           | USCORE
           | DOLLAR
           | BANG
           | STAR
           | LARROW
           | RARROW
           | LLOLLI
           | RLOLLI
           | UNIFY
           | DIFFER

          val error : terminal Streamable.t -> exn
       end)
   :>
   sig
      val parse : Arg.terminal Streamable.t -> Arg.tops * Arg.terminal Streamable.t
   end
=

(*

AUTOMATON LISTING
=================

State 0:

start -> . Tops  / 0
0 : Top -> . Syn PERIOD  / 1
1 : Top -> . STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 1
2 : Top -> . CONTEXT IDENT OpEquals LBRACE Syn RBRACE OpPeriod  / 1
3 : Top -> . HASHDENT Atomics PERIOD  / 1
4 : Tops -> .  / 0
5 : Tops -> . Top Tops  / 0
6 : Syn -> . Syn COLON Syn  / 2
7 : Syn -> . Syn LLOLLI Syn  / 2
8 : Syn -> . Syn LARROW Syn  / 2
9 : Syn -> . Syn RLOLLI Syn  / 2
10 : Syn -> . Syn RLOLLI  / 2
11 : Syn -> . Syn RARROW Syn  / 2
12 : Syn -> . Syn STAR Syn  / 2
13 : Syn -> . Syn COMMA Syn  / 2
14 : Syn -> . Syn UNIFY Syn  / 2
15 : Syn -> . Syn DIFFER Syn  / 2
16 : Syn -> . BANG Syn  / 2
17 : Syn -> . DOLLAR Syn  / 2
18 : Syn -> . STAGE IDENT  / 2
19 : Syn -> . Atomic Atomics  / 2
22 : Atomic -> . LPAREN Syn RPAREN  / 3
23 : Atomic -> . LBRACE Syn RBRACE  / 3
24 : Atomic -> . LPAREN RPAREN  / 3
25 : Atomic -> . IDENT  / 3
26 : Atomic -> . USCORE  / 3
27 : Atomic -> . PRED  / 3
28 : Atomic -> . NUM  / 3

$ => reduce 4
PRED => shift 2
STAGE => shift 3
CONTEXT => shift 5
IDENT => shift 4
NUM => shift 1
HASHDENT => shift 6
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Tops => goto 13
Top => goto 14
Syn => goto 12
Atomic => goto 15

-----

State 1:

28 : Atomic -> NUM .  / 4

PRED => reduce 28
IDENT => reduce 28
NUM => reduce 28
LBRACE => reduce 28
RBRACE => reduce 28
LPAREN => reduce 28
RPAREN => reduce 28
PERIOD => reduce 28
COLON => reduce 28
COMMA => reduce 28
USCORE => reduce 28
STAR => reduce 28
LARROW => reduce 28
RARROW => reduce 28
LLOLLI => reduce 28
RLOLLI => reduce 28
UNIFY => reduce 28
DIFFER => reduce 28

-----

State 2:

27 : Atomic -> PRED .  / 4

PRED => reduce 27
IDENT => reduce 27
NUM => reduce 27
LBRACE => reduce 27
RBRACE => reduce 27
LPAREN => reduce 27
RPAREN => reduce 27
PERIOD => reduce 27
COLON => reduce 27
COMMA => reduce 27
USCORE => reduce 27
STAR => reduce 27
LARROW => reduce 27
RARROW => reduce 27
LLOLLI => reduce 27
RLOLLI => reduce 27
UNIFY => reduce 27
DIFFER => reduce 27

-----

State 3:

1 : Top -> STAGE . IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 5
18 : Syn -> STAGE . IDENT  / 2

IDENT => shift 16

-----

State 4:

25 : Atomic -> IDENT .  / 4

PRED => reduce 25
IDENT => reduce 25
NUM => reduce 25
LBRACE => reduce 25
RBRACE => reduce 25
LPAREN => reduce 25
RPAREN => reduce 25
PERIOD => reduce 25
COLON => reduce 25
COMMA => reduce 25
USCORE => reduce 25
STAR => reduce 25
LARROW => reduce 25
RARROW => reduce 25
LLOLLI => reduce 25
RLOLLI => reduce 25
UNIFY => reduce 25
DIFFER => reduce 25

-----

State 5:

2 : Top -> CONTEXT . IDENT OpEquals LBRACE Syn RBRACE OpPeriod  / 5

IDENT => shift 17

-----

State 6:

3 : Top -> HASHDENT . Atomics PERIOD  / 5
20 : Atomics -> .  / 6
21 : Atomics -> . Atomic Atomics  / 6
22 : Atomic -> . LPAREN Syn RPAREN  / 7
23 : Atomic -> . LBRACE Syn RBRACE  / 7
24 : Atomic -> . LPAREN RPAREN  / 7
25 : Atomic -> . IDENT  / 7
26 : Atomic -> . USCORE  / 7
27 : Atomic -> . PRED  / 7
28 : Atomic -> . NUM  / 7

PRED => shift 2
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
PERIOD => reduce 20
USCORE => shift 7
Atomics => goto 18
Atomic => goto 19

-----

State 7:

26 : Atomic -> USCORE .  / 4

PRED => reduce 26
IDENT => reduce 26
NUM => reduce 26
LBRACE => reduce 26
RBRACE => reduce 26
LPAREN => reduce 26
RPAREN => reduce 26
PERIOD => reduce 26
COLON => reduce 26
COMMA => reduce 26
USCORE => reduce 26
STAR => reduce 26
LARROW => reduce 26
RARROW => reduce 26
LLOLLI => reduce 26
RLOLLI => reduce 26
UNIFY => reduce 26
DIFFER => reduce 26

-----

State 8:

6 : Syn -> . Syn COLON Syn  / 8
7 : Syn -> . Syn LLOLLI Syn  / 8
8 : Syn -> . Syn LARROW Syn  / 8
9 : Syn -> . Syn RLOLLI Syn  / 8
10 : Syn -> . Syn RLOLLI  / 8
11 : Syn -> . Syn RARROW Syn  / 8
12 : Syn -> . Syn STAR Syn  / 8
13 : Syn -> . Syn COMMA Syn  / 8
14 : Syn -> . Syn UNIFY Syn  / 8
15 : Syn -> . Syn DIFFER Syn  / 8
16 : Syn -> . BANG Syn  / 8
17 : Syn -> . DOLLAR Syn  / 8
18 : Syn -> . STAGE IDENT  / 8
19 : Syn -> . Atomic Atomics  / 8
22 : Atomic -> . LPAREN Syn RPAREN  / 9
23 : Atomic -> . LBRACE Syn RBRACE  / 9
23 : Atomic -> LBRACE . Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 9
25 : Atomic -> . IDENT  / 9
26 : Atomic -> . USCORE  / 9
27 : Atomic -> . PRED  / 9
28 : Atomic -> . NUM  / 9

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 21
Atomic => goto 15

-----

State 9:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . Syn COMMA Syn  / 10
14 : Syn -> . Syn UNIFY Syn  / 10
15 : Syn -> . Syn DIFFER Syn  / 10
16 : Syn -> . BANG Syn  / 10
17 : Syn -> . DOLLAR Syn  / 10
18 : Syn -> . STAGE IDENT  / 10
19 : Syn -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 11
22 : Atomic -> LPAREN . Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 11
24 : Atomic -> . LPAREN RPAREN  / 11
24 : Atomic -> LPAREN . RPAREN  / 4
25 : Atomic -> . IDENT  / 11
26 : Atomic -> . USCORE  / 11
27 : Atomic -> . PRED  / 11
28 : Atomic -> . NUM  / 11

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
RPAREN => shift 22
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 23
Atomic => goto 15

-----

State 10:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
17 : Syn -> DOLLAR . Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 24
Atomic => goto 15

-----

State 11:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
16 : Syn -> BANG . Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 25
Atomic => goto 15

-----

State 12:

0 : Top -> Syn . PERIOD  / 5
6 : Syn -> Syn . COLON Syn  / 2
7 : Syn -> Syn . LLOLLI Syn  / 2
8 : Syn -> Syn . LARROW Syn  / 2
9 : Syn -> Syn . RLOLLI Syn  / 2
10 : Syn -> Syn . RLOLLI  / 2
11 : Syn -> Syn . RARROW Syn  / 2
12 : Syn -> Syn . STAR Syn  / 2
13 : Syn -> Syn . COMMA Syn  / 2
14 : Syn -> Syn . UNIFY Syn  / 2
15 : Syn -> Syn . DIFFER Syn  / 2

PERIOD => shift 31
COLON => shift 30
COMMA => shift 29
STAR => shift 33
LARROW => shift 32
RARROW => shift 35
LLOLLI => shift 34
RLOLLI => shift 28
UNIFY => shift 27
DIFFER => shift 26

-----

State 13:

start -> Tops .  / 0

$ => accept

-----

State 14:

0 : Top -> . Syn PERIOD  / 5
1 : Top -> . STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 5
2 : Top -> . CONTEXT IDENT OpEquals LBRACE Syn RBRACE OpPeriod  / 5
3 : Top -> . HASHDENT Atomics PERIOD  / 5
4 : Tops -> .  / 13
5 : Tops -> . Top Tops  / 13
5 : Tops -> Top . Tops  / 13
6 : Syn -> . Syn COLON Syn  / 2
7 : Syn -> . Syn LLOLLI Syn  / 2
8 : Syn -> . Syn LARROW Syn  / 2
9 : Syn -> . Syn RLOLLI Syn  / 2
10 : Syn -> . Syn RLOLLI  / 2
11 : Syn -> . Syn RARROW Syn  / 2
12 : Syn -> . Syn STAR Syn  / 2
13 : Syn -> . Syn COMMA Syn  / 2
14 : Syn -> . Syn UNIFY Syn  / 2
15 : Syn -> . Syn DIFFER Syn  / 2
16 : Syn -> . BANG Syn  / 2
17 : Syn -> . DOLLAR Syn  / 2
18 : Syn -> . STAGE IDENT  / 2
19 : Syn -> . Atomic Atomics  / 2
22 : Atomic -> . LPAREN Syn RPAREN  / 3
23 : Atomic -> . LBRACE Syn RBRACE  / 3
24 : Atomic -> . LPAREN RPAREN  / 3
25 : Atomic -> . IDENT  / 3
26 : Atomic -> . USCORE  / 3
27 : Atomic -> . PRED  / 3
28 : Atomic -> . NUM  / 3

$ => reduce 4
PRED => shift 2
STAGE => shift 3
CONTEXT => shift 5
IDENT => shift 4
NUM => shift 1
HASHDENT => shift 6
LBRACE => shift 8
RBRACE => reduce 4
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Tops => goto 36
Top => goto 14
Syn => goto 12
Atomic => goto 15

-----

State 15:

19 : Syn -> Atomic . Atomics  / 12
20 : Atomics -> .  / 12
21 : Atomics -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
RBRACE => reduce 20
LPAREN => shift 9
RPAREN => reduce 20
PERIOD => reduce 20
COLON => reduce 20
COMMA => reduce 20
USCORE => shift 7
STAR => reduce 20
LARROW => reduce 20
RARROW => reduce 20
LLOLLI => reduce 20
RLOLLI => reduce 20
UNIFY => reduce 20
DIFFER => reduce 20
Atomics => goto 37
Atomic => goto 19

-----

State 16:

1 : Top -> STAGE IDENT . OpEquals LBRACE Tops RBRACE OpPeriod  / 5
18 : Syn -> STAGE IDENT .  / 2
29 : OpEquals -> .  / 14
30 : OpEquals -> . EQUALS  / 14

LBRACE => reduce 29
PERIOD => reduce 18
COLON => reduce 18
COMMA => reduce 18
EQUALS => shift 38
STAR => reduce 18
LARROW => reduce 18
RARROW => reduce 18
LLOLLI => reduce 18
RLOLLI => reduce 18
UNIFY => reduce 18
DIFFER => reduce 18
OpEquals => goto 39

-----

State 17:

2 : Top -> CONTEXT IDENT . OpEquals LBRACE Syn RBRACE OpPeriod  / 5
29 : OpEquals -> .  / 14
30 : OpEquals -> . EQUALS  / 14

LBRACE => reduce 29
EQUALS => shift 38
OpEquals => goto 40

-----

State 18:

3 : Top -> HASHDENT Atomics . PERIOD  / 5

PERIOD => shift 41

-----

State 19:

20 : Atomics -> .  / 12
21 : Atomics -> . Atomic Atomics  / 12
21 : Atomics -> Atomic . Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
RBRACE => reduce 20
LPAREN => shift 9
RPAREN => reduce 20
PERIOD => reduce 20
COLON => reduce 20
COMMA => reduce 20
USCORE => shift 7
STAR => reduce 20
LARROW => reduce 20
RARROW => reduce 20
LLOLLI => reduce 20
RLOLLI => reduce 20
UNIFY => reduce 20
DIFFER => reduce 20
Atomics => goto 42
Atomic => goto 19

-----

State 20:

18 : Syn -> STAGE . IDENT  / 12

IDENT => shift 43

-----

State 21:

6 : Syn -> Syn . COLON Syn  / 8
7 : Syn -> Syn . LLOLLI Syn  / 8
8 : Syn -> Syn . LARROW Syn  / 8
9 : Syn -> Syn . RLOLLI Syn  / 8
10 : Syn -> Syn . RLOLLI  / 8
11 : Syn -> Syn . RARROW Syn  / 8
12 : Syn -> Syn . STAR Syn  / 8
13 : Syn -> Syn . COMMA Syn  / 8
14 : Syn -> Syn . UNIFY Syn  / 8
15 : Syn -> Syn . DIFFER Syn  / 8
23 : Atomic -> LBRACE Syn . RBRACE  / 4

RBRACE => shift 44
COLON => shift 30
COMMA => shift 29
STAR => shift 33
LARROW => shift 32
RARROW => shift 35
LLOLLI => shift 34
RLOLLI => shift 28
UNIFY => shift 27
DIFFER => shift 26

-----

State 22:

24 : Atomic -> LPAREN RPAREN .  / 4

PRED => reduce 24
IDENT => reduce 24
NUM => reduce 24
LBRACE => reduce 24
RBRACE => reduce 24
LPAREN => reduce 24
RPAREN => reduce 24
PERIOD => reduce 24
COLON => reduce 24
COMMA => reduce 24
USCORE => reduce 24
STAR => reduce 24
LARROW => reduce 24
RARROW => reduce 24
LLOLLI => reduce 24
RLOLLI => reduce 24
UNIFY => reduce 24
DIFFER => reduce 24

-----

State 23:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
13 : Syn -> Syn . COMMA Syn  / 10
14 : Syn -> Syn . UNIFY Syn  / 10
15 : Syn -> Syn . DIFFER Syn  / 10
22 : Atomic -> LPAREN Syn . RPAREN  / 4

RPAREN => shift 45
COLON => shift 30
COMMA => shift 29
STAR => shift 33
LARROW => shift 32
RARROW => shift 35
LLOLLI => shift 34
RLOLLI => shift 28
UNIFY => shift 27
DIFFER => shift 26

-----

State 24:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12
17 : Syn -> DOLLAR Syn .  / 12

RBRACE => reduce 17
RPAREN => reduce 17
PERIOD => reduce 17
COLON => reduce 17, shift 30  PRECEDENCE
COMMA => reduce 17, shift 29  PRECEDENCE
STAR => reduce 17, shift 33  PRECEDENCE
LARROW => reduce 17, shift 32  PRECEDENCE
RARROW => reduce 17, shift 35  PRECEDENCE
LLOLLI => reduce 17, shift 34  PRECEDENCE
RLOLLI => reduce 17, shift 28  PRECEDENCE
UNIFY => shift 27, reduce 17  PRECEDENCE
DIFFER => shift 26, reduce 17  PRECEDENCE

-----

State 25:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12
16 : Syn -> BANG Syn .  / 12

RBRACE => reduce 16
RPAREN => reduce 16
PERIOD => reduce 16
COLON => reduce 16, shift 30  PRECEDENCE
COMMA => reduce 16, shift 29  PRECEDENCE
STAR => reduce 16, shift 33  PRECEDENCE
LARROW => reduce 16, shift 32  PRECEDENCE
RARROW => reduce 16, shift 35  PRECEDENCE
LLOLLI => reduce 16, shift 34  PRECEDENCE
RLOLLI => reduce 16, shift 28  PRECEDENCE
UNIFY => shift 27, reduce 16  PRECEDENCE
DIFFER => shift 26, reduce 16  PRECEDENCE

-----

State 26:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
15 : Syn -> Syn DIFFER . Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 46
Atomic => goto 15

-----

State 27:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
14 : Syn -> Syn UNIFY . Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 47
Atomic => goto 15

-----

State 28:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
9 : Syn -> Syn RLOLLI . Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
10 : Syn -> Syn RLOLLI .  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
RBRACE => reduce 10
LPAREN => shift 9
RPAREN => reduce 10
PERIOD => reduce 10
COLON => reduce 10
COMMA => reduce 10
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
STAR => reduce 10
LARROW => reduce 10
RARROW => reduce 10
LLOLLI => reduce 10
RLOLLI => reduce 10
UNIFY => reduce 10
DIFFER => reduce 10
Syn => goto 48
Atomic => goto 15

-----

State 29:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
13 : Syn -> Syn COMMA . Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 49
Atomic => goto 15

-----

State 30:

6 : Syn -> . Syn COLON Syn  / 12
6 : Syn -> Syn COLON . Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 50
Atomic => goto 15

-----

State 31:

0 : Top -> Syn PERIOD .  / 5

$ => reduce 0
PRED => reduce 0
STAGE => reduce 0
CONTEXT => reduce 0
IDENT => reduce 0
NUM => reduce 0
HASHDENT => reduce 0
LBRACE => reduce 0
RBRACE => reduce 0
LPAREN => reduce 0
USCORE => reduce 0
DOLLAR => reduce 0
BANG => reduce 0

-----

State 32:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
8 : Syn -> Syn LARROW . Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 51
Atomic => goto 15

-----

State 33:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
12 : Syn -> Syn STAR . Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 52
Atomic => goto 15

-----

State 34:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
7 : Syn -> Syn LLOLLI . Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 53
Atomic => goto 15

-----

State 35:

6 : Syn -> . Syn COLON Syn  / 12
7 : Syn -> . Syn LLOLLI Syn  / 12
8 : Syn -> . Syn LARROW Syn  / 12
9 : Syn -> . Syn RLOLLI Syn  / 12
10 : Syn -> . Syn RLOLLI  / 12
11 : Syn -> . Syn RARROW Syn  / 12
11 : Syn -> Syn RARROW . Syn  / 12
12 : Syn -> . Syn STAR Syn  / 12
13 : Syn -> . Syn COMMA Syn  / 12
14 : Syn -> . Syn UNIFY Syn  / 12
15 : Syn -> . Syn DIFFER Syn  / 12
16 : Syn -> . BANG Syn  / 12
17 : Syn -> . DOLLAR Syn  / 12
18 : Syn -> . STAGE IDENT  / 12
19 : Syn -> . Atomic Atomics  / 12
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LBRACE Syn RBRACE  / 4
24 : Atomic -> . LPAREN RPAREN  / 4
25 : Atomic -> . IDENT  / 4
26 : Atomic -> . USCORE  / 4
27 : Atomic -> . PRED  / 4
28 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 54
Atomic => goto 15

-----

State 36:

5 : Tops -> Top Tops .  / 13

$ => reduce 5
RBRACE => reduce 5

-----

State 37:

19 : Syn -> Atomic Atomics .  / 12

RBRACE => reduce 19
RPAREN => reduce 19
PERIOD => reduce 19
COLON => reduce 19
COMMA => reduce 19
STAR => reduce 19
LARROW => reduce 19
RARROW => reduce 19
LLOLLI => reduce 19
RLOLLI => reduce 19
UNIFY => reduce 19
DIFFER => reduce 19

-----

State 38:

30 : OpEquals -> EQUALS .  / 14

LBRACE => reduce 30

-----

State 39:

1 : Top -> STAGE IDENT OpEquals . LBRACE Tops RBRACE OpPeriod  / 5

LBRACE => shift 55

-----

State 40:

2 : Top -> CONTEXT IDENT OpEquals . LBRACE Syn RBRACE OpPeriod  / 5

LBRACE => shift 56

-----

State 41:

3 : Top -> HASHDENT Atomics PERIOD .  / 5

$ => reduce 3
PRED => reduce 3
STAGE => reduce 3
CONTEXT => reduce 3
IDENT => reduce 3
NUM => reduce 3
HASHDENT => reduce 3
LBRACE => reduce 3
RBRACE => reduce 3
LPAREN => reduce 3
USCORE => reduce 3
DOLLAR => reduce 3
BANG => reduce 3

-----

State 42:

21 : Atomics -> Atomic Atomics .  / 12

RBRACE => reduce 21
RPAREN => reduce 21
PERIOD => reduce 21
COLON => reduce 21
COMMA => reduce 21
STAR => reduce 21
LARROW => reduce 21
RARROW => reduce 21
LLOLLI => reduce 21
RLOLLI => reduce 21
UNIFY => reduce 21
DIFFER => reduce 21

-----

State 43:

18 : Syn -> STAGE IDENT .  / 12

RBRACE => reduce 18
RPAREN => reduce 18
PERIOD => reduce 18
COLON => reduce 18
COMMA => reduce 18
STAR => reduce 18
LARROW => reduce 18
RARROW => reduce 18
LLOLLI => reduce 18
RLOLLI => reduce 18
UNIFY => reduce 18
DIFFER => reduce 18

-----

State 44:

23 : Atomic -> LBRACE Syn RBRACE .  / 4

PRED => reduce 23
IDENT => reduce 23
NUM => reduce 23
LBRACE => reduce 23
RBRACE => reduce 23
LPAREN => reduce 23
RPAREN => reduce 23
PERIOD => reduce 23
COLON => reduce 23
COMMA => reduce 23
USCORE => reduce 23
STAR => reduce 23
LARROW => reduce 23
RARROW => reduce 23
LLOLLI => reduce 23
RLOLLI => reduce 23
UNIFY => reduce 23
DIFFER => reduce 23

-----

State 45:

22 : Atomic -> LPAREN Syn RPAREN .  / 4

PRED => reduce 22
IDENT => reduce 22
NUM => reduce 22
LBRACE => reduce 22
RBRACE => reduce 22
LPAREN => reduce 22
RPAREN => reduce 22
PERIOD => reduce 22
COLON => reduce 22
COMMA => reduce 22
USCORE => reduce 22
STAR => reduce 22
LARROW => reduce 22
RARROW => reduce 22
LLOLLI => reduce 22
RLOLLI => reduce 22
UNIFY => reduce 22
DIFFER => reduce 22

-----

State 46:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12
15 : Syn -> Syn DIFFER Syn .  / 12

RBRACE => reduce 15
RPAREN => reduce 15
PERIOD => reduce 15
COLON => reduce 15, shift 30  PRECEDENCE
COMMA => reduce 15, shift 29  PRECEDENCE
STAR => reduce 15, shift 33  PRECEDENCE
LARROW => reduce 15, shift 32  PRECEDENCE
RARROW => reduce 15, shift 35  PRECEDENCE
LLOLLI => reduce 15, shift 34  PRECEDENCE
RLOLLI => reduce 15, shift 28  PRECEDENCE
UNIFY => shift 27, reduce 15  PRECEDENCE
DIFFER => shift 26, reduce 15  PRECEDENCE

-----

State 47:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
14 : Syn -> Syn UNIFY Syn .  / 12
15 : Syn -> Syn . DIFFER Syn  / 12

RBRACE => reduce 14
RPAREN => reduce 14
PERIOD => reduce 14
COLON => reduce 14, shift 30  PRECEDENCE
COMMA => reduce 14, shift 29  PRECEDENCE
STAR => reduce 14, shift 33  PRECEDENCE
LARROW => reduce 14, shift 32  PRECEDENCE
RARROW => reduce 14, shift 35  PRECEDENCE
LLOLLI => reduce 14, shift 34  PRECEDENCE
RLOLLI => reduce 14, shift 28  PRECEDENCE
UNIFY => shift 27, reduce 14  PRECEDENCE
DIFFER => shift 26, reduce 14  PRECEDENCE

-----

State 48:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
9 : Syn -> Syn RLOLLI Syn .  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12

RBRACE => reduce 9
RPAREN => reduce 9
PERIOD => reduce 9
COLON => reduce 9, shift 30  PRECEDENCE
COMMA => reduce 9, shift 29  PRECEDENCE
STAR => shift 33, reduce 9  PRECEDENCE
LARROW => reduce 9, shift 32  PRECEDENCE
RARROW => shift 35, reduce 9  PRECEDENCE
LLOLLI => reduce 9, shift 34  PRECEDENCE
RLOLLI => shift 28, reduce 9  PRECEDENCE
UNIFY => shift 27, reduce 9  PRECEDENCE
DIFFER => shift 26, reduce 9  PRECEDENCE

-----

State 49:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
13 : Syn -> Syn COMMA Syn .  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12

RBRACE => reduce 13
RPAREN => reduce 13
PERIOD => reduce 13
COLON => shift 30, reduce 13  PRECEDENCE
COMMA => shift 29, reduce 13  PRECEDENCE
STAR => shift 33, reduce 13  PRECEDENCE
LARROW => shift 32, reduce 13  PRECEDENCE
RARROW => shift 35, reduce 13  PRECEDENCE
LLOLLI => shift 34, reduce 13  PRECEDENCE
RLOLLI => shift 28, reduce 13  PRECEDENCE
UNIFY => shift 27, reduce 13  PRECEDENCE
DIFFER => shift 26, reduce 13  PRECEDENCE

-----

State 50:

6 : Syn -> Syn . COLON Syn  / 12
6 : Syn -> Syn COLON Syn .  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12

RBRACE => reduce 6
RPAREN => reduce 6
PERIOD => reduce 6
COLON => shift 30, reduce 6  PRECEDENCE
COMMA => reduce 6, shift 29  PRECEDENCE
STAR => shift 33, reduce 6  PRECEDENCE
LARROW => shift 32, reduce 6  PRECEDENCE
RARROW => shift 35, reduce 6  PRECEDENCE
LLOLLI => shift 34, reduce 6  PRECEDENCE
RLOLLI => shift 28, reduce 6  PRECEDENCE
UNIFY => shift 27, reduce 6  PRECEDENCE
DIFFER => shift 26, reduce 6  PRECEDENCE

-----

State 51:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
8 : Syn -> Syn LARROW Syn .  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12

RBRACE => reduce 8
RPAREN => reduce 8
PERIOD => reduce 8
COLON => reduce 8, shift 30  PRECEDENCE
COMMA => reduce 8, shift 29  PRECEDENCE
STAR => shift 33, reduce 8  PRECEDENCE
LARROW => reduce 8, shift 32  PRECEDENCE
RARROW => shift 35, reduce 8  PRECEDENCE
LLOLLI => reduce 8, shift 34  PRECEDENCE
RLOLLI => shift 28, reduce 8  PRECEDENCE
UNIFY => shift 27, reduce 8  PRECEDENCE
DIFFER => shift 26, reduce 8  PRECEDENCE

-----

State 52:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
12 : Syn -> Syn STAR Syn .  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12

RBRACE => reduce 12
RPAREN => reduce 12
PERIOD => reduce 12
COLON => reduce 12, shift 30  PRECEDENCE
COMMA => reduce 12, shift 29  PRECEDENCE
STAR => shift 33, reduce 12  PRECEDENCE
LARROW => reduce 12, shift 32  PRECEDENCE
RARROW => reduce 12, shift 35  PRECEDENCE
LLOLLI => reduce 12, shift 34  PRECEDENCE
RLOLLI => reduce 12, shift 28  PRECEDENCE
UNIFY => shift 27, reduce 12  PRECEDENCE
DIFFER => shift 26, reduce 12  PRECEDENCE

-----

State 53:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
7 : Syn -> Syn LLOLLI Syn .  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12

RBRACE => reduce 7
RPAREN => reduce 7
PERIOD => reduce 7
COLON => reduce 7, shift 30  PRECEDENCE
COMMA => reduce 7, shift 29  PRECEDENCE
STAR => shift 33, reduce 7  PRECEDENCE
LARROW => reduce 7, shift 32  PRECEDENCE
RARROW => shift 35, reduce 7  PRECEDENCE
LLOLLI => reduce 7, shift 34  PRECEDENCE
RLOLLI => shift 28, reduce 7  PRECEDENCE
UNIFY => shift 27, reduce 7  PRECEDENCE
DIFFER => shift 26, reduce 7  PRECEDENCE

-----

State 54:

6 : Syn -> Syn . COLON Syn  / 12
7 : Syn -> Syn . LLOLLI Syn  / 12
8 : Syn -> Syn . LARROW Syn  / 12
9 : Syn -> Syn . RLOLLI Syn  / 12
10 : Syn -> Syn . RLOLLI  / 12
11 : Syn -> Syn . RARROW Syn  / 12
11 : Syn -> Syn RARROW Syn .  / 12
12 : Syn -> Syn . STAR Syn  / 12
13 : Syn -> Syn . COMMA Syn  / 12
14 : Syn -> Syn . UNIFY Syn  / 12
15 : Syn -> Syn . DIFFER Syn  / 12

RBRACE => reduce 11
RPAREN => reduce 11
PERIOD => reduce 11
COLON => reduce 11, shift 30  PRECEDENCE
COMMA => reduce 11, shift 29  PRECEDENCE
STAR => shift 33, reduce 11  PRECEDENCE
LARROW => reduce 11, shift 32  PRECEDENCE
RARROW => shift 35, reduce 11  PRECEDENCE
LLOLLI => reduce 11, shift 34  PRECEDENCE
RLOLLI => shift 28, reduce 11  PRECEDENCE
UNIFY => shift 27, reduce 11  PRECEDENCE
DIFFER => shift 26, reduce 11  PRECEDENCE

-----

State 55:

0 : Top -> . Syn PERIOD  / 15
1 : Top -> . STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 15
1 : Top -> STAGE IDENT OpEquals LBRACE . Tops RBRACE OpPeriod  / 5
2 : Top -> . CONTEXT IDENT OpEquals LBRACE Syn RBRACE OpPeriod  / 15
3 : Top -> . HASHDENT Atomics PERIOD  / 15
4 : Tops -> .  / 16
5 : Tops -> . Top Tops  / 16
6 : Syn -> . Syn COLON Syn  / 2
7 : Syn -> . Syn LLOLLI Syn  / 2
8 : Syn -> . Syn LARROW Syn  / 2
9 : Syn -> . Syn RLOLLI Syn  / 2
10 : Syn -> . Syn RLOLLI  / 2
11 : Syn -> . Syn RARROW Syn  / 2
12 : Syn -> . Syn STAR Syn  / 2
13 : Syn -> . Syn COMMA Syn  / 2
14 : Syn -> . Syn UNIFY Syn  / 2
15 : Syn -> . Syn DIFFER Syn  / 2
16 : Syn -> . BANG Syn  / 2
17 : Syn -> . DOLLAR Syn  / 2
18 : Syn -> . STAGE IDENT  / 2
19 : Syn -> . Atomic Atomics  / 2
22 : Atomic -> . LPAREN Syn RPAREN  / 3
23 : Atomic -> . LBRACE Syn RBRACE  / 3
24 : Atomic -> . LPAREN RPAREN  / 3
25 : Atomic -> . IDENT  / 3
26 : Atomic -> . USCORE  / 3
27 : Atomic -> . PRED  / 3
28 : Atomic -> . NUM  / 3

PRED => shift 2
STAGE => shift 3
CONTEXT => shift 5
IDENT => shift 4
NUM => shift 1
HASHDENT => shift 6
LBRACE => shift 8
RBRACE => reduce 4
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Tops => goto 57
Top => goto 14
Syn => goto 12
Atomic => goto 15

-----

State 56:

2 : Top -> CONTEXT IDENT OpEquals LBRACE . Syn RBRACE OpPeriod  / 5
6 : Syn -> . Syn COLON Syn  / 8
7 : Syn -> . Syn LLOLLI Syn  / 8
8 : Syn -> . Syn LARROW Syn  / 8
9 : Syn -> . Syn RLOLLI Syn  / 8
10 : Syn -> . Syn RLOLLI  / 8
11 : Syn -> . Syn RARROW Syn  / 8
12 : Syn -> . Syn STAR Syn  / 8
13 : Syn -> . Syn COMMA Syn  / 8
14 : Syn -> . Syn UNIFY Syn  / 8
15 : Syn -> . Syn DIFFER Syn  / 8
16 : Syn -> . BANG Syn  / 8
17 : Syn -> . DOLLAR Syn  / 8
18 : Syn -> . STAGE IDENT  / 8
19 : Syn -> . Atomic Atomics  / 8
22 : Atomic -> . LPAREN Syn RPAREN  / 9
23 : Atomic -> . LBRACE Syn RBRACE  / 9
24 : Atomic -> . LPAREN RPAREN  / 9
25 : Atomic -> . IDENT  / 9
26 : Atomic -> . USCORE  / 9
27 : Atomic -> . PRED  / 9
28 : Atomic -> . NUM  / 9

PRED => shift 2
STAGE => shift 20
IDENT => shift 4
NUM => shift 1
LBRACE => shift 8
LPAREN => shift 9
USCORE => shift 7
DOLLAR => shift 10
BANG => shift 11
Syn => goto 58
Atomic => goto 15

-----

State 57:

1 : Top -> STAGE IDENT OpEquals LBRACE Tops . RBRACE OpPeriod  / 5

RBRACE => shift 59

-----

State 58:

2 : Top -> CONTEXT IDENT OpEquals LBRACE Syn . RBRACE OpPeriod  / 5
6 : Syn -> Syn . COLON Syn  / 8
7 : Syn -> Syn . LLOLLI Syn  / 8
8 : Syn -> Syn . LARROW Syn  / 8
9 : Syn -> Syn . RLOLLI Syn  / 8
10 : Syn -> Syn . RLOLLI  / 8
11 : Syn -> Syn . RARROW Syn  / 8
12 : Syn -> Syn . STAR Syn  / 8
13 : Syn -> Syn . COMMA Syn  / 8
14 : Syn -> Syn . UNIFY Syn  / 8
15 : Syn -> Syn . DIFFER Syn  / 8

RBRACE => shift 60
COLON => shift 30
COMMA => shift 29
STAR => shift 33
LARROW => shift 32
RARROW => shift 35
LLOLLI => shift 34
RLOLLI => shift 28
UNIFY => shift 27
DIFFER => shift 26

-----

State 59:

1 : Top -> STAGE IDENT OpEquals LBRACE Tops RBRACE . OpPeriod  / 5
31 : OpPeriod -> .  / 5
32 : OpPeriod -> . PERIOD  / 5

$ => reduce 31
PRED => reduce 31
STAGE => reduce 31
CONTEXT => reduce 31
IDENT => reduce 31
NUM => reduce 31
HASHDENT => reduce 31
LBRACE => reduce 31
RBRACE => reduce 31
LPAREN => reduce 31
PERIOD => shift 61
USCORE => reduce 31
DOLLAR => reduce 31
BANG => reduce 31
OpPeriod => goto 62

-----

State 60:

2 : Top -> CONTEXT IDENT OpEquals LBRACE Syn RBRACE . OpPeriod  / 5
31 : OpPeriod -> .  / 5
32 : OpPeriod -> . PERIOD  / 5

$ => reduce 31
PRED => reduce 31
STAGE => reduce 31
CONTEXT => reduce 31
IDENT => reduce 31
NUM => reduce 31
HASHDENT => reduce 31
LBRACE => reduce 31
RBRACE => reduce 31
LPAREN => reduce 31
PERIOD => shift 61
USCORE => reduce 31
DOLLAR => reduce 31
BANG => reduce 31
OpPeriod => goto 63

-----

State 61:

32 : OpPeriod -> PERIOD .  / 5

$ => reduce 32
PRED => reduce 32
STAGE => reduce 32
CONTEXT => reduce 32
IDENT => reduce 32
NUM => reduce 32
HASHDENT => reduce 32
LBRACE => reduce 32
RBRACE => reduce 32
LPAREN => reduce 32
USCORE => reduce 32
DOLLAR => reduce 32
BANG => reduce 32

-----

State 62:

1 : Top -> STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod .  / 5

$ => reduce 1
PRED => reduce 1
STAGE => reduce 1
CONTEXT => reduce 1
IDENT => reduce 1
NUM => reduce 1
HASHDENT => reduce 1
LBRACE => reduce 1
RBRACE => reduce 1
LPAREN => reduce 1
USCORE => reduce 1
DOLLAR => reduce 1
BANG => reduce 1

-----

State 63:

2 : Top -> CONTEXT IDENT OpEquals LBRACE Syn RBRACE OpPeriod .  / 5

$ => reduce 2
PRED => reduce 2
STAGE => reduce 2
CONTEXT => reduce 2
IDENT => reduce 2
NUM => reduce 2
HASHDENT => reduce 2
LBRACE => reduce 2
RBRACE => reduce 2
LPAREN => reduce 2
USCORE => reduce 2
DOLLAR => reduce 2
BANG => reduce 2

-----

lookahead 0 = $ 
lookahead 1 = $ PRED STAGE CONTEXT IDENT NUM HASHDENT LBRACE LPAREN USCORE DOLLAR BANG 
lookahead 2 = PERIOD COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 3 = PRED IDENT NUM LBRACE LPAREN PERIOD COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 4 = PRED IDENT NUM LBRACE RBRACE LPAREN RPAREN PERIOD COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 5 = $ PRED STAGE CONTEXT IDENT NUM HASHDENT LBRACE RBRACE LPAREN USCORE DOLLAR BANG 
lookahead 6 = PERIOD 
lookahead 7 = PRED IDENT NUM LBRACE LPAREN PERIOD USCORE 
lookahead 8 = RBRACE COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 9 = PRED IDENT NUM LBRACE RBRACE LPAREN COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 10 = RPAREN COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 11 = PRED IDENT NUM LBRACE LPAREN RPAREN COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 12 = RBRACE RPAREN PERIOD COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 13 = $ RBRACE 
lookahead 14 = LBRACE 
lookahead 15 = PRED STAGE CONTEXT IDENT NUM HASHDENT LBRACE RBRACE LPAREN USCORE DOLLAR BANG 
lookahead 16 = RBRACE 

*)

struct
local
structure Value = struct
datatype nonterminal =
nonterminal
| string of Arg.string
| int of Arg.int
| top of Arg.top
| tops of Arg.tops
| syn of Arg.syn
| syns of Arg.syns
| ign of Arg.ign
end
structure ParseEngine = ParseEngineFun (structure Streamable = Streamable
type terminal = Arg.terminal
type value = Value.nonterminal
val dummy = Value.nonterminal
fun read terminal =
(case terminal of
Arg.PRED => (1, Value.nonterminal)
| Arg.STAGE => (2, Value.nonterminal)
| Arg.CONTEXT => (3, Value.nonterminal)
| Arg.IDENT x => (4, Value.string x)
| Arg.NUM x => (5, Value.int x)
| Arg.HASHDENT x => (6, Value.string x)
| Arg.LBRACE => (7, Value.nonterminal)
| Arg.RBRACE => (8, Value.nonterminal)
| Arg.LPAREN => (9, Value.nonterminal)
| Arg.RPAREN => (10, Value.nonterminal)
| Arg.PERIOD => (11, Value.nonterminal)
| Arg.COLON => (12, Value.nonterminal)
| Arg.COMMA => (13, Value.nonterminal)
| Arg.EQUALS => (14, Value.nonterminal)
| Arg.USCORE => (15, Value.nonterminal)
| Arg.DOLLAR => (16, Value.nonterminal)
| Arg.BANG => (17, Value.nonterminal)
| Arg.STAR => (18, Value.nonterminal)
| Arg.LARROW => (19, Value.nonterminal)
| Arg.RARROW => (20, Value.nonterminal)
| Arg.LLOLLI => (21, Value.nonterminal)
| Arg.RLOLLI => (22, Value.nonterminal)
| Arg.UNIFY => (23, Value.nonterminal)
| Arg.DIFFER => (24, Value.nonterminal)
)
)
in
val parse = ParseEngine.parse (
ParseEngine.next5x1 "z\131\132\134\133\130\135\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128b\128\128bb\128bbbbbbb\128b\128\128bbbbbbb\128\128\128\128\128\128\128\128c\128\128cc\128ccccccc\128c\128\128ccccccc\128\128\128\128\128\128\128\128\128\128\128\145\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128e\128\128ee\128eeeeeee\128e\128\128eeeeeee\128\128\128\128\128\128\128\128\128\128\128\146\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\128\128\133\130\128\137\128\138\128j\128\128\128\136\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128d\128\128dd\128ddddddd\128d\128\128ddddddd\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\151\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\160\159\158\128\128\128\128\162\161\164\163\157\156\155\128\128\128\128\128\128\128\127\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128z\131\132\134\133\130\135\137z\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\128\128\133\130\128\137j\138jjjj\128\136\128\128jjjjjjj\128\128\128\128\128\128\128\128\128\128\128\128\128\128a\128\128\128lll\167\128\128\128lllllll\128\128\128\128\128\128\128\128\128\128\128\128\128\128a\128\128\128\128\128\128\167\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\170\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\128\128\133\130\128\137j\138jjjj\128\136\128\128jjjjjjj\128\128\128\128\128\128\128\128\128\128\128\172\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\173\128\128\128\159\158\128\128\128\128\162\161\164\163\157\156\155\128\128\128\128\128\128\128\128f\128\128ff\128fffffff\128f\128\128fffffff\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\174\128\159\158\128\128\128\128\162\161\164\163\157\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128m\128mmmm\128\128\128\128mmmmm\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128n\128nnnn\128\128\128\128nnnnn\156\155\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137t\138tttt\128\136\139\140ttttttt\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128~~~~~~~~~~\128\128\128\128\128~~~\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128y\128\128\128\128\128\128\128y\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128k\128kkkk\128\128\128\128kkkkkkk\128\128\128\128\128\128\128\128\128\128\128\128\128\128`\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\184\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\185\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128{{{{{{{{{{\128\128\128\128\128{{{\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128i\128iiii\128\128\128\128iiiiiii\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128l\128llll\128\128\128\128lllllll\128\128\128\128\128\128\128\128g\128\128gg\128ggggggg\128g\128\128ggggggg\128\128\128\128\128\128\128\128h\128\128hh\128hhhhhhh\128h\128\128hhhhhhh\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128o\128oooo\128\128\128\128ooooo\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128p\128pppp\128\128\128\128ppppp\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128u\128uuuu\128\128\128\128\162u\164u\157\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128q\128qq\159\158\128\128\128\128\162\161\164\163\157\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128x\128xx\159x\128\128\128\128\162\161\164\163\157\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128v\128vvvv\128\128\128\128\162v\164v\157\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128r\128rrrr\128\128\128\128\162rrrr\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128w\128wwww\128\128\128\128\162w\164w\157\156\155\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128s\128ssss\128\128\128\128\162s\164s\157\156\155\128\128\128\128\128\128\128\128\131\132\134\133\130\135\137z\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\149\128\133\130\128\137\128\138\128\128\128\128\128\136\139\140\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\188\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\189\128\128\128\159\158\128\128\128\128\162\161\164\163\157\156\155\128\128\128\128\128\128\128__________\128\190\128\128\128___\128\128\128\128\128\128\128\128\128\128\128\128\128\128__________\128\190\128\128\128___\128\128\128\128\128\128\128\128\128\128\128\128\128\128^^^^^^^^^^\128\128\128\128\128^^^\128\128\128\128\128\128\128\128\128\128\128\128\128\128}}}}}}}}}}\128\128\128\128\128}}}\128\128\128\128\128\128\128\128\128\128\128\128\128\128||||||||||\128\128\128\128\128|||\128\128\128\128\128\128\128\128\128\128\128\128\128\128",
ParseEngine.next5x1 "\141\142\140\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\146\147\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\149\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\151\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\152\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\153\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\164\142\140\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\165\147\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\167\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\168\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\170\147\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\174\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\175\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\176\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\177\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\178\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\179\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\180\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\181\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\182\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\185\142\140\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\186\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\190\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\191\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128",
Vector.fromList [(1,2,(fn _::Value.syn(arg0)::rest => Value.top(Arg.Decl arg0)::rest|_=>raise (Fail "bad parser"))),
(1,7,(fn _::_::Value.tops(arg0)::_::_::Value.string(arg1)::_::rest => Value.top(Arg.Stage {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(1,7,(fn _::_::Value.syn(arg0)::_::_::Value.string(arg1)::_::rest => Value.top(Arg.Context {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(1,3,(fn _::Value.syns(arg0)::Value.string(arg1)::rest => Value.top(Arg.Special {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(0,0,(fn rest => Value.tops(Arg.NilT {})::rest)),
(0,2,(fn Value.tops(arg0)::Value.top(arg1)::rest => Value.tops(Arg.ConsT {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Ascribe {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.LolliL {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.ArrowL {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Lolli {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn _::Value.syn(arg0)::rest => Value.syn(Arg.LolliOne arg0)::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Arrow {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Star {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Comma {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Unify {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Differ {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn Value.syn(arg0)::_::rest => Value.syn(Arg.Bang arg0)::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn Value.syn(arg0)::_::rest => Value.syn(Arg.Dollar arg0)::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn Value.string(arg0)::_::rest => Value.syn(Arg.StagePred arg0)::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn Value.syns(arg0)::Value.syn(arg1)::rest => Value.syn(Arg.app {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(5,0,(fn rest => Value.syns(Arg.Nil {})::rest)),
(5,2,(fn Value.syns(arg0)::Value.syn(arg1)::rest => Value.syns(Arg.Cons {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(6,3,(fn _::Value.syn(arg0)::_::rest => Value.syn(Arg.parens arg0)::rest|_=>raise (Fail "bad parser"))),
(6,3,(fn _::Value.syn(arg0)::_::rest => Value.syn(Arg.Braces arg0)::rest|_=>raise (Fail "bad parser"))),
(6,2,(fn _::_::rest => Value.syn(Arg.One {})::rest|_=>raise (Fail "bad parser"))),
(6,1,(fn Value.string(arg0)::rest => Value.syn(Arg.Id arg0)::rest|_=>raise (Fail "bad parser"))),
(6,1,(fn _::rest => Value.syn(Arg.Wild {})::rest|_=>raise (Fail "bad parser"))),
(6,1,(fn _::rest => Value.syn(Arg.Pred {})::rest|_=>raise (Fail "bad parser"))),
(6,1,(fn Value.int(arg0)::rest => Value.syn(Arg.Num arg0)::rest|_=>raise (Fail "bad parser"))),
(3,0,(fn rest => Value.ign(Arg.Ign {})::rest)),
(3,1,(fn _::rest => Value.ign(Arg.Ign {})::rest|_=>raise (Fail "bad parser"))),
(4,0,(fn rest => Value.ign(Arg.Ign {})::rest)),
(4,1,(fn _::rest => Value.ign(Arg.Ign {})::rest|_=>raise (Fail "bad parser")))],
(fn Value.tops x => x | _ => raise (Fail "bad parser")), Arg.error)
end
end
