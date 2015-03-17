(* Pull sensors *)
structure PullSensors =
struct

  (* user input *)
  fun inputString (fastctx, terms) =
    case terms of
         [] => (case TextIO.inputLine TextIO.stdIn of
                     NONE => []
                   | SOME s => [Ceptre.cnst s])
        | _ => [] (* ill-formed *)

end
