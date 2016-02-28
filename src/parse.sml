structure Parse =
struct

open Coord
open Pos

datatype token = 
   PRED | STAGE | CONTEXT 
 | IDENT of string | NUM of IntInf.int | HASHDENT of string
 | LBRACE | RBRACE | LPAREN | RPAREN
 | PERIOD | COLON | COMMA | EQUALS | USCORE
 | UNIFY | DIFFER
 | BANG | DOLLAR | STAR | LARROW | RARROW | LLOLLI | RLOLLI

fun toString tok = 
   case tok of 
      PRED => "PRED" | STAGE => "STAGE" | CONTEXT => "CONTEXT"
    | IDENT s => s | NUM n => IntInf.toString n | HASHDENT s => ("#"^s)
    | LBRACE => "{" | RBRACE => "}" | LPAREN => "(" | RPAREN => ")"
    | PERIOD => "." | COLON => ":" | COMMA => "," | EQUALS => "="
    | USCORE => "_" 
    | UNIFY => "==" | DIFFER => "<>"
    | BANG => "!" | DOLLAR => "$" | STAR => "*" 
    | LARROW => "<-" | RARROW => "->" | LLOLLI => "o-" | RLOLLI => "-o"

datatype syn = 
   Ascribe of syn * syn      (* t : t *)
 | Lolli of syn * syn        (* t -o t *)
 | Arrow of syn * syn        (* t -> t *) 
 | Star of syn * syn         (* t * t *)
 | Unify of syn * syn        (* t == t *)
 | Differ of syn * syn       (* t <> t *)
 | Comma of syn * syn        (* t , t *)
 | Bang of syn               (* !t *)
 | Dollar of syn             (* $t *)
 | One of unit               (* () *)
 | App of syn * syn list     (* t t1...tn *)
                             (* Parser will only allow t = Id, Wild *)
 | Pred of unit              (* pred *)
 | Wild of unit              (* _ *)
 | Id of string              (* x or X *)
 | Num of IntInf.int         (* 3 *)
 | Braces of syn             (* { t } *)   
 | EmptyBraces of unit       (* {} *)             

fun synToString syn =
  (case syn of 
      Ascribe (x, y) => "("^synToString x^" : "^synToString y^")" 
    | Lolli (x, y) => "("^synToString x^" -o "^synToString y^")" 
    | Arrow (x, y) => "("^synToString x^" -> "^synToString y^")" 
    | Star (x, y) => "("^synToString x^" * "^synToString y^")" 
    | Unify (x, y) => "("^synToString x^" == "^synToString y^")" 
    | Differ (x, y) => "("^synToString x^" <> "^synToString y^")" 
    | Comma (x, y) => "("^synToString x^" , "^synToString y^")"
    | Bang x => "(!"^synToString x^")"
    | Dollar x => "($"^synToString x^")"
    | One () => "()" 
    | App (x, []) => synToString x
    | App (x, xs) => "("^String.concatWith " " (map synToString (x::xs))^")"
    | Pred () => "pred"
    | Wild () => "_"
    | Id x => x
    | Num n => IntInf.toString n
    | Braces x => "{"^synToString x^"}"
    | EmptyBraces () => "{}")

