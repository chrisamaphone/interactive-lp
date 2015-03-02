structure Exec = 
struct

exception BadProg

fun currentPhase ((x,p)::ctx) =
  (case p of
        (Ceptre.Lin ("phase", [Ceptre.Ground (Ceptre.Const id)])) => id
      | _ => currentPhase ctx)
  | currentPhase _ = raise BadProg


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


(* fwdchain : Ceptre.atom list -> Ceptre.program
*          -> Ceptre.context
*  
*  [fwdchain initialDB program]
*    runs [program] to global quiescence on [initialDB].
*)
fun fwdchain initialDB (program as {init_phase,...} : Ceptre.program) = 
let
   fun loop phase fastctx = 
      case CoreEngine.possible_steps phase fastctx of
         [] => 
         (case CoreEngine.possible_steps "outer_level" fastctx of 
             [] => fastctx (* DONE *)
           | T :: _ => 
             let 
                val fastctx' = CoreEngine.apply_transition fastctx T
                (* READ OUT NEW PHASE FROM PROGRAM *)
                val phase_id = currentPhase (CoreEngine.context fastctx')
                (* XXX there's probably a more efficient way to do that. *)
                (* val phase' = lookupPhase phase_id program *)
             in
                loop phase_id fastctx'
             end)
       | T :: _ => loop phase (CoreEngine.apply_transition fastctx T)   

   val ctx = #2 (foldl (fn (x, (n, l)) => (n+1, (n, x) :: l)) (0, []) initialDB)
in
   CoreEngine.context (loop init_phase (CoreEngine.init program ctx))
end

end
