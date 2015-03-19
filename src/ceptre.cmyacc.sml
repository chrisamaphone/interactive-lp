
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
          val parens : syn -> syn
          val Cons : syn * syns -> syns
          val Nil : unit -> syns
          val App : syn * syns -> syn
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
23 : Atomic -> . LPAREN RPAREN  / 3
24 : Atomic -> . IDENT  / 3
25 : Atomic -> . USCORE  / 3
26 : Atomic -> . PRED  / 3
27 : Atomic -> . NUM  / 3

$ => reduce 4
PRED => shift 2
STAGE => shift 3
CONTEXT => shift 5
IDENT => shift 4
NUM => shift 1
HASHDENT => shift 6
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Tops => goto 12
Top => goto 13
Syn => goto 11
Atomic => goto 14

-----

State 1:

27 : Atomic -> NUM .  / 4

PRED => reduce 27
IDENT => reduce 27
NUM => reduce 27
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

State 2:

26 : Atomic -> PRED .  / 4

PRED => reduce 26
IDENT => reduce 26
NUM => reduce 26
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

State 3:

1 : Top -> STAGE . IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 5
18 : Syn -> STAGE . IDENT  / 2

IDENT => shift 15

-----

State 4:

24 : Atomic -> IDENT .  / 4

PRED => reduce 24
IDENT => reduce 24
NUM => reduce 24
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

State 5:

2 : Top -> CONTEXT . IDENT OpEquals LBRACE Syn RBRACE OpPeriod  / 5

IDENT => shift 16

-----

State 6:

3 : Top -> HASHDENT . Atomics PERIOD  / 5
20 : Atomics -> .  / 6
21 : Atomics -> . Atomic Atomics  / 6
22 : Atomic -> . LPAREN Syn RPAREN  / 7
23 : Atomic -> . LPAREN RPAREN  / 7
24 : Atomic -> . IDENT  / 7
25 : Atomic -> . USCORE  / 7
26 : Atomic -> . PRED  / 7
27 : Atomic -> . NUM  / 7

PRED => shift 2
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
PERIOD => reduce 20
USCORE => shift 8
Atomics => goto 17
Atomic => goto 18

-----

State 7:

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
22 : Atomic -> LPAREN . Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 9
23 : Atomic -> LPAREN . RPAREN  / 4
24 : Atomic -> . IDENT  / 9
25 : Atomic -> . USCORE  / 9
26 : Atomic -> . PRED  / 9
27 : Atomic -> . NUM  / 9

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
RPAREN => shift 20
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 21
Atomic => goto 14

-----

State 8:

25 : Atomic -> USCORE .  / 4

PRED => reduce 25
IDENT => reduce 25
NUM => reduce 25
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
17 : Syn -> DOLLAR . Syn  / 10
18 : Syn -> . STAGE IDENT  / 10
19 : Syn -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 22
Atomic => goto 14

-----

State 10:

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
16 : Syn -> BANG . Syn  / 10
17 : Syn -> . DOLLAR Syn  / 10
18 : Syn -> . STAGE IDENT  / 10
19 : Syn -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 23
Atomic => goto 14

-----

State 11:

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

PERIOD => shift 29
COLON => shift 28
COMMA => shift 27
STAR => shift 31
LARROW => shift 30
RARROW => shift 33
LLOLLI => shift 32
RLOLLI => shift 26
UNIFY => shift 25
DIFFER => shift 24

-----

State 12:

start -> Tops .  / 0

$ => accept

-----

State 13:

0 : Top -> . Syn PERIOD  / 5
1 : Top -> . STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 5
2 : Top -> . CONTEXT IDENT OpEquals LBRACE Syn RBRACE OpPeriod  / 5
3 : Top -> . HASHDENT Atomics PERIOD  / 5
4 : Tops -> .  / 11
5 : Tops -> . Top Tops  / 11
5 : Tops -> Top . Tops  / 11
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
23 : Atomic -> . LPAREN RPAREN  / 3
24 : Atomic -> . IDENT  / 3
25 : Atomic -> . USCORE  / 3
26 : Atomic -> . PRED  / 3
27 : Atomic -> . NUM  / 3

$ => reduce 4
PRED => shift 2
STAGE => shift 3
CONTEXT => shift 5
IDENT => shift 4
NUM => shift 1
HASHDENT => shift 6
RBRACE => reduce 4
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Tops => goto 34
Top => goto 13
Syn => goto 11
Atomic => goto 14

