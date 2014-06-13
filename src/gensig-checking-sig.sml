signature GENSIGS =
sig
  type atom = int
  type genrule = (atom list) * (atom list)
  (* could be just atom * (atom list) ? *)
  (* refinement: nt * (terminal list) * (nt list) * (terminal list) *) 

  type multistep = (atom list) * (atom list)

  type gensig = genrule list
  type context = atom list
  (* actually, context might want to have unification vars in it... *)

  type state_transition = atom * (atom list) * (atom option)
  type state_machine = state_transition list

  val terminal : atom -> gensig -> bool

  (* produces gen M D trace = trace
  * starting from gen and using state machine M, can we generate the multiset D?
  * *)
  val produces : atom -> state_machine -> context -> atom list 
    -> atom list option

  (* models (gen, G) D = true
  * iff {gen} -->*_G D 
  * *)
  val models : (atom * gensig) -> context -> bool 

  (* val extend : gensig * genrule list -> gensig *)

  (* invert gen G D = steps
  * means "invert with starting atom gen on generative signature G and goal
  * context D yields steps, which are additional info about the trace"
  *)
  val invert : (atom * gensig) -> context -> multistep list

end
