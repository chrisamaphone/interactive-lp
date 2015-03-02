(* Language Datatype for Ceptre programs *)

structure Ceptre = struct

  (* internal rule syntax *)
  type var = int
  type ident = string
  datatype ground_term = Const of ident 
                       | Fn of (ground_term * (ground_term list))
  datatype term = Ground of ground_term | Var of var
  type pred = ident
  type atprop = pred * (term list)
  datatype atom = Lin of atprop | Pers of atprop
  type rule_internal = 
    {name : ident, pivars : int, lhs : atom list, rhs : atom list}

  (* Const term declarations *)
  datatype classifier = Type | Tp of ground_term | LinPred | PersPred
  type decl = ident * classifier

  (* Backward chaining persistent rules *)
  type bwd_rule = {head:atprop, subgoals : atprop list}

  type tp_header = decl list
  type sigma = {header:tp_header, rules:bwd_rule list}

  (* Contexts *)
  type context_var = int (* X1, X2, X3... *)
  type context = (int * atom) list (* X1:P1, X2:P2, X3:P3, ... *)

  (* An enabled transition is (r, ts, S), representing our ability to run
     let {p} = r ts S 
      1) an identifier r representing a rule 
      2) a vector ts that gives assignments to r's pi-bindings
      3) a tuple S of the resources used by that rule
   *)
  type transition = {r : ident, tms : term vector, S : context_var list}

 
  (* external rule syntax *)
  datatype external_term =
    EConst of ground_term | EVar of ident
  type eatom = pred * (external_term list)
  type rule_external = {name : ident, lhs : eatom list, rhs : eatom list}
  
  (* external: foo X Y -o bar Y
  *  internal: Pi (2). foo 0 1 -o bar 1
  *)
  
  (* build a table of id |-> int maps for ext rules *)
  fun lookup id nil = NONE
    | lookup id ((s,n)::table) = 
        if s = id then SOME n
        else lookup id table

  fun walk_terms (tms : external_term list) (table, ctr) =
    (case tms of 
          [] => (table, ctr)
        | ((EConst _)::tms) => walk_terms tms (table, ctr)
        | ((EVar id)::tms) =>
            (case lookup id table of
                  NONE => walk_terms tms ((id,ctr)::table, ctr+1)
                | SOME _ => walk_terms tms (table, ctr)))

  fun walk_atoms (atoms:eatom list) (table : ((ident*int)list) * int) =
    case atoms of
         [] => table
       | ((p, terms)::atoms) => 
           let
             val t = walk_terms terms table
           in
             walk_atoms atoms t
           end

  fun etermToTerm table term =
    case term of
         EConst g => Ground g
         (* XXX probably shouldn't valOf *)
       | EVar id => Var (valOf (lookup id table))

  exception IllFormed
  fun eatomToAtom sg table (p, tms) =
    let
      val termMapper = etermToTerm table
    in
      case lookup p sg of
          SOME LinPred => Lin (p, map termMapper tms)
        | SOME PersPred => Pers (p, map termMapper tms)
        | _ => raise IllFormed
    end

  fun externalToInternal 
    (sg:tp_header) ({name,lhs,rhs}:rule_external) =
    let
      val (table, nvars) = walk_atoms lhs ([], 0)
      val atomMapper = eatomToAtom sg table 
      val lhs' = map atomMapper lhs
      val rhs' = map atomMapper rhs
    in 
      {name=name, pivars=nvars, lhs=lhs', rhs=rhs'}
      : rule_internal
    end

  (* a phase is a name & a list of rules *)
  type phase = {name : ident, body : rule_internal list}

  (* qui * phase p * S -o {phase p' * S'} =
  *   (?, p, S, p', S') *)
  type phase_rule = 
    {name : ident,
     pivars : int,
     pre_phase : ident,
     lhs : atom list,
     post_phase : ident,
     rhs : atom list}

  (* program is a set of phases, a set of phase rules, and an identifier for an
  * initial phase *)
  type program = {phases : phase list, 
                  links : phase_rule list,
                  init_phase : ident,
                  init_state : atom list}
  (* XXX incorporate sigma? *)
  (* program definitions/#run/#trace directives? *)

  (* compile from program to list of rulesets *)
  type rulesets = (ident * (rule_internal list)) list

  fun cnst s = Ground (Const s)

  (* progToRulesets : program -> rulesets * (atom list) *)
  fun progToRulesets ({phases, links, init_phase, init_state} : program) =
  let
    fun link_to_rule {name, pivars, pre_phase, lhs, post_phase, rhs} =
      {name=name, pivars=pivars,
        lhs=(Lin ("phase", [cnst pre_phase]))::lhs,
        rhs=(Lin ("phase", [cnst post_phase]))::rhs}
    val phase_sets = map (fn {name, body} => (name, body)) phases
    val link_set = ("outer_level", map link_to_rule links)
    val init = (Lin ("phase", [cnst init_phase]))::init_state
  in
    (link_set::phase_sets : rulesets, init)
  end
  

  (** Test Programs **)
  val [a,b,c,d,e] = map cnst ["a","b","c","d","e"]
  
(*
* phase paths = {
*   p/edge : edge X Y -o path X Y.
*   p/trns : path X Y * path Y Z -o path X Z.
* }
* n.b. this program doesn't really make sense; just an arbitrary syntax example.
*)

  fun edge x y = Lin ("edge", [x,y])
  fun path x y = Lin ("path", [x,y])

  val rule1'1 : rule_internal = 
   {name="p/edge", pivars = 2,
    lhs = [edge (Var 0) (Var 1)], rhs = [path (Var 0) (Var 1)]}

  val rule1'2 : rule_internal =
   {name="p/trns", pivars = 3,
    lhs = [path (Var 0) (Var 1), path (Var 1) (Var 2)],
    rhs = [path (Var 0) (Var 2)]}

  val phase_paths : phase =
    {name = "paths",
     body = [rule1'1, rule1'2]}

  val init1 = 
    [edge a b,
     edge b c,
     edge a d,
     edge b d,
     edge d e]

  val prog1 : program =
    {phases = [phase_paths],
     links = [],
     init_phase = "paths",
     init_state = init1}


  (* Testing external to internal translation *)
  val ext1 =
    {name="r1", lhs=[("a", [EVar "X", EVar "Y"])],
                 rhs=[("b", [EVar "X"]), ("c", [EVar "Y"])]}

  val sg1 =
    [("a", LinPred),
     ("b", LinPred),
     ("c", LinPred)]

 val etoi_test1 = externalToInternal sg1 ext1

end