-----

State 14:

19 : Syn -> Atomic . Atomics  / 10
20 : Atomics -> .  / 10
21 : Atomics -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
IDENT => shift 4
NUM => shift 1
RBRACE => reduce 20
LPAREN => shift 7
RPAREN => reduce 20
PERIOD => reduce 20
COLON => reduce 20
COMMA => reduce 20
USCORE => shift 8
STAR => reduce 20
LARROW => reduce 20
RARROW => reduce 20
LLOLLI => reduce 20
RLOLLI => reduce 20
UNIFY => reduce 20
DIFFER => reduce 20
Atomics => goto 35
Atomic => goto 18

-----

State 15:

1 : Top -> STAGE IDENT . OpEquals LBRACE Tops RBRACE OpPeriod  / 5
18 : Syn -> STAGE IDENT .  / 2
28 : OpEquals -> .  / 12
29 : OpEquals -> . EQUALS  / 12

LBRACE => reduce 28
PERIOD => reduce 18
COLON => reduce 18
COMMA => reduce 18
EQUALS => shift 36
STAR => reduce 18
LARROW => reduce 18
RARROW => reduce 18
LLOLLI => reduce 18
RLOLLI => reduce 18
UNIFY => reduce 18
DIFFER => reduce 18
OpEquals => goto 37

-----

State 16:

2 : Top -> CONTEXT IDENT . OpEquals LBRACE Syn RBRACE OpPeriod  / 5
28 : OpEquals -> .  / 12
29 : OpEquals -> . EQUALS  / 12

LBRACE => reduce 28
EQUALS => shift 36
OpEquals => goto 38

-----

State 17:

3 : Top -> HASHDENT Atomics . PERIOD  / 5

PERIOD => shift 39

-----

State 18:

20 : Atomics -> .  / 10
21 : Atomics -> . Atomic Atomics  / 10
21 : Atomics -> Atomic . Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
IDENT => shift 4
NUM => shift 1
RBRACE => reduce 20
LPAREN => shift 7
RPAREN => reduce 20
PERIOD => reduce 20
COLON => reduce 20
COMMA => reduce 20
USCORE => shift 8
STAR => reduce 20
LARROW => reduce 20
RARROW => reduce 20
LLOLLI => reduce 20
RLOLLI => reduce 20
UNIFY => reduce 20
DIFFER => reduce 20
Atomics => goto 40
Atomic => goto 18

-----

State 19:

18 : Syn -> STAGE . IDENT  / 10

IDENT => shift 41

-----

State 20:

23 : Atomic -> LPAREN RPAREN .  / 4

PRED => reduce 23
IDENT => reduce 23
NUM => reduce 23
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
22 : Atomic -> LPAREN Syn . RPAREN  / 4

RPAREN => shift 42
COLON => shift 28
COMMA => shift 27
STAR => shift 31
LARROW => shift 30
RARROW => shift 33
LLOLLI => shift 32
RLOLLI => shift 26
UNIFY => shift 25
DIFFER => shift 24

-----

State 22:

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
17 : Syn -> DOLLAR Syn .  / 10

RBRACE => reduce 17
RPAREN => reduce 17
PERIOD => reduce 17
COLON => reduce 17, shift 28  PRECEDENCE
COMMA => reduce 17, shift 27  PRECEDENCE
STAR => reduce 17, shift 31  PRECEDENCE
LARROW => reduce 17, shift 30  PRECEDENCE
RARROW => reduce 17, shift 33  PRECEDENCE
LLOLLI => reduce 17, shift 32  PRECEDENCE
RLOLLI => reduce 17, shift 26  PRECEDENCE
UNIFY => shift 25, reduce 17  PRECEDENCE
DIFFER => shift 24, reduce 17  PRECEDENCE

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
16 : Syn -> BANG Syn .  / 10

RBRACE => reduce 16
RPAREN => reduce 16
PERIOD => reduce 16
COLON => reduce 16, shift 28  PRECEDENCE
COMMA => reduce 16, shift 27  PRECEDENCE
STAR => reduce 16, shift 31  PRECEDENCE
LARROW => reduce 16, shift 30  PRECEDENCE
RARROW => reduce 16, shift 33  PRECEDENCE
LLOLLI => reduce 16, shift 32  PRECEDENCE
RLOLLI => reduce 16, shift 26  PRECEDENCE
UNIFY => shift 25, reduce 16  PRECEDENCE
DIFFER => shift 24, reduce 16  PRECEDENCE

