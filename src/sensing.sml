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

  (* interactive fiction primitives *)
  
  fun unary s = SOME (Ceptre.cnst s)
  fun multiary s args = SOME (Ceptre.Fn (s, map Ceptre.cnst args))

  fun cmd s =
  case String.tokens Char.isSpace s of
       [] => NONE
     | [s] =>
        (case s of
            ("n" | "N" | "north" | "North" | "NORTH") => unary "north"
          | ("s" | "S" | "south" | "South" | "SOUTH") => unary "south"
          | ("e" | "E" | "east" | "East" | "EAST") => unary "east"
          | ("w" | "W" | "west" | "West" | "WEST") => unary "west"
          | ("q" | "Q" | "quit" | "Quit" | "QUIT") => unary "quit"
          | ("l" | "L" | "look" | "Look" | "LOOK") => unary "look"
          | ("take" | "get" | "GET") => unary "take"
          | ("drop" | "DROP") => unary "drop"
          | ("x" | "X" | "examine") => unary "examine"
          | _ => unary s (* alternatively, NONE *))
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
  
  val builtins = [readline, if_command]

end
