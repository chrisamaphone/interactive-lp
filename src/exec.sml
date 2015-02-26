structure Exec = 
struct

fun fwdchain initialDB phase program = 
let
   fun loop phase fastctx = 
      case CoreEngine.possible_steps phase fastctx of
         [] => 
         (case CoreEngine.possible_steps "outer_level" fastctx of 
             [] => fastctx (* DONE *)
           | T :: _ => 
             let 
                (* READ OUT NEW PHASE FROM PROGRAM *)
                val phase' = raise Match 
                val fastctx' = CoreEngine.apply_transition fastctx T
             in
                loop phase' fastctx'
             end)
       | T :: _ => loop phase (CoreEngine.apply_transition fastctx T)   

   val ctx = #2 (foldl (fn (x, (n, l)) => (n+1, (n, x) :: l)) (0, []) initialDB)
in
   CoreEngine.context (loop phase (CoreEngine.init program ctx))
end

end
