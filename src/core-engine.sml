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
  val apply_transition : fastctx -> Ceptre.transition -> fastctx

end = 
struct

  type fastctx = Ceptre.context
  
  fun init _ ctx = ctx

  fun context ctx = ctx

  fun possible_steps _ _ = []

  fun apply_transition _ _ = [] 

end