datatype top = 
   Decl of syn                    (* something. *)
 | Stage of string * top list     (* stage x {decl1, ..., decln} *)
 | Context of string * syn option (* context x {t} *)
 | Special of string * syn list   (* #whatever t1...tn *) 

fun topToString pre top =
  (case top of 
      Decl syn => pre^synToString syn^".\n"
    | Stage (id, tops) => pre^"stage "^id^" {\n"^
                          String.concat (map (topToString (pre^"  ")) tops)^
                          pre^"}\n"
    | Context (id, NONE) => pre^"context "^id^" {}\n"
    | Context (id, SOME syn) => pre^"context "^id^" {"^
                            synToString syn
                            ^"}\n"
    | Special (name, syns) => pre^"#"^name^" "^
                              String.concatWith " " (map synToString syns)
                              ^".\n")

local

structure Lexer = 
LexFn
(structure Streamable = StreamStreamable
 structure Arg =
 struct
   type symbol = coord * char
   val ord = fn (_, c) => Int.min (128, Char.ord c)
   type t = (token * pos) Stream.front

   type self = { lexmain : symbol Streamable.t -> (token * pos) Stream.front }
   type info = { match : symbol list,
                 len : int,
                 start : symbol Streamable.t,
                 follow : symbol Streamable.t,
                 self : self }

   fun posrange (toks: symbol list) = 
      pos (#1 (List.hd toks)) (#1 (List.last toks))
   fun stringrange (toks: symbol list) = 
      String.implode (List.map #2 toks)

   fun eof _ = Stream.Nil

   val error = 
     (fn ({match, ...}: info) => 
        (case match of
            [] => raise Fail ("Encountered unexpected error with lexing")
          | _ => raise Fail ("Encountered error lexing \""^stringrange match^
                             "\" at "^Pos.toString (posrange match))))

   fun skip ({self, follow, ...}: info) = #lexmain self follow

   fun ident ({self, match, follow, ...}: info) =
      Stream.Cons ((IDENT (stringrange match), posrange match),
         Stream.lazy (fn () => #lexmain self follow))

   fun num ({self, match, follow, ...}: info) =
     (case IntInf.fromString (stringrange match) of 
         NONE => raise Fail ("Couldn't parse '"^stringrange match^"' as an int")
       | SOME n => Stream.Cons ((NUM n, posrange match),
                      Stream.lazy (fn () => #lexmain self follow)))

   fun hashident ({self, match, follow, ...}: info) =
      Stream.Cons ((HASHDENT (stringrange (List.tl match)), posrange match),
         Stream.lazy (fn () => #lexmain self follow))

   fun simple token ({self, match, follow, ...}: info) = 
      Stream.Cons ((token, posrange match), 
         Stream.lazy (fn () => #lexmain self follow))

   val pred = simple PRED
   val stage = simple STAGE
   val context = simple CONTEXT
   val lbrace = simple LBRACE
   val rbrace = simple RBRACE
   val lparen = simple LPAREN
   val rparen = simple RPAREN
   val period = simple PERIOD
   val colon = simple COLON
   val comma = simple COMMA
   val equals = simple EQUALS
   val uscore = simple USCORE
   val bang = simple BANG
   val dollar = simple DOLLAR
   val star = simple STAR
   val larrow = simple LARROW
   val rarrow = simple RARROW
   val llolli = simple LLOLLI
   val rlolli = simple RLOLLI
   val differ = simple DIFFER
   val unify = simple UNIFY

 end)

structure Parser = 
ParseFn
(structure Streamable = 
 CoercedStreamable (structure Streamable = StreamStreamable
                    type 'a item = 'a * pos
                    fun coerce (x, _) = x)
 structure Arg =
 struct

   type string = string
   type ign = unit
   type int = IntInf.int

   val Ign = ignore
   val Nil  = fn () => []
   val NilT = fn () => []
   val Single = fn x => [x]
   val Cons  = fn (x, xs) => x :: xs
   val ConsT = fn (x, xs) => x :: xs
   val noneSyn = fn () => NONE
   val someSyn = SOME

   datatype top = datatype top
   datatype syn = datatype syn
   type synopt = syn option

   val parens = fn x => x
   val swap = fn (x, y) => (y, x)
   val LolliOne = fn x => Lolli (x, One ())
   val LolliL = Lolli o swap
   val ArrowL = Arrow o swap
   val StagePred = fn x => App (Id "stage", [Id x])
   fun app (x, ys) = 
      case (x, ys) of 
         (App (x, xs), ys) => app (x, xs @ ys)
       | (x, []) => x
       | (Id x, ys) => App (Id x, ys)
       | (Wild x, ys) => App (Wild x, ys)
       | _ => raise Fail ("It never makes sense to give arguments to '"^
                          synToString x^"', but this was given "^
                          Int.toString (length ys)^" argument(s).")

   type tops = top list
   type syns = syn list

   datatype terminal = datatype token

   fun error s = 
     (case Stream.front s of
         Stream.Nil => Fail "Syntax error at end of file"
       | Stream.Cons ((tok, pos), _) => 
           (Fail ("Parse error encountered at token "^toString tok^
                  " at position "^Pos.toString pos)))
 end)

fun coordinate eoln coord s =
  (Stream.lazy (fn () =>
     (case Stream.front s of
         Stream.Nil => Stream.Nil
       | Stream.Cons (x, s') =>
         let val coord' =
                 if eoln s
                    then Coord.nextline coord
                 else Coord.nextchar coord
         in
            Stream.Cons ((coord, x), coordinate eoln coord' s')
         end)))

fun eol stream = 
  (case Stream.front stream of
      Stream.Cons (#"\n", _) => true
    | Stream.Cons (#"\v", _) => true
    | Stream.Cons (#"\f", _) => true
    | Stream.Cons (#"\r", stream) => 
        (case Stream.front stream of
            Stream.Cons (#"\n", _) => false
          | _ => true)
    | _ => false)

in

fun parsefile s =
let
   val textstream = TextIO.openIn s
   val str = Stream.fromTextInstream textstream
   val str = coordinate eol (Coord.init s) str
   val str = Stream.eager (Lexer.lexmain str)

   (* Debug: print out all tokens *)
   val () = 
      if true then ()
      else Stream.app
             (fn (tok, pos) =>
                 print (toString tok^
                        String.implode 
                          (List.tabulate (9 - Int.min (9, size (toString tok)),
                                          fn _ => #" "))^
                        " - "^Pos.toString pos^"\n"))
             str


   val (tops, _) = Parser.parse str

   (* Debug: print out the parsed file *)
   val () =
      if true then ()
      else app (print o topToString "") tops
in 
   tops
   before TextIO.closeIn textstream
end

end

end
