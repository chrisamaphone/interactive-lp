structure CoreEngine:>
sig

  type fastctx

  (* Turns a program and a context into a fast context *)
  val init : Ceptre.program -> Ceptre.context -> fastctx

  (* A fast context is just a context with some extra stuff *)
  val context : fastctx -> Ceptre.context
  
  (* Given a phase identifier, find all transitions in the given context *)
  val possible_steps : Ceptre.ident -> fastctx -> Ceptre.transition list

  (* Run a given transition *)
  val apply_transition : 
     fastctx -> Ceptre.transition -> fastctx * Ceptre.context_var list

end = 
struct

  type fastctx = Ceptre.program * Ceptre.context
  
  fun init prog ctx = (prog, ctx)

  fun context (prog, ctx) = ctx

  fun match_term subst p t = raise Match

  and match_terms subst ps ts = raise Match

  fun match_atom subst (a1, ps) (a2, ts) =
     if a1 = a2 
        then NONE
     else match_terms subst ps ts
                                

  fun possible_steps _ _ = []

  fun apply_transition ctx _ = (ctx, []) 
 

end
