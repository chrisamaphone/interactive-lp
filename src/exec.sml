structure Exec = 
struct

fun fwdchain initialDB phase program = 
let
   fun loop fastctx = 
      case CoreEngine.possible_steps phase fastctx of
         [] => fastctx (* QUIESCENCE *)
       | T :: _ => loop (CoreEngine.apply_transition fastctx T)   

   val ctx = #2 (foldl (fn (x, (n, l)) => (n+1, (n, x) :: l)) (0, []) initialDB)
in
   loop (CoreEngine.init program ctx)
end

end
