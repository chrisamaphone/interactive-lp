structure CoreEngine:>
sig
  (* BEGIN STUFF THAT BELONGS ELSEWHERE *)
  
  (* What is a context? *)
  type context_var = int  (* X1, X2, X3... *)
  type context = (int * Ceptre.atom) list (* X1:P1, X2:P2, X3:P3,... *)

  (* An enabled transition is (r, ts, S), representing our ability to run
     let {p} = r ts S 
      1) an identifier representing a rule 
      2) a vector that gives 
      3) a tuple of the resources used by that rule
   *)
  type transition = Ceptre.ident * Ceptre.term vector * context_var list
 
  (* END STUFF THAT BELONGS ELSEWHERE *)

  type fastctx

  (* Turns a program and a context into a fast context *)
  val init : Ceptre.program -> context -> fastctx

  (* A fast context is just a context with some extra stuff *)
  val context : fastctx -> context
  
  (* Given a phase identifier, find all transitions in the given context *)
  val possible_steps : Ceptre.ident -> fastctx -> transition list

  (* Run a given transition *)
  val apply_transition : fastctx -> transition -> fastctx

end = 
struct

  type context_var = int
  type context = (int * Ceptre.atom) list
  type transition = Ceptre.ident * Ceptre.term vector * context_var list

  type fastctx = context
  
  fun init _ ctx = ctx

  fun context ctx = ctx

  fun possible_steps _ _ = []

  fun apply_transition _ _ = [] 

end
