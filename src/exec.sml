structure Exec = 
struct

exception BadProg

fun currentPhase {pers, lin} =
   case List.mapPartial 
           (fn (x, "stage", [Ceptre.GFn (id, [])]) => SOME id
           | _ => NONE)
           lin of
      [ id ] => id
    | _ => raise BadProg 

fun lookupPhase id ({stages,...}:Ceptre.program) =
  let
    fun lookupInList stages =
    (case stages of
       ((p as {name,body})::stages) => 
         if name = id then p
         else lookupInList stages
      | _ => raise BadProg)
  in
    lookupInList stages
  end


(* fwdchain : Ceptre.context -> Ceptre.program
*          -> Ceptre.context
*  
*  [fwdchain initialDB program]
*    runs [program] to global quiescence on [initialDB].
*)
fun fwdchain ctx (program as {init_stage,...} : Ceptre.program) = 
let
   fun loop stage fastctx = 
      case CoreEngine.possible_steps stage fastctx of
         [] => 
         (case CoreEngine.possible_steps "outer_level" fastctx of 
             [] => fastctx (* DONE *)
           | T :: _ => 
             let 
                val (fastctx', _) = CoreEngine.apply_transition fastctx T
                (* READ OUT NEW PHASE FROM PROGRAM *)
                val stage_id = currentPhase (CoreEngine.context fastctx')
                (* XXX there's probably a more efficient way to do that. *)
                (* val stage' = lookupPhase stage_id program *)
             in
                loop stage_id fastctx'
             end)
       | T :: _ => loop stage (#1 (CoreEngine.apply_transition fastctx T))

   (* XXX doesn't this need to have more stuff going on? The init
    * function is expecting just a list of rulesets, not a structured
    * Ceptre program with states - RJS *)
   val stages = #stages program
in
   CoreEngine.context (loop init_stage (CoreEngine.init stages ctx))
end

end