-----

State 24:

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
15 : Syn -> Syn DIFFER . Syn  / 10
16 : Syn -> . BANG Syn  / 10
17 : Syn -> . DOLLAR Syn  / 10
18 : Syn -> . STAGE IDENT  / 10
19 : Syn -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 43
Atomic => goto 14

-----

State 25:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . Syn COMMA Syn  / 10
14 : Syn -> . Syn UNIFY Syn  / 10
14 : Syn -> Syn UNIFY . Syn  / 10
15 : Syn -> . Syn DIFFER Syn  / 10
16 : Syn -> . BANG Syn  / 10
17 : Syn -> . DOLLAR Syn  / 10
18 : Syn -> . STAGE IDENT  / 10
19 : Syn -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 44
Atomic => goto 14

-----

State 26:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
9 : Syn -> Syn RLOLLI . Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
10 : Syn -> Syn RLOLLI .  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . Syn COMMA Syn  / 10
14 : Syn -> . Syn UNIFY Syn  / 10
15 : Syn -> . Syn DIFFER Syn  / 10
16 : Syn -> . BANG Syn  / 10
17 : Syn -> . DOLLAR Syn  / 10
18 : Syn -> . STAGE IDENT  / 10
19 : Syn -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
RBRACE => reduce 10
LPAREN => shift 7
RPAREN => reduce 10
PERIOD => reduce 10
COLON => reduce 10
COMMA => reduce 10
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
STAR => reduce 10
LARROW => reduce 10
RARROW => reduce 10
LLOLLI => reduce 10
RLOLLI => reduce 10
UNIFY => reduce 10
DIFFER => reduce 10
Syn => goto 45
Atomic => goto 14

-----

State 27:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . Syn COMMA Syn  / 10
13 : Syn -> Syn COMMA . Syn  / 10
14 : Syn -> . Syn UNIFY Syn  / 10
15 : Syn -> . Syn DIFFER Syn  / 10
16 : Syn -> . BANG Syn  / 10
17 : Syn -> . DOLLAR Syn  / 10
18 : Syn -> . STAGE IDENT  / 10
19 : Syn -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 46
Atomic => goto 14

-----

State 28:

6 : Syn -> . Syn COLON Syn  / 10
6 : Syn -> Syn COLON . Syn  / 10
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
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 47
Atomic => goto 14

-----

State 29:

0 : Top -> Syn PERIOD .  / 5

$ => reduce 0
PRED => reduce 0
STAGE => reduce 0
CONTEXT => reduce 0
IDENT => reduce 0
NUM => reduce 0
HASHDENT => reduce 0
RBRACE => reduce 0
LPAREN => reduce 0
USCORE => reduce 0
DOLLAR => reduce 0
BANG => reduce 0

-----

State 30:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
8 : Syn -> Syn LARROW . Syn  / 10
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
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 48
Atomic => goto 14

-----

State 31:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
12 : Syn -> Syn STAR . Syn  / 10
13 : Syn -> . Syn COMMA Syn  / 10
14 : Syn -> . Syn UNIFY Syn  / 10
15 : Syn -> . Syn DIFFER Syn  / 10
16 : Syn -> . BANG Syn  / 10
17 : Syn -> . DOLLAR Syn  / 10
18 : Syn -> . STAGE IDENT  / 10
19 : Syn -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 49
Atomic => goto 14

-----

State 32:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
7 : Syn -> Syn LLOLLI . Syn  / 10
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
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 50
Atomic => goto 14

-----

State 33:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
11 : Syn -> Syn RARROW . Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . Syn COMMA Syn  / 10
14 : Syn -> . Syn UNIFY Syn  / 10
15 : Syn -> . Syn DIFFER Syn  / 10
16 : Syn -> . BANG Syn  / 10
17 : Syn -> . DOLLAR Syn  / 10
18 : Syn -> . STAGE IDENT  / 10
19 : Syn -> . Atomic Atomics  / 10
22 : Atomic -> . LPAREN Syn RPAREN  / 4
23 : Atomic -> . LPAREN RPAREN  / 4
24 : Atomic -> . IDENT  / 4
25 : Atomic -> . USCORE  / 4
26 : Atomic -> . PRED  / 4
27 : Atomic -> . NUM  / 4

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 51
Atomic => goto 14

