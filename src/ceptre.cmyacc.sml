
functor ParseFn
   (structure Streamable : STREAMABLE
    structure Arg :
       sig
          type string
          type top
          type tops
          type syn
          type syns
          type ign

          val Ign : unit -> ign
          val Single : syn -> syns
          val Pred : unit -> syn
          val Wild : unit -> syn
          val Id : string -> syn
          val parens : syn -> syn
          val Cons : syn * syns -> syns
          val Nil : unit -> syns
          val App : syn * syns -> syn
          val StagePred : string -> syn
          val Dollar : syn -> syn
          val Bang : syn -> syn
          val Star : syn * syn -> syn
          val Arrow : syn * syn -> syn
          val LolliNONE : syn -> syn
          val LolliSOME : syn * syn -> syn
          val ArrowL : syn * syn -> syn
          val LolliL : syn * syn -> syn
          val Ascribe : syn * syn -> syn
          val ConsT : top * tops -> tops
          val NilT : unit -> tops
          val Special : string * syns -> top
          val Context : string * syns -> top
          val Stage : string * tops -> top
          val Decl : syn -> top

          datatype terminal =
             PRED
           | STAGE
           | CONTEXT
           | IDENT of string
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
2 : Top -> . CONTEXT IDENT OpEquals LBRACE Syncommas RBRACE OpPeriod  / 1
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
13 : Syn -> . BANG Syn  / 2
14 : Syn -> . DOLLAR Syn  / 2
15 : Syn -> . STAGE IDENT  / 2
16 : Syn -> . Atomic Atomics  / 2
19 : Atomic -> . LPAREN Syn RPAREN  / 3
20 : Atomic -> . IDENT  / 3
21 : Atomic -> . USCORE  / 3
22 : Atomic -> . PRED  / 3

$ => reduce 4
PRED => shift 1
STAGE => shift 2
CONTEXT => shift 4
IDENT => shift 5
HASHDENT => shift 6
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Tops => goto 11
Top => goto 12
Syn => goto 10
Atomic => goto 13

-----

State 1:

22 : Atomic -> PRED .  / 4

PRED => reduce 22
IDENT => reduce 22
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

-----

State 2:

1 : Top -> STAGE . IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 5
15 : Syn -> STAGE . IDENT  / 2

IDENT => shift 14

-----

State 3:

6 : Syn -> . Syn COLON Syn  / 6
7 : Syn -> . Syn LLOLLI Syn  / 6
8 : Syn -> . Syn LARROW Syn  / 6
9 : Syn -> . Syn RLOLLI Syn  / 6
10 : Syn -> . Syn RLOLLI  / 6
11 : Syn -> . Syn RARROW Syn  / 6
12 : Syn -> . Syn STAR Syn  / 6
13 : Syn -> . BANG Syn  / 6
14 : Syn -> . DOLLAR Syn  / 6
15 : Syn -> . STAGE IDENT  / 6
16 : Syn -> . Atomic Atomics  / 6
19 : Atomic -> . LPAREN Syn RPAREN  / 7
19 : Atomic -> LPAREN . Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 7
21 : Atomic -> . USCORE  / 7
22 : Atomic -> . PRED  / 7

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 16
Atomic => goto 13

-----

State 4:

2 : Top -> CONTEXT . IDENT OpEquals LBRACE Syncommas RBRACE OpPeriod  / 5

IDENT => shift 17

-----

State 5:

20 : Atomic -> IDENT .  / 4

PRED => reduce 20
IDENT => reduce 20
RBRACE => reduce 20
LPAREN => reduce 20
RPAREN => reduce 20
PERIOD => reduce 20
COLON => reduce 20
COMMA => reduce 20
USCORE => reduce 20
STAR => reduce 20
LARROW => reduce 20
RARROW => reduce 20
LLOLLI => reduce 20
RLOLLI => reduce 20

-----

State 6:

3 : Top -> HASHDENT . Atomics PERIOD  / 5
17 : Atomics -> .  / 8
18 : Atomics -> . Atomic Atomics  / 8
19 : Atomic -> . LPAREN Syn RPAREN  / 9
20 : Atomic -> . IDENT  / 9
21 : Atomic -> . USCORE  / 9
22 : Atomic -> . PRED  / 9

PRED => shift 1
IDENT => shift 5
LPAREN => shift 3
PERIOD => reduce 17
USCORE => shift 7
Atomics => goto 18
Atomic => goto 19

-----

State 7:

21 : Atomic -> USCORE .  / 4

PRED => reduce 21
IDENT => reduce 21
RBRACE => reduce 21
LPAREN => reduce 21
RPAREN => reduce 21
PERIOD => reduce 21
COLON => reduce 21
COMMA => reduce 21
USCORE => reduce 21
STAR => reduce 21
LARROW => reduce 21
RARROW => reduce 21
LLOLLI => reduce 21
RLOLLI => reduce 21

-----

State 8:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . BANG Syn  / 10
14 : Syn -> . DOLLAR Syn  / 10
14 : Syn -> DOLLAR . Syn  / 10
15 : Syn -> . STAGE IDENT  / 10
16 : Syn -> . Atomic Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 20
Atomic => goto 13

-----

State 9:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . BANG Syn  / 10
13 : Syn -> BANG . Syn  / 10
14 : Syn -> . DOLLAR Syn  / 10
15 : Syn -> . STAGE IDENT  / 10
16 : Syn -> . Atomic Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 21
Atomic => goto 13

-----

State 10:

0 : Top -> Syn . PERIOD  / 5
6 : Syn -> Syn . COLON Syn  / 2
7 : Syn -> Syn . LLOLLI Syn  / 2
8 : Syn -> Syn . LARROW Syn  / 2
9 : Syn -> Syn . RLOLLI Syn  / 2
10 : Syn -> Syn . RLOLLI  / 2
11 : Syn -> Syn . RARROW Syn  / 2
12 : Syn -> Syn . STAR Syn  / 2

PERIOD => shift 24
COLON => shift 23
STAR => shift 22
LARROW => shift 25
RARROW => shift 26
LLOLLI => shift 27
RLOLLI => shift 28

-----

State 11:

start -> Tops .  / 0

$ => accept

-----

State 12:

0 : Top -> . Syn PERIOD  / 5
1 : Top -> . STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 5
2 : Top -> . CONTEXT IDENT OpEquals LBRACE Syncommas RBRACE OpPeriod  / 5
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
13 : Syn -> . BANG Syn  / 2
14 : Syn -> . DOLLAR Syn  / 2
15 : Syn -> . STAGE IDENT  / 2
16 : Syn -> . Atomic Atomics  / 2
19 : Atomic -> . LPAREN Syn RPAREN  / 3
20 : Atomic -> . IDENT  / 3
21 : Atomic -> . USCORE  / 3
22 : Atomic -> . PRED  / 3

$ => reduce 4
PRED => shift 1
STAGE => shift 2
CONTEXT => shift 4
IDENT => shift 5
HASHDENT => shift 6
RBRACE => reduce 4
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Tops => goto 29
Top => goto 12
Syn => goto 10
Atomic => goto 13

-----

State 13:

16 : Syn -> Atomic . Atomics  / 10
17 : Atomics -> .  / 10
18 : Atomics -> . Atomic Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
IDENT => shift 5
RBRACE => reduce 17
LPAREN => shift 3
RPAREN => reduce 17
PERIOD => reduce 17
COLON => reduce 17
COMMA => reduce 17
USCORE => shift 7
STAR => reduce 17
LARROW => reduce 17
RARROW => reduce 17
LLOLLI => reduce 17
RLOLLI => reduce 17
Atomics => goto 30
Atomic => goto 19

-----

State 14:

1 : Top -> STAGE IDENT . OpEquals LBRACE Tops RBRACE OpPeriod  / 5
15 : Syn -> STAGE IDENT .  / 2
26 : OpEquals -> .  / 12
27 : OpEquals -> . EQUALS  / 12

LBRACE => reduce 26
PERIOD => reduce 15
COLON => reduce 15
EQUALS => shift 31
STAR => reduce 15
LARROW => reduce 15
RARROW => reduce 15
LLOLLI => reduce 15
RLOLLI => reduce 15
OpEquals => goto 32

-----

State 15:

15 : Syn -> STAGE . IDENT  / 10

IDENT => shift 33

-----

State 16:

6 : Syn -> Syn . COLON Syn  / 6
7 : Syn -> Syn . LLOLLI Syn  / 6
8 : Syn -> Syn . LARROW Syn  / 6
9 : Syn -> Syn . RLOLLI Syn  / 6
10 : Syn -> Syn . RLOLLI  / 6
11 : Syn -> Syn . RARROW Syn  / 6
12 : Syn -> Syn . STAR Syn  / 6
19 : Atomic -> LPAREN Syn . RPAREN  / 4

RPAREN => shift 34
COLON => shift 23
STAR => shift 22
LARROW => shift 25
RARROW => shift 26
LLOLLI => shift 27
RLOLLI => shift 28

-----

State 17:

2 : Top -> CONTEXT IDENT . OpEquals LBRACE Syncommas RBRACE OpPeriod  / 5
26 : OpEquals -> .  / 12
27 : OpEquals -> . EQUALS  / 12

LBRACE => reduce 26
EQUALS => shift 31
OpEquals => goto 35

-----

State 18:

3 : Top -> HASHDENT Atomics . PERIOD  / 5

PERIOD => shift 36

-----

State 19:

17 : Atomics -> .  / 10
18 : Atomics -> . Atomic Atomics  / 10
18 : Atomics -> Atomic . Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
IDENT => shift 5
RBRACE => reduce 17
LPAREN => shift 3
RPAREN => reduce 17
PERIOD => reduce 17
COLON => reduce 17
COMMA => reduce 17
USCORE => shift 7
STAR => reduce 17
LARROW => reduce 17
RARROW => reduce 17
LLOLLI => reduce 17
RLOLLI => reduce 17
Atomics => goto 37
Atomic => goto 19

-----

State 20:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
14 : Syn -> DOLLAR Syn .  / 10

RBRACE => reduce 14
RPAREN => reduce 14
PERIOD => reduce 14
COLON => reduce 14, shift 23  PRECEDENCE
COMMA => reduce 14
STAR => reduce 14, shift 22  PRECEDENCE
LARROW => reduce 14, shift 25  PRECEDENCE
RARROW => reduce 14, shift 26  PRECEDENCE
LLOLLI => reduce 14, shift 27  PRECEDENCE
RLOLLI => reduce 14, shift 28  PRECEDENCE

-----

State 21:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
13 : Syn -> BANG Syn .  / 10

RBRACE => reduce 13
RPAREN => reduce 13
PERIOD => reduce 13
COLON => reduce 13, shift 23  PRECEDENCE
COMMA => reduce 13
STAR => reduce 13, shift 22  PRECEDENCE
LARROW => reduce 13, shift 25  PRECEDENCE
RARROW => reduce 13, shift 26  PRECEDENCE
LLOLLI => reduce 13, shift 27  PRECEDENCE
RLOLLI => reduce 13, shift 28  PRECEDENCE

-----

State 22:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
12 : Syn -> Syn STAR . Syn  / 10
13 : Syn -> . BANG Syn  / 10
14 : Syn -> . DOLLAR Syn  / 10
15 : Syn -> . STAGE IDENT  / 10
16 : Syn -> . Atomic Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 38
Atomic => goto 13

-----

State 23:

6 : Syn -> . Syn COLON Syn  / 10
6 : Syn -> Syn COLON . Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . BANG Syn  / 10
14 : Syn -> . DOLLAR Syn  / 10
15 : Syn -> . STAGE IDENT  / 10
16 : Syn -> . Atomic Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 39
Atomic => goto 13

-----

State 24:

0 : Top -> Syn PERIOD .  / 5

$ => reduce 0
PRED => reduce 0
STAGE => reduce 0
CONTEXT => reduce 0
IDENT => reduce 0
HASHDENT => reduce 0
RBRACE => reduce 0
LPAREN => reduce 0
USCORE => reduce 0
DOLLAR => reduce 0
BANG => reduce 0

-----

State 25:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
8 : Syn -> Syn LARROW . Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . BANG Syn  / 10
14 : Syn -> . DOLLAR Syn  / 10
15 : Syn -> . STAGE IDENT  / 10
16 : Syn -> . Atomic Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 40
Atomic => goto 13

-----

State 26:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
11 : Syn -> Syn RARROW . Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . BANG Syn  / 10
14 : Syn -> . DOLLAR Syn  / 10
15 : Syn -> . STAGE IDENT  / 10
16 : Syn -> . Atomic Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 41
Atomic => goto 13

-----

State 27:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
7 : Syn -> Syn LLOLLI . Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . BANG Syn  / 10
14 : Syn -> . DOLLAR Syn  / 10
15 : Syn -> . STAGE IDENT  / 10
16 : Syn -> . Atomic Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 42
Atomic => goto 13

-----

State 28:

6 : Syn -> . Syn COLON Syn  / 10
7 : Syn -> . Syn LLOLLI Syn  / 10
8 : Syn -> . Syn LARROW Syn  / 10
9 : Syn -> . Syn RLOLLI Syn  / 10
9 : Syn -> Syn RLOLLI . Syn  / 10
10 : Syn -> . Syn RLOLLI  / 10
10 : Syn -> Syn RLOLLI .  / 10
11 : Syn -> . Syn RARROW Syn  / 10
12 : Syn -> . Syn STAR Syn  / 10
13 : Syn -> . BANG Syn  / 10
14 : Syn -> . DOLLAR Syn  / 10
15 : Syn -> . STAGE IDENT  / 10
16 : Syn -> . Atomic Atomics  / 10
19 : Atomic -> . LPAREN Syn RPAREN  / 4
20 : Atomic -> . IDENT  / 4
21 : Atomic -> . USCORE  / 4
22 : Atomic -> . PRED  / 4

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
RBRACE => reduce 10
LPAREN => shift 3
RPAREN => reduce 10
PERIOD => reduce 10
COLON => reduce 10
COMMA => reduce 10
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
STAR => reduce 10
LARROW => reduce 10
RARROW => reduce 10
LLOLLI => reduce 10
RLOLLI => reduce 10
Syn => goto 43
Atomic => goto 13

-----

State 29:

5 : Tops -> Top Tops .  / 11

$ => reduce 5
RBRACE => reduce 5

-----

State 30:

16 : Syn -> Atomic Atomics .  / 10

RBRACE => reduce 16
RPAREN => reduce 16
PERIOD => reduce 16
COLON => reduce 16
COMMA => reduce 16
STAR => reduce 16
LARROW => reduce 16
RARROW => reduce 16
LLOLLI => reduce 16
RLOLLI => reduce 16

-----

State 31:

27 : OpEquals -> EQUALS .  / 12

LBRACE => reduce 27

-----

State 32:

1 : Top -> STAGE IDENT OpEquals . LBRACE Tops RBRACE OpPeriod  / 5

LBRACE => shift 44

-----

State 33:

15 : Syn -> STAGE IDENT .  / 10

RBRACE => reduce 15
RPAREN => reduce 15
PERIOD => reduce 15
COLON => reduce 15
COMMA => reduce 15
STAR => reduce 15
LARROW => reduce 15
RARROW => reduce 15
LLOLLI => reduce 15
RLOLLI => reduce 15

-----

State 34:

19 : Atomic -> LPAREN Syn RPAREN .  / 4

PRED => reduce 19
IDENT => reduce 19
RBRACE => reduce 19
LPAREN => reduce 19
RPAREN => reduce 19
PERIOD => reduce 19
COLON => reduce 19
COMMA => reduce 19
USCORE => reduce 19
STAR => reduce 19
LARROW => reduce 19
RARROW => reduce 19
LLOLLI => reduce 19
RLOLLI => reduce 19

-----

State 35:

2 : Top -> CONTEXT IDENT OpEquals . LBRACE Syncommas RBRACE OpPeriod  / 5

LBRACE => shift 45

-----

State 36:

3 : Top -> HASHDENT Atomics PERIOD .  / 5

$ => reduce 3
PRED => reduce 3
STAGE => reduce 3
CONTEXT => reduce 3
IDENT => reduce 3
HASHDENT => reduce 3
RBRACE => reduce 3
LPAREN => reduce 3
USCORE => reduce 3
DOLLAR => reduce 3
BANG => reduce 3

-----

State 37:

18 : Atomics -> Atomic Atomics .  / 10

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

-----

State 38:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10
12 : Syn -> Syn STAR Syn .  / 10

RBRACE => reduce 12
RPAREN => reduce 12
PERIOD => reduce 12
COLON => reduce 12, shift 23  PRECEDENCE
COMMA => reduce 12
STAR => shift 22, reduce 12  PRECEDENCE
LARROW => reduce 12, shift 25  PRECEDENCE
RARROW => reduce 12, shift 26  PRECEDENCE
LLOLLI => reduce 12, shift 27  PRECEDENCE
RLOLLI => reduce 12, shift 28  PRECEDENCE

-----

State 39:

6 : Syn -> Syn . COLON Syn  / 10
6 : Syn -> Syn COLON Syn .  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10

RBRACE => reduce 6
RPAREN => reduce 6
PERIOD => reduce 6
COLON => shift 23, reduce 6  PRECEDENCE
COMMA => reduce 6
STAR => shift 22, reduce 6  PRECEDENCE
LARROW => shift 25, reduce 6  PRECEDENCE
RARROW => shift 26, reduce 6  PRECEDENCE
LLOLLI => shift 27, reduce 6  PRECEDENCE
RLOLLI => shift 28, reduce 6  PRECEDENCE

-----

State 40:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
8 : Syn -> Syn LARROW Syn .  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10

RBRACE => reduce 8
RPAREN => reduce 8
PERIOD => reduce 8
COLON => reduce 8, shift 23  PRECEDENCE
COMMA => reduce 8
STAR => shift 22, reduce 8  PRECEDENCE
LARROW => reduce 8, shift 25  PRECEDENCE
RARROW => shift 26, reduce 8  PRECEDENCE
LLOLLI => reduce 8, shift 27  PRECEDENCE
RLOLLI => shift 28, reduce 8  PRECEDENCE

-----

State 41:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
11 : Syn -> Syn RARROW Syn .  / 10
12 : Syn -> Syn . STAR Syn  / 10

RBRACE => reduce 11
RPAREN => reduce 11
PERIOD => reduce 11
COLON => reduce 11, shift 23  PRECEDENCE
COMMA => reduce 11
STAR => shift 22, reduce 11  PRECEDENCE
LARROW => reduce 11, shift 25  PRECEDENCE
RARROW => shift 26, reduce 11  PRECEDENCE
LLOLLI => reduce 11, shift 27  PRECEDENCE
RLOLLI => shift 28, reduce 11  PRECEDENCE

-----

State 42:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
7 : Syn -> Syn LLOLLI Syn .  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10

RBRACE => reduce 7
RPAREN => reduce 7
PERIOD => reduce 7
COLON => reduce 7, shift 23  PRECEDENCE
COMMA => reduce 7
STAR => shift 22, reduce 7  PRECEDENCE
LARROW => reduce 7, shift 25  PRECEDENCE
RARROW => shift 26, reduce 7  PRECEDENCE
LLOLLI => reduce 7, shift 27  PRECEDENCE
RLOLLI => shift 28, reduce 7  PRECEDENCE

-----

State 43:

6 : Syn -> Syn . COLON Syn  / 10
7 : Syn -> Syn . LLOLLI Syn  / 10
8 : Syn -> Syn . LARROW Syn  / 10
9 : Syn -> Syn . RLOLLI Syn  / 10
9 : Syn -> Syn RLOLLI Syn .  / 10
10 : Syn -> Syn . RLOLLI  / 10
11 : Syn -> Syn . RARROW Syn  / 10
12 : Syn -> Syn . STAR Syn  / 10

RBRACE => reduce 9
RPAREN => reduce 9
PERIOD => reduce 9
COLON => reduce 9, shift 23  PRECEDENCE
COMMA => reduce 9
STAR => shift 22, reduce 9  PRECEDENCE
LARROW => reduce 9, shift 25  PRECEDENCE
RARROW => shift 26, reduce 9  PRECEDENCE
LLOLLI => reduce 9, shift 27  PRECEDENCE
RLOLLI => shift 28, reduce 9  PRECEDENCE

-----

State 44:

0 : Top -> . Syn PERIOD  / 13
1 : Top -> . STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod  / 13
1 : Top -> STAGE IDENT OpEquals LBRACE . Tops RBRACE OpPeriod  / 5
2 : Top -> . CONTEXT IDENT OpEquals LBRACE Syncommas RBRACE OpPeriod  / 13
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
13 : Syn -> . BANG Syn  / 2
14 : Syn -> . DOLLAR Syn  / 2
15 : Syn -> . STAGE IDENT  / 2
16 : Syn -> . Atomic Atomics  / 2
19 : Atomic -> . LPAREN Syn RPAREN  / 3
20 : Atomic -> . IDENT  / 3
21 : Atomic -> . USCORE  / 3
22 : Atomic -> . PRED  / 3

PRED => shift 1
STAGE => shift 2
CONTEXT => shift 4
IDENT => shift 5
HASHDENT => shift 6
RBRACE => reduce 4
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Tops => goto 46
Top => goto 12
Syn => goto 10
Atomic => goto 13

-----

State 45:

2 : Top -> CONTEXT IDENT OpEquals LBRACE . Syncommas RBRACE OpPeriod  / 5
6 : Syn -> . Syn COLON Syn  / 15
7 : Syn -> . Syn LLOLLI Syn  / 15
8 : Syn -> . Syn LARROW Syn  / 15
9 : Syn -> . Syn RLOLLI Syn  / 15
10 : Syn -> . Syn RLOLLI  / 15
11 : Syn -> . Syn RARROW Syn  / 15
12 : Syn -> . Syn STAR Syn  / 15
13 : Syn -> . BANG Syn  / 15
14 : Syn -> . DOLLAR Syn  / 15
15 : Syn -> . STAGE IDENT  / 15
16 : Syn -> . Atomic Atomics  / 15
19 : Atomic -> . LPAREN Syn RPAREN  / 16
20 : Atomic -> . IDENT  / 16
21 : Atomic -> . USCORE  / 16
22 : Atomic -> . PRED  / 16
23 : Syncommas -> .  / 14
24 : Syncommas -> . Syn  / 14
25 : Syncommas -> . Syn COMMA Syncommas  / 14

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
RBRACE => reduce 23
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 47
Syncommas => goto 48
Atomic => goto 13

-----

State 46:

1 : Top -> STAGE IDENT OpEquals LBRACE Tops . RBRACE OpPeriod  / 5

RBRACE => shift 49

-----

State 47:

6 : Syn -> Syn . COLON Syn  / 15
7 : Syn -> Syn . LLOLLI Syn  / 15
8 : Syn -> Syn . LARROW Syn  / 15
9 : Syn -> Syn . RLOLLI Syn  / 15
10 : Syn -> Syn . RLOLLI  / 15
11 : Syn -> Syn . RARROW Syn  / 15
12 : Syn -> Syn . STAR Syn  / 15
24 : Syncommas -> Syn .  / 14
25 : Syncommas -> Syn . COMMA Syncommas  / 14

RBRACE => reduce 24
COLON => shift 23
COMMA => shift 50
STAR => shift 22
LARROW => shift 25
RARROW => shift 26
LLOLLI => shift 27
RLOLLI => shift 28

-----

State 48:

2 : Top -> CONTEXT IDENT OpEquals LBRACE Syncommas . RBRACE OpPeriod  / 5

RBRACE => shift 51

-----

State 49:

1 : Top -> STAGE IDENT OpEquals LBRACE Tops RBRACE . OpPeriod  / 5
28 : OpPeriod -> .  / 5
29 : OpPeriod -> . PERIOD  / 5

$ => reduce 28
PRED => reduce 28
STAGE => reduce 28
CONTEXT => reduce 28
IDENT => reduce 28
HASHDENT => reduce 28
RBRACE => reduce 28
LPAREN => reduce 28
PERIOD => shift 52
USCORE => reduce 28
DOLLAR => reduce 28
BANG => reduce 28
OpPeriod => goto 53

-----

State 50:

6 : Syn -> . Syn COLON Syn  / 15
7 : Syn -> . Syn LLOLLI Syn  / 15
8 : Syn -> . Syn LARROW Syn  / 15
9 : Syn -> . Syn RLOLLI Syn  / 15
10 : Syn -> . Syn RLOLLI  / 15
11 : Syn -> . Syn RARROW Syn  / 15
12 : Syn -> . Syn STAR Syn  / 15
13 : Syn -> . BANG Syn  / 15
14 : Syn -> . DOLLAR Syn  / 15
15 : Syn -> . STAGE IDENT  / 15
16 : Syn -> . Atomic Atomics  / 15
19 : Atomic -> . LPAREN Syn RPAREN  / 16
20 : Atomic -> . IDENT  / 16
21 : Atomic -> . USCORE  / 16
22 : Atomic -> . PRED  / 16
23 : Syncommas -> .  / 14
24 : Syncommas -> . Syn  / 14
25 : Syncommas -> . Syn COMMA Syncommas  / 14
25 : Syncommas -> Syn COMMA . Syncommas  / 14

PRED => shift 1
STAGE => shift 15
IDENT => shift 5
RBRACE => reduce 23
LPAREN => shift 3
USCORE => shift 7
DOLLAR => shift 8
BANG => shift 9
Syn => goto 47
Syncommas => goto 54
Atomic => goto 13

-----

State 51:

2 : Top -> CONTEXT IDENT OpEquals LBRACE Syncommas RBRACE . OpPeriod  / 5
28 : OpPeriod -> .  / 5
29 : OpPeriod -> . PERIOD  / 5

$ => reduce 28
PRED => reduce 28
STAGE => reduce 28
CONTEXT => reduce 28
IDENT => reduce 28
HASHDENT => reduce 28
RBRACE => reduce 28
LPAREN => reduce 28
PERIOD => shift 52
USCORE => reduce 28
DOLLAR => reduce 28
BANG => reduce 28
OpPeriod => goto 55

-----

State 52:

29 : OpPeriod -> PERIOD .  / 5

$ => reduce 29
PRED => reduce 29
STAGE => reduce 29
CONTEXT => reduce 29
IDENT => reduce 29
HASHDENT => reduce 29
RBRACE => reduce 29
LPAREN => reduce 29
USCORE => reduce 29
DOLLAR => reduce 29
BANG => reduce 29

-----

State 53:

1 : Top -> STAGE IDENT OpEquals LBRACE Tops RBRACE OpPeriod .  / 5

$ => reduce 1
PRED => reduce 1
STAGE => reduce 1
CONTEXT => reduce 1
IDENT => reduce 1
HASHDENT => reduce 1
RBRACE => reduce 1
LPAREN => reduce 1
USCORE => reduce 1
DOLLAR => reduce 1
BANG => reduce 1

-----

State 54:

25 : Syncommas -> Syn COMMA Syncommas .  / 14

RBRACE => reduce 25

-----

State 55:

2 : Top -> CONTEXT IDENT OpEquals LBRACE Syncommas RBRACE OpPeriod .  / 5

$ => reduce 2
PRED => reduce 2
STAGE => reduce 2
CONTEXT => reduce 2
IDENT => reduce 2
HASHDENT => reduce 2
RBRACE => reduce 2
LPAREN => reduce 2
USCORE => reduce 2
DOLLAR => reduce 2
BANG => reduce 2

-----

lookahead 0 = $ 
lookahead 1 = $ PRED STAGE CONTEXT IDENT HASHDENT LPAREN USCORE DOLLAR BANG 
lookahead 2 = PERIOD COLON STAR LARROW RARROW LLOLLI RLOLLI 
lookahead 3 = PRED IDENT LPAREN PERIOD COLON USCORE STAR LARROW RARROW LLOLLI RLOLLI 
lookahead 4 = PRED IDENT RBRACE LPAREN RPAREN PERIOD COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI 
lookahead 5 = $ PRED STAGE CONTEXT IDENT HASHDENT RBRACE LPAREN USCORE DOLLAR BANG 
lookahead 6 = RPAREN COLON STAR LARROW RARROW LLOLLI RLOLLI 
lookahead 7 = PRED IDENT LPAREN RPAREN COLON USCORE STAR LARROW RARROW LLOLLI RLOLLI 
lookahead 8 = PERIOD 
lookahead 9 = PRED IDENT LPAREN PERIOD USCORE 
lookahead 10 = RBRACE RPAREN PERIOD COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI 
lookahead 11 = $ RBRACE 
lookahead 12 = LBRACE 
lookahead 13 = PRED STAGE CONTEXT IDENT HASHDENT RBRACE LPAREN USCORE DOLLAR BANG 
lookahead 14 = RBRACE 
lookahead 15 = RBRACE COLON COMMA STAR LARROW RARROW LLOLLI RLOLLI 
lookahead 16 = PRED IDENT RBRACE LPAREN COLON COMMA USCORE STAR LARROW RARROW LLOLLI RLOLLI 

*)

