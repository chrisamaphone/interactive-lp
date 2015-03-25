(* Pull sensors *)
structure PullSensors =
struct

  (* From core-engine.sml:
  * type sense = fastctx * Ceptre.term list -> Ceptre.term list list
  *)

  (* user input *)
  fun inputString (fastctx, terms) =
    case terms of
         [] => (case TextIO.inputLine TextIO.stdIn of
                     NONE => []
                   | SOME s => [[Ceptre.cnst s]])
        | _ => [] (* ill-formed *)

  (* XXX ask for names for these from the input program? *)
  val inputSense = ("input", inputString)
  
  val all = [inputSense]

end