-----

State 34:

5 : Tops -> Top Tops .  / 11

$ => reduce 5
RBRACE => reduce 5

-----

State 35:

19 : Syn -> Atomic Atomics .  / 10

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

State 36:

29 : OpEquals -> EQUALS .  / 12

LBRACE => reduce 29

-----

State 37:

1 : Top -> STAGE IDENT OpEquals . LBRACE Tops RBRACE OpPeriod  / 5

LBRACE => shift 52

-----

State 38:

2 : Top -> CONTEXT IDENT OpEquals . LBRACE Syn RBRACE OpPeriod  / 5

LBRACE => shift 53

-----

State 39:

3 : Top -> HASHDENT Atomics PERIOD .  / 5

$ => reduce 3
PRED => reduce 3
STAGE => reduce 3
CONTEXT => reduce 3
IDENT => reduce 3
NUM => reduce 3
HASHDENT => reduce 3
RBRACE => reduce 3
LPAREN => reduce 3
USCORE => reduce 3
DOLLAR => reduce 3
BANG => reduce 3

-----

State 40:

21 : Atomics -> Atomic Atomics .  / 10

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

State 41:

18 : Syn -> STAGE IDENT .  / 10

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

State 42:

22 : Atomic -> LPAREN Syn RPAREN .  / 4

PRED => reduce 22
IDENT => reduce 22
NUM => reduce 22
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

State 43:

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
15 : Syn -> Syn DIFFER Syn .  / 10

RBRACE => reduce 15
RPAREN => reduce 15
PERIOD => reduce 15
COLON => reduce 15, shift 28  PRECEDENCE
COMMA => reduce 15, shift 27  PRECEDENCE
STAR => reduce 15, shift 31  PRECEDENCE
LARROW => reduce 15, shift 30  PRECEDENCE
RARROW => reduce 15, shift 33  PRECEDENCE
LLOLLI => reduce 15, shift 32  PRECEDENCE
RLOLLI => reduce 15, shift 26  PRECEDENCE
UNIFY => shift 25, reduce 15  PRECEDENCE
DIFFER => shift 24, reduce 15  PRECEDENCE

-----

State 44:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
13 : Syn -> Syn . COMMA Syn  / 10
14 : Syn -> Syn . UNIFY Syn  / 10
14 : Syn -> Syn UNIFY Syn .  / 10
15 : Syn -> Syn . DIFFER Syn  / 10

RBRACE => reduce 14
RPAREN => reduce 14
PERIOD => reduce 14
COLON => reduce 14, shift 28  PRECEDENCE
COMMA => reduce 14, shift 27  PRECEDENCE
STAR => reduce 14, shift 31  PRECEDENCE
LARROW => reduce 14, shift 30  PRECEDENCE
RARROW => reduce 14, shift 33  PRECEDENCE
LLOLLI => reduce 14, shift 32  PRECEDENCE
RLOLLI => reduce 14, shift 26  PRECEDENCE
UNIFY => shift 25, reduce 14  PRECEDENCE
DIFFER => shift 24, reduce 14  PRECEDENCE

-----

State 45:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
9 : Syn -> Syn RLOLLI Syn .  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
13 : Syn -> Syn . COMMA Syn  / 10
14 : Syn -> Syn . UNIFY Syn  / 10
15 : Syn -> Syn . DIFFER Syn  / 10

RBRACE => reduce 9
RPAREN => reduce 9
PERIOD => reduce 9
COLON => reduce 9, shift 28  PRECEDENCE
COMMA => reduce 9, shift 27  PRECEDENCE
STAR => shift 31, reduce 9  PRECEDENCE
LARROW => reduce 9, shift 30  PRECEDENCE
RARROW => shift 33, reduce 9  PRECEDENCE
LLOLLI => reduce 9, shift 32  PRECEDENCE
RLOLLI => shift 26, reduce 9  PRECEDENCE
UNIFY => shift 25, reduce 9  PRECEDENCE
DIFFER => shift 24, reduce 9  PRECEDENCE

-----

State 46:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
13 : Syn -> Syn . COMMA Syn  / 10
13 : Syn -> Syn COMMA Syn .  / 10
14 : Syn -> Syn . UNIFY Syn  / 10
15 : Syn -> Syn . DIFFER Syn  / 10

