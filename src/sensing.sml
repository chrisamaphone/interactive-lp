(* Pull sensors *)
structure PullSensors =
struct

  (* From core-engine.sml:
  * type sense = fastctx * Ceptre.term list -> Ceptre.term list list
  *)

  fun inputChop () =
    case TextIO.inputLine TextIO.stdIn of
         NONE => NONE
       | SOME s =>
           let
             val s = String.substring (s, 0, String.size s - 1)
           in
             SOME s
           end

  (* user input *)
  fun inputString (fastctx, terms) =
    case terms of
         [] => (case inputChop () of
                     NONE => []
                   | SOME s => [[Ceptre.cnst s]])
        | _ => [] (* ill-formed *)

  (* parse strings of the form "head a1 a2 ... an"
  *   as terms [head a1 .. an] *)
  fun parseTerm s =
    case String.tokens (Char.isSpace) s of
         [] => NONE
       | (t::args) => SOME (Ceptre.Fn (t, map Ceptre.cnst args))

  fun inputTerm (fastctx, tms) =
    case tms of
         [] => (case inputChop () of
                     NONE => []
                   | SOME s =>
                       (case parseTerm s of
                             NONE => []
                           | SOME t => [[t]]))
       | _ => [] (* ill-formed *)

  (* interactive fiction primitives *)
  
  fun unary s = SOME (Ceptre.cnst s)
  fun multiary s args = SOME (Ceptre.Fn (s, map Ceptre.cnst args))

  val cmdmap =
     List.foldr 
        (fn ((ks, v), d) => 
            List.foldr (fn (k, d) => StringRedBlackDict.insert d k v) d ks)
        StringRedBlackDict.empty
        [ (["n", "N", "north", "North", "NORTH"], "north"),
          (["s", "S", "south", "Sorth", "SOUTH"], "south"),
          (["e", "E", "east",  "East",  "EAST" ], "east"),
          (["w", "W", "west",  "West",  "WEST" ], "west"),
          (["q", "Q", "quit",  "Quit",  "QUIT" ], "quit"),
          (["l", "L", "look",  "Look",  "LOOK" ], "look"),
          (["take", "get", "GET"],                "take"),
          (["drop", "DROP"],                      "drop"),
          (["x", "X", "examine"],                 "examine") ]

  fun cmd s =
  case String.tokens Char.isSpace s of
       [] => NONE
     | [s] => 
        (case StringRedBlackDict.find cmdmap s of 
            SOME s => unary s
          | NONE => unary s) (* alternatively, NONE *)
    | (c::args) => (* multi-word cmd *) 
      (case cmd c of
            SOME (Ceptre.Fn (c, [])) => multiary c args
          | _ => NONE)

  fun inputCmd (fastctx, terms) =
    case terms of
         [] => (case inputChop () of
                     NONE => []
                   | SOME s => 
                       (case cmd s of
                             NONE => []
                           | SOME cmd => [[cmd]]))
       | _ => [] (* ill-formed *)

  val readline = ("input", inputString)
    (* XXX rename to READLINE and map "input" to it *)
  val if_command = ("inputCmd", inputCmd)
    (* XXX rename to IF_COMMAND and map "inputCmd" to it *)
  val readterm = ("inputTerm", inputTerm)
  
  val builtins = [readterm, readline, if_command]

end
