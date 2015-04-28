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
  val north = "north"
  val east = "east"
  val west = "west"
  val south = "south"
  val quit = "quit"

  fun cmd s =
    case s of
         ("n" | "N" | "north" | "North" | "NORTH") => SOME north
       | ("s" | "S" | "south" | "South" | "SOUTH") => SOME south
       | ("e" | "E" | "east" | "East" | "EAST") => SOME east
       | ("w" | "W" | "west" | "West" | "WEST") => SOME west
       | ("q" | "Q" | "quit" | "Quit" | "QUIT") => SOME quit
       | _ => NONE

  fun inputCmd (fastctx, terms) =
    case terms of
         [] => (case inputChop () of
                     NONE => []
                   | SOME s => 
                       (case cmd s of
                             NONE => []
                           | SOME cmd => [[Ceptre.cnst cmd]]))
       | _ => [] (* ill-formed *)

  val readline = ("input", inputString)
    (* XXX rename to READLINE and map "input" to it *)
  val if_command = ("inputCmd", inputCmd)
    (* XXX rename to IF_COMMAND and map "inputCmd" to it *)
  
  val builtins = [readline, if_command]

end