RBRACE => reduce 13
RPAREN => reduce 13
PERIOD => reduce 13
COLON => shift 28, reduce 13  PRECEDENCE
COMMA => shift 27, reduce 13  PRECEDENCE
STAR => shift 31, reduce 13  PRECEDENCE
LARROW => shift 30, reduce 13  PRECEDENCE
RARROW => shift 33, reduce 13  PRECEDENCE
LLOLLI => shift 32, reduce 13  PRECEDENCE
RLOLLI => shift 26, reduce 13  PRECEDENCE
UNIFY => shift 25, reduce 13  PRECEDENCE
DIFFER => shift 24, reduce 13  PRECEDENCE

-----

State 47:

6 : Syn -> Syn . COLON Syn  / 10
6 : Syn -> Syn COLON Syn .  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
13 : Syn -> Syn . COMMA Syn  / 10
14 : Syn -> Syn . UNIFY Syn  / 10
15 : Syn -> Syn . DIFFER Syn  / 10

RBRACE => reduce 6
RPAREN => reduce 6
PERIOD => reduce 6
COLON => shift 28, reduce 6  PRECEDENCE
COMMA => reduce 6, shift 27  PRECEDENCE
STAR => shift 31, reduce 6  PRECEDENCE
LARROW => shift 30, reduce 6  PRECEDENCE
RARROW => shift 33, reduce 6  PRECEDENCE
LLOLLI => shift 32, reduce 6  PRECEDENCE
RLOLLI => shift 26, reduce 6  PRECEDENCE
UNIFY => shift 25, reduce 6  PRECEDENCE
DIFFER => shift 24, reduce 6  PRECEDENCE

-----

State 48:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
8 : Syn -> Syn LARROW Syn .  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
13 : Syn -> Syn . COMMA Syn  / 10
14 : Syn -> Syn . UNIFY Syn  / 10
15 : Syn -> Syn . DIFFER Syn  / 10

RBRACE => reduce 8
RPAREN => reduce 8
PERIOD => reduce 8
COLON => reduce 8, shift 28  PRECEDENCE
COMMA => reduce 8, shift 27  PRECEDENCE
STAR => shift 31, reduce 8  PRECEDENCE
LARROW => reduce 8, shift 30  PRECEDENCE
RARROW => shift 33, reduce 8  PRECEDENCE
LLOLLI => reduce 8, shift 32  PRECEDENCE
RLOLLI => shift 26, reduce 8  PRECEDENCE
UNIFY => shift 25, reduce 8  PRECEDENCE
DIFFER => shift 24, reduce 8  PRECEDENCE

-----

State 49:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
12 : Syn -> Syn STAR Syn .  / 10
13 : Syn -> Syn . COMMA Syn  / 10
14 : Syn -> Syn . UNIFY Syn  / 10
15 : Syn -> Syn . DIFFER Syn  / 10

RBRACE => reduce 12
RPAREN => reduce 12
PERIOD => reduce 12
COLON => reduce 12, shift 28  PRECEDENCE
COMMA => reduce 12, shift 27  PRECEDENCE
STAR => shift 31, reduce 12  PRECEDENCE
LARROW => reduce 12, shift 30  PRECEDENCE
RARROW => reduce 12, shift 33  PRECEDENCE
LLOLLI => reduce 12, shift 32  PRECEDENCE
RLOLLI => reduce 12, shift 26  PRECEDENCE
UNIFY => shift 25, reduce 12  PRECEDENCE
DIFFER => shift 24, reduce 12  PRECEDENCE

-----

State 50:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
7 : Syn -> Syn LLOLLI Syn .  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
13 : Syn -> Syn . COMMA Syn  / 10
14 : Syn -> Syn . UNIFY Syn  / 10
15 : Syn -> Syn . DIFFER Syn  / 10

RBRACE => reduce 7
RPAREN => reduce 7
PERIOD => reduce 7
COLON => reduce 7, shift 28  PRECEDENCE
COMMA => reduce 7, shift 27  PRECEDENCE
STAR => shift 31, reduce 7  PRECEDENCE
LARROW => reduce 7, shift 30  PRECEDENCE
RARROW => shift 33, reduce 7  PRECEDENCE
LLOLLI => reduce 7, shift 32  PRECEDENCE
RLOLLI => shift 26, reduce 7  PRECEDENCE
UNIFY => shift 25, reduce 7  PRECEDENCE
DIFFER => shift 24, reduce 7  PRECEDENCE