struct
local
structure Value = struct
datatype nonterminal =
nonterminal
| string of Arg.string
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
| Arg.HASHDENT x => (5, Value.string x)
| Arg.LBRACE => (6, Value.nonterminal)
| Arg.RBRACE => (7, Value.nonterminal)
| Arg.LPAREN => (8, Value.nonterminal)
| Arg.RPAREN => (9, Value.nonterminal)
| Arg.PERIOD => (10, Value.nonterminal)
| Arg.COLON => (11, Value.nonterminal)
| Arg.COMMA => (12, Value.nonterminal)
| Arg.EQUALS => (13, Value.nonterminal)
| Arg.USCORE => (14, Value.nonterminal)
| Arg.DOLLAR => (15, Value.nonterminal)
| Arg.BANG => (16, Value.nonterminal)
| Arg.STAR => (17, Value.nonterminal)
| Arg.LARROW => (18, Value.nonterminal)
| Arg.RARROW => (19, Value.nonterminal)
| Arg.LLOLLI => (20, Value.nonterminal)
| Arg.RLOLLI => (21, Value.nonterminal)
)
)
in
val parse = ParseEngine.parse (
ParseEngine.next5x1 "z\130\131\133\134\135\128\128\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128h\128\128h\128\128hhhhhh\128h\128\128hhhhh\128\128\128\128\128\128\128\128\128\128\128\128\128\128\143\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128\128\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\146\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128j\128\128j\128\128jjjjjj\128j\128\128jjjjj\128\128\128\128\128\128\128\128\128\128\128\130\128\128\134\128\128\128\132\128m\128\128\128\136\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128i\128\128i\128\128iiiiii\128i\128\128iiiii\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128\128\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128\128\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\153\152\128\128\128\128\128\151\154\155\156\157\128\128\128\128\128\128\128\128\128\128\127\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128z\130\131\133\134\135\128z\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\128\128\134\128\128m\132mmmm\128\136\128\128mmmmm\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128d\128\128\128oo\128\160\128\128\128ooooo\128\128\128\128\128\128\128\128\128\128\128\128\128\128\162\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\163\128\152\128\128\128\128\128\151\154\155\156\157\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128d\128\128\128\128\128\128\160\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\165\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\128\128\134\128\128m\132mmmm\128\136\128\128mmmmm\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128p\128pppp\128\128\128\128ppppp\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128q\128qqqq\128\128\128\128qqqqq\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128\128\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128\128\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128~~~~~~\128~~\128\128\128\128\128~~~\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128\128\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128\128\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128\128\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128t\132tttt\128\136\137\138ttttt\128\128\128\128\128\128\128\128\128\128y\128\128\128\128\128\128y\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128n\128nnnn\128\128\128\128nnnnn\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128c\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\173\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128o\128oooo\128\128\128\128ooooo\128\128\128\128\128\128\128\128\128\128\128k\128\128k\128\128kkkkkk\128k\128\128kkkkk\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\174\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128{{{{{{\128{{\128\128\128\128\128{{{\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128l\128llll\128\128\128\128lllll\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128r\128rrrr\128\128\128\128\151rrrr\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128x\128xx\152x\128\128\128\128\151\154\155\156\157\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128v\128vvvv\128\128\128\128\151v\155v\157\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128s\128ssss\128\128\128\128\151s\155s\157\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128w\128wwww\128\128\128\128\151w\155w\157\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128u\128uuuu\128\128\128\128\151u\155u\157\128\128\128\128\128\128\128\128\128\128\128\130\131\133\134\135\128z\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128g\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\178\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128f\128\128\128\152\179\128\128\128\128\151\154\155\156\157\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\180\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128bbbbbb\128bb\128\181\128\128\128bbb\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\130\144\128\134\128\128g\132\128\128\128\128\128\136\137\138\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128bbbbbb\128bb\128\181\128\128\128bbb\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128aaaaaa\128aa\128\128\128\128\128aaa\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128}}}}}}\128}}\128\128\128\128\128}}}\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128e\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128||||||\128||\128\128\128\128\128|||\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128",
ParseEngine.next5x1 "\139\140\138\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\144\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\146\147\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\148\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\149\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\157\140\138\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\158\147\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\160\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\163\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\165\147\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\166\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\167\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\168\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\169\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\170\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\171\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\174\140\138\128\128\128\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\175\128\128\176\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\181\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\175\128\128\182\128\141\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\183\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128\128",
Vector.fromList [(1,2,(fn _::Value.syn(arg0)::rest => Value.top(Arg.Decl arg0)::rest|_=>raise (Fail "bad parser"))),
(1,7,(fn _::_::Value.tops(arg0)::_::_::Value.string(arg1)::_::rest => Value.top(Arg.Stage {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(1,7,(fn _::_::Value.syns(arg0)::_::_::Value.string(arg1)::_::rest => Value.top(Arg.Context {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(1,3,(fn _::Value.syns(arg0)::Value.string(arg1)::rest => Value.top(Arg.Special {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(0,0,(fn rest => Value.tops(Arg.NilT {})::rest)),
(0,2,(fn Value.tops(arg0)::Value.top(arg1)::rest => Value.tops(Arg.ConsT {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Ascribe {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.LolliL {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.ArrowL {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.LolliSOME {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn _::Value.syn(arg0)::rest => Value.syn(Arg.LolliNONE arg0)::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Arrow {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,3,(fn Value.syn(arg0)::_::Value.syn(arg1)::rest => Value.syn(Arg.Star {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn Value.syn(arg0)::_::rest => Value.syn(Arg.Bang arg0)::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn Value.syn(arg0)::_::rest => Value.syn(Arg.Dollar arg0)::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn Value.string(arg0)::_::rest => Value.syn(Arg.StagePred arg0)::rest|_=>raise (Fail "bad parser"))),
(2,2,(fn Value.syns(arg0)::Value.syn(arg1)::rest => Value.syn(Arg.App {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(6,0,(fn rest => Value.syns(Arg.Nil {})::rest)),
(6,2,(fn Value.syns(arg0)::Value.syn(arg1)::rest => Value.syns(Arg.Cons {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(7,3,(fn _::Value.syn(arg0)::_::rest => Value.syn(Arg.parens arg0)::rest|_=>raise (Fail "bad parser"))),
(7,1,(fn Value.string(arg0)::rest => Value.syn(Arg.Id arg0)::rest|_=>raise (Fail "bad parser"))),
(7,1,(fn _::rest => Value.syn(Arg.Wild {})::rest|_=>raise (Fail "bad parser"))),
(7,1,(fn _::rest => Value.syn(Arg.Pred {})::rest|_=>raise (Fail "bad parser"))),
(5,0,(fn rest => Value.syns(Arg.Nil {})::rest)),
(5,1,(fn Value.syn(arg0)::rest => Value.syns(Arg.Single arg0)::rest|_=>raise (Fail "bad parser"))),
(5,3,(fn Value.syns(arg0)::_::Value.syn(arg1)::rest => Value.syns(Arg.Cons {2=arg0,1=arg1})::rest|_=>raise (Fail "bad parser"))),
(3,0,(fn rest => Value.ign(Arg.Ign {})::rest)),
(3,1,(fn _::rest => Value.ign(Arg.Ign {})::rest|_=>raise (Fail "bad parser"))),
(4,0,(fn rest => Value.ign(Arg.Ign {})::rest)),
(4,1,(fn _::rest => Value.ign(Arg.Ign {})::rest|_=>raise (Fail "bad parser")))],
(fn Value.tops x => x | _ => raise (Fail "bad parser")), Arg.error)
end
end
