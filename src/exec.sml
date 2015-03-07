structure Exec = 
struct

exception BadProg

fun currentPhase {pers, lin} =
   case List.mapPartial 
           (fn (x, "phase", [Ceptre.GFn (id, [])]) => SOME id
           | _ => NONE)
           lin of
      [ id ] => id
    | _ => raise BadProg 

fun lookupPhase id ({phases,...}:Ceptre.program) =
  let
    fun lookupInList phases =
    (case phases of
       ((p as {name,body})::phases) => 
         if name = id then p
         else lookupInList phases
      | _ => raise BadProg)
  in
    lookupInList phases
  end


(* fwdchain : Ceptre.context -> Ceptre.program
*          -> Ceptre.context
*  
*  [fwdchain initialDB program]
*    runs [program] to global quiescence on [initialDB].
*)
fun fwdchain ctx (program as {init_phase,...} : Ceptre.program) = 
let
   fun loop phase fastctx = 
      case CoreEngine.possible_steps phase fastctx of
         [] => 
         (case CoreEngine.possible_steps "outer_level" fastctx of 
             [] => fastctx (* DONE *)
           | T :: _ => 
             let 
                val (fastctx', _) = CoreEngine.apply_transition fastctx T
                (* READ OUT NEW PHASE FROM PROGRAM *)
                val phase_id = currentPhase (CoreEngine.context fastctx')
                (* XXX there's probably a more efficient way to do that. *)
                (* val phase' = lookupPhase phase_id program *)
             in
                loop phase_id fastctx'
             end)
       | T :: _ => loop phase (#1 (CoreEngine.apply_transition fastctx T))
in
   CoreEngine.context (loop init_phase (CoreEngine.init program ctx))
end

end