-----

State 51:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
11 : Syn -> Syn RARROW Syn .  / 10
12 : Syn -> Syn . STAR Syn  / 10
13 : Syn -> Syn . COMMA Syn  / 10
14 : Syn -> Syn . UNIFY Syn  / 10
15 : Syn -> Syn . DIFFER Syn  / 10

RBRACE => reduce 11
RPAREN => reduce 11
PERIOD => reduce 11
COLON => reduce 11, shift 28  PRECEDENCE
COMMA => reduce 11, shift 27  PRECEDENCE
STAR => shift 31, reduce 11  PRECEDENCE
LARROW => reduce 11, shift 30  PRECEDENCE
RARROW => shift 33, reduce 11  PRECEDENCE
LLOLLI => reduce 11, shift 32  PRECEDENCE
RLOLLI => shift 26, reduce 11  PRECEDENCE
UNIFY => shift 25, reduce 11  PRECEDENCE
DIFFER => shift 24, reduce 11  PRECEDENCE

-----

State 52:

0 : Top -> . Syn PERIOD  / 13
1 : Top -> . STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 13
1 : Top -> STAGE IDENT OpEquals LBRACE . Tops RBRACE OpPeriod  / 5
2 : Top -> . CONTEXT IDENT OpEquals LBRACE Syn RBRACE OpPeriod  / 13
3 : Top -> . HASHDENT Atomics PERIOD  / 13
4 : Tops -> .  / 14
5 : Tops -> . Top Tops  / 14
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
23 : Atomic -> . LPAREN RPAREN  / 3
24 : Atomic -> . IDENT  / 3
25 : Atomic -> . USCORE  / 3
26 : Atomic -> . PRED  / 3
27 : Atomic -> . NUM  / 3

PRED => shift 2
STAGE => shift 3
CONTEXT => shift 5
IDENT => shift 4
NUM => shift 1
HASHDENT => shift 6
RBRACE => reduce 4
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Tops => goto 54
Top => goto 13
Syn => goto 11
Atomic => goto 14

-----

State 53:

2 : Top -> CONTEXT IDENT OpEquals LBRACE . Syn RBRACE OpPeriod  / 5
6 : Syn -> . Syn COLON Syn  / 15
7 : Syn -> . Syn LLOLLI Syn  / 15
8 : Syn -> . Syn LARROW Syn  / 15
9 : Syn -> . Syn RLOLLI Syn  / 15
10 : Syn -> . Syn RLOLLI  / 15
11 : Syn -> . Syn RARROW Syn  / 15
12 : Syn -> . Syn STAR Syn  / 15
13 : Syn -> . Syn COMMA Syn  / 15
14 : Syn -> . Syn UNIFY Syn  / 15
15 : Syn -> . Syn DIFFER Syn  / 15
16 : Syn -> . BANG Syn  / 15
17 : Syn -> . DOLLAR Syn  / 15
18 : Syn -> . STAGE IDENT  / 15
19 : Syn -> . Atomic Atomics  / 15
22 : Atomic -> . LPAREN Syn RPAREN  / 16
23 : Atomic -> . LPAREN RPAREN  / 16
24 : Atomic -> . IDENT  / 16
25 : Atomic -> . USCORE  / 16
26 : Atomic -> . PRED  / 16
27 : Atomic -> . NUM  / 16

PRED => shift 2
STAGE => shift 19
IDENT => shift 4
NUM => shift 1
LPAREN => shift 7
USCORE => shift 8
DOLLAR => shift 9
BANG => shift 10
Syn => goto 55
Atomic => goto 14

-----

State 54:

1 : Top -> STAGE IDENT OpEquals LBRACE Tops . RBRACE OpPeriod  / 5

RBRACE => shift 56

-----

State 55:

2 : Top -> CONTEXT IDENT OpEquals LBRACE Syn . RBRACE OpPeriod  / 5
6 : Syn -> Syn . COLON Syn  / 15
7 : Syn -> Syn . LLOLLI Syn  / 15
8 : Syn -> Syn . LARROW Syn  / 15
9 : Syn -> Syn . RLOLLI Syn  / 15
10 : Syn -> Syn . RLOLLI  / 15
11 : Syn -> Syn . RARROW Syn  / 15
12 : Syn -> Syn . STAR Syn  / 15
13 : Syn -> Syn . COMMA Syn  / 15
14 : Syn -> Syn . UNIFY Syn  / 15
15 : Syn -> Syn . DIFFER Syn  / 15

