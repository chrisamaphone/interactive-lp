(* Language Datatype for Ceptre programs *)

structure Ceptre = struct

  type var = int
  datatype term = Const of string | Var of var
  type pred = string
  type atprop = pred * (term list)
  datatype atom = Lin of atprop | Pers of atprop

  type ident = string
  
  (* external: foo X -o bar Y
  *  internal: Pi (2). foo 0 -o bar 1
  *)
  type rule_external = ident * (atom list) * (atom list)
  type rule_internal = ident * int * (atom list) * (atom list)

  (* a phase is a name & a list of rules *)
  type phase = ident * (rule_internal list)

  (* qui * phase p * S -o {phase p' * S'} =
  *   (?, p, S, p', S') *)
  type phase_rule = int * ident * (atom list) * ident * (atom list)

  (* program is a set of phases, a set of phase rules, and an identifier for an
  * initial phase *)
  type program = (phase list) * (phase_rule list) * ident

end
