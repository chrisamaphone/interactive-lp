(* Language for invariant checking. *)
structure LinearLogicPrograms = struct

  (* Language definition: terms, atoms, rules, contexts *)

  type term = int (* term constants e.g. z or s *)
  datatype uvar = BOUND of int | FREE
  datatype lp_term = UVAR of uvar | LOCAL of int | TERM of term
  (* | MULTIARY_TERM of (string * (lp_term list)) *)
  datatype atom = AT of int | AP of string * (lp_term list)
  (* atom ~= first-order predicate *)

  type rname = string
  type genrule = rname * int * atom * int * (atom list)
    (* (r, avars, nt, evars, rhs) models 
    *   r : (Pi X)^avars. nt -o {(Exists x)^evars.rhs}
    *   (nvars is the number of existentials to bind;
    *     LOCAL refers to the nth new var) *)
  type gensig = genrule list
  type context = atom list
  type step = context * context

end