RBRACE => shift 57
COLON => shift 28
COMMA => shift 27
STAR => shift 31
LARROW => shift 30
RARROW => shift 33
LLOLLI => shift 32
RLOLLI => shift 26
UNIFY => shift 25
DIFFER => shift 24

-----

State 56:

1 : Top -> STAGE IDENT OpEquals LBRACE Tops RBRACE . OpPeriod  / 5
30 : OpPeriod -> .  / 5
31 : OpPeriod -> . PERIOD  / 5

$ => reduce 30
PRED => reduce 30
STAGE => reduce 30
CONTEXT => reduce 30
IDENT => reduce 30
NUM => reduce 30
HASHDENT => reduce 30
RBRACE => reduce 30
LPAREN => reduce 30
PERIOD => shift 58
USCORE => reduce 30
DOLLAR => reduce 30
BANG => reduce 30
OpPeriod => goto 59

-----

State 57:

2 : Top -> CONTEXT IDENT OpEquals LBRACE Syn RBRACE . OpPeriod  / 5
30 : OpPeriod -> .  / 5
31 : OpPeriod -> . PERIOD  / 5

$ => reduce 30
PRED => reduce 30
STAGE => reduce 30
CONTEXT => reduce 30
IDENT => reduce 30
NUM => reduce 30
HASHDENT => reduce 30
RBRACE => reduce 30
LPAREN => reduce 30
PERIOD => shift 58
USCORE => reduce 30
DOLLAR => reduce 30
BANG => reduce 30
OpPeriod => goto 60

-----

State 58:

31 : OpPeriod -> PERIOD .  / 5

$ => reduce 31
PRED => reduce 31
STAGE => reduce 31
CONTEXT => reduce 31
IDENT => reduce 31
NUM => reduce 31
HASHDENT => reduce 31
RBRACE => reduce 31
LPAREN => reduce 31
USCORE => reduce 31
DOLLAR => reduce 31
BANG => reduce 31

-----

State 59:

1 : Top -> STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod .  / 5

$ => reduce 1
PRED => reduce 1
STAGE => reduce 1
CONTEXT => reduce 1
IDENT => reduce 1
NUM => reduce 1
HASHDENT => reduce 1
RBRACE => reduce 1
LPAREN => reduce 1
USCORE => reduce 1
DOLLAR => reduce 1
BANG => reduce 1

-----

State 60:

2 : Top -> CONTEXT IDENT OpEquals LBRACE Syn RBRACE OpPeriod .  / 5

$ => reduce 2
PRED => reduce 2
STAGE => reduce 2
CONTEXT => reduce 2
IDENT => reduce 2
NUM => reduce 2
HASHDENT => reduce 2
RBRACE => reduce 2
LPAREN => reduce 2
USCORE => reduce 2
DOLLAR => reduce 2
BANG => reduce 2

-----

lookahead 0 = $ 
lookahead 1 = $ PRED STAGE CONTEXT IDENT NUM HASHDENT LPAREN USCORE DOLLAR BANG 
lookahead 2 = PERIOD COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 3 = PRED IDENT NUM LPAREN PERIOD COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 4 = PRED IDENT NUM RBRACE LPAREN RPAREN PERIOD COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 5 = $ PRED STAGE CONTEXT IDENT NUM HASHDENT RBRACE LPAREN USCORE DOLLAR BANG 
lookahead 6 = PERIOD 
lookahead 7 = PRED IDENT NUM LPAREN PERIOD USCORE 
lookahead 8 = RPAREN COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 9 = PRED IDENT NUM LPAREN RPAREN COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 10 = RBRACE RPAREN PERIOD COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 11 = $ RBRACE 
lookahead 12 = LBRACE 
lookahead 13 = PRED STAGE CONTEXT IDENT NUM HASHDENT RBRACE LPAREN USCORE DOLLAR BANG 
lookahead 14 = RBRACE 
lookahead 15 = RBRACE COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 
lookahead 16 = PRED IDENT NUM RBRACE LPAREN COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI UNIFY DIFFER 

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
ParseEngine.next5x1 "z\131\132\134\133\130\135\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128c\128\128cc\128\128cccccc\128c\128\128ccccccc\128\128\128\128\128\128\128\128d\128\128dd\128\128dddddd\128d\128\128ddddddd\128\128\128\128\128\128\128\128\128\128\128\144\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128f\128\128ff\128\128ffffff\128f\128\128fffffff\128\128\128\128\128\128\128\128\128\128\128\145\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\128\128\133\130\128\128\128\136\128j\128\128\128\137\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\149\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128e\128\128ee\128\128eeeeee\128e\128\128eeeeeee\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\158\157\156\128\128\128\128\160\159\162\161\155\154\153\128\128\128\128\128\128\128\127\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128z\131\132\134\133\130\135\128z\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\128\128\133\130\128\128j\136jjjj\128\137\128\128jjjjjjj\128\128\128\128\128\128\128\128\128\128\128\128\128\128b\128\128\128lll\165\128\128\128lllllll\128\128\128\128\128\128\128\128\128\128\128\128\128\128b\128\128\128\128\128\128\165\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\168\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\128\128\133\130\128\128j\136jjjj\128\137\128\128jjjjjjj\128\128\128\128\128\128\128\128\128\128\128\170\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128g\128\128gg\128\128gggggg\128g\128\128ggggggg\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\171\128\157\156\128\128\128\128\160\159\162\161\155\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128m\128mmmm\128\128\128\128mmmmm\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128n\128nnnn\128\128\128\128nnnnn\154\153\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128t\136tttt\128\137\138\139ttttttt\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128~~~~~~~\128~~\128\128\128\128\128~~~\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128y\128\128\128\128\128\128\128y\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128k\128kkkk\128\128\128\128kkkkkkk\128\128\128\128\128\128\128\128\128\128\128\128\128\128a\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\181\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\182\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128{{{{{{{\128{{\128\128\128\128\128{{{\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128i\128iiii\128\128\128\128iiiiiii\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128l\128llll\128\128\128\128lllllll\128\128\128\128\128\128\128\128h\128\128hh\128\128hhhhhh\128h\128\128hhhhhhh\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128o\128oooo\128\128\128\128ooooo\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128p\128pppp\128\128\128\128ppppp\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128u\128uuuu\128\128\128\128\160u\162u\155\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128q\128qq\157\156\128\128\128\128\160\159\162\161\155\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128x\128xx\157x\128\128\128\128\160\159\162\161\155\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128v\128vvvv\128\128\128\128\160v\162v\155\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128r\128rrrr\128\128\128\128\160rrrr\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128w\128wwww\128\128\128\128\160w\162w\155\154\153\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128s\128ssss\128\128\128\128\160s\162s\155\154\153\128\128\128\128\128\128\128\128\131\132\134\133\130\135\128z\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\131\148\128\133\130\128\128\128\136\128\128\128\128\128\137\138\139\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\185\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\186\128\128\128\157\156\128\128\128\128\160\159\162\161\155\154\153\128\128\128\128\128\128\128```````\128``\128\187\128\128\128```\128\128\128\128\128\128\128\128\128\128\128\128\128\128```````\128``\128\187\128\128\128```\128\128\128\128\128\128\128\128\128\128\128\128\128\128_______\128__\128\128\128\128\128___\128\128\128\128\128\128\128\128\128\128\128\128\128\128}}}}}}}\128}}\128\128\128\128\128}}}\128\128\128\128\128\128\128\128\128\128\128\128\128\128|||||||\128||\128\128\128\128\128|||\128\128\128\128\128\128\128\128\128\128\128\128\128\128",
ParseEngine.next5x1 "\140\141\139\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\145\146\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\149\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\150\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\151\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\162\141\139\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\163\146\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\165\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\166\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\168\146\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\171\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\172\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\173\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\174\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\175\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\176\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\177\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\178\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\179\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\182\141\139\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\183\128\128\128\142\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\187\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\188\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128",
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
(2,2,(fn Value.syns(arg0)::Value.syn(arg1)::rest => Value.syn(Arg.App {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(5,0,(fn rest => Value.syns(Arg.Nil {})::rest)),
(5,2,(fn Value.syns(arg0)::Value.syn(arg1)::rest => Value.syns(Arg.Cons {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(6,3,(fn _::Value.syn(arg0)::_::rest => Value.syn(Arg.parens arg0)::rest|_=>raise (Fail "bad parser"))),
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
