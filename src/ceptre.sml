(* Language Datatype for Ceptre programs *)

structure Ceptre = struct

  (* internal rule syntax *)
  type var = int
  type ident = string
  datatype term 
   = Fn of ident * term list 
   | Var of var
   | SLit of string
   | ILit of IntInf.int
  type pred = ident
  datatype mode = Pers | Lin
  type atom = mode * pred * (term list)
  datatype prem = 
     Eq of term * term
   | Neq of term * term
   | Tensor of prem * prem
   | Or of prem * prem
   | One
   | Atom of atom
  type rule_internal_new = 
    {name : ident, pivars : int, lhs : prem, rhs : atom list}
  type rule_internal = 
    {name : ident, pivars : int, lhs : atom list, rhs : atom list}
  type context = atom list

  (* Const term declarations *)
  datatype predClass = Prop | Bwd | Sense | Act
  datatype classifier = 
      Type | Tp of (ident list) * ident | Pred of predClass * term list

  type decl = ident * classifier

  (* Backward chaining persistent rules *)
  type bwd_rule = 
    {name : ident, pivars : int, 
     head : pred * term list, subgoals : atom list}
  type bwd_rule_new = 
    {name : ident, pivars : int, 
     head : pred * term list, subgoals : prem}

  type tp_header = decl list
  datatype builtin = NAT | NAT_ZERO | NAT_SUCC
  type sigma = {header:tp_header, 
                builtin: (string * builtin) list,
                rules:bwd_rule list}

  (* Stringification/ pretty printing for internal syntax *)

  fun varToString v = Int.toString v

  fun withArgs p [] = p
    | withArgs p args =
            "(" ^ p ^ " " ^ (String.concatWith " " args) ^ ")"

  fun termToString (Fn (p, args)) = withArgs p (map termToString args)
    | termToString (Var i) = "(Var "^(varToString i)^")"
    | termToString (SLit s) = "\""^String.toCString s^"\""
    | termToString (ILit i) = IntInf.toString i  

  fun atomToString (Lin, p, args) = withArgs p (map termToString args)
    | atomToString (Pers, p, args) = withArgs ("!"^p) (map termToString args)

  fun pclassToString class = 
     case class of
        Prop => "pred"
      | Act => "acting"
      | Sense => "sense"
      | Bwd => "bwd" 

  fun classToString class =
    case class of
         Type => "type"
       | Tp (tp_args, tp) => (String.concatWith " -> " tp_args) ^ tp
       | Pred (pclass, term_args) =>
           let
             val predstring =
               (case pclass of
                     Prop => "pred"
                   | Bwd => "bwd"
                   | Sense => "sense"
                   | Act => "act")
             val term_strings = map termToString term_args
           in
             withArgs predstring term_strings
           end


  fun contextToString x = 
    "{" ^ (String.concatWith ", " (map atomToString x)) ^ "}"

  fun ruleToString {name, pivars, lhs, rhs} =
    let
      val lhs_string = String.concatWith " * " (map atomToString lhs)
      val rhs_string = String.concatWith " * " (map atomToString rhs)
    in
      name ^ " : " ^ lhs_string ^ " -o " ^ rhs_string
    end

  fun ctxEltToString (var, id, terms) =
  let
    val termStrings = map termToString terms
  in
    "X" ^ (Int.toString var) ^ ": " ^ (withArgs id termStrings)
  end

  (* An enabled transition is (r, ts, S), representing our ability to run
     let {p} = r ts S 
      1) an identifier r representing a rule 
      2) a vector ts that gives assignments to r's pi-bindings
      3) a tuple S of the resources used by that rule
   *)
   (*
  type transition = {r : ident, tms : term vector, S : context_var list}
  *) (* XXX *)

 
  (* external rule syntax *)
  datatype external_term =
      EFn of ident * external_term list 
    | EVar of ident
    | EInt of IntInf.int
    | EString of string
  type eatom = pred * (external_term list)
  datatype epred = ELin of eatom | EPers of eatom
  type rule_external = {name : ident, lhs : epred list, rhs : epred list}
  
  (* external: foo X Y -o bar Y
  *  internal: Pi (2). foo 0 1 -o bar 1
  *)
  
  (* build a table of id |-> int maps for ext rules *)
  fun lookup id nil = NONE
    | lookup id ((s,n)::table) = 
        if s = id then SOME n
        else lookup id table

  fun lookupSplit id table =
  let
    fun lookupSplit' id nil cont = NONE
      | lookupSplit' id ((k,v)::table) cont =
          if k = id then SOME (v, cont table)
          else lookupSplit' id table (fn suffix => cont ((k,v)::suffix))
  in
    lookupSplit' id table (fn x => x)
  end

  fun lookupStage id nil = NONE
    | lookupStage id ((s as {name,body,nondet})::stages) =
        if name = id then SOME s
        else lookupStage id stages

  fun lookupStageSplit id stages =
  let
    fun lss' id nil cont = NONE
      | lss' id ((s as {name,body,nondet})::stages) cont =
          if name = id then SOME (s, stages)
          else lss' id stages (fn suffix => cont (s::suffix))
  in
    lss' id stages (fn x => x)
  end

  (* assigns numbers to named terms for the sake of translating between external
  * representation and internal. *)
  fun walk_terms (tms : external_term list) (table, ctr) =
    (case tms of 
          [] => (table, ctr)
        | ((EFn (id,args))::tms) => 
            let
              val (table,ctr) = walk_terms args (table,ctr)
            in
              walk_terms tms (table, ctr)
            end
        | ((EInt i)::tms) => walk_terms tms (table, ctr)
        | ((EString s)::tms) => walk_terms tms (table, ctr)
        | ((EVar id)::tms) =>
            (case lookup id table of
                  NONE => walk_terms tms ((id,ctr)::table, ctr+1)
                | SOME _ => walk_terms tms (table, ctr)))

  fun walk_atoms (atoms:epred list) (table : ((ident*int)list) * int) =
    case atoms of
         [] => table
       | (EPers (p, terms))::atoms =>
           let
             val t = walk_terms terms table
           in
             walk_atoms atoms t
           end
       | (ELin (p, terms))::atoms => 
           let
             val t = walk_terms terms table
           in
             walk_atoms atoms t
           end

  exception IllFormed

  (* a phase is a name & a list of rules *)
  type phase = ident * (rule_internal list)

  fun etermToTerm table term =
    case term of
         EFn (f, args) => Fn (f, map (etermToTerm table) args)
         (* XXX probably shouldn't valOf *)
       | EInt i => ILit i
       | EString s => SLit s
       | EVar id =>
           (case lookup id table of
                SOME x => Var x
              | NONE =>
                  let
                    val error = "Couldn't match id "^id^"\n"
                    val () = print error
                  in
                    raise IllFormed
                  end)

  fun eatomToAtom sg table epred =
    let
      val termMapper = etermToTerm table
    in
      (* XXX right now this treats any !'d linear thing as
      * persistent - not really right. Either all preds should be used
      * consistently, or !lin should only make sense on the RHS. *)
      case epred of
          ELin (p, tms) =>
            (case lookup p sg of
                SOME (Pred (class, tps)) => (Lin, p, map termMapper tms)
                (* XXX check tms match tps? *)
             (* | _ => raise IllFormed) *)
              | _ => (Lin, p, map termMapper tms))
        | EPers (p, tms) =>
            (case lookup p sg of
                  SOME _ => (Pers, p, map termMapper tms)
                | _ =>
                    let
                      val error = "Predicate "^p^" not found in signature.\n"
                      val () = print error
                    in
                      raise IllFormed
                    end)
    end

  fun externalToBwd sg ({name,lhs,rhs}:rule_external) =
    case rhs of
         [ehead as EPers(pred,eargs)] =>
         (* XXX this check might make sense but it isn't working atm
         if (List.all (fn EPers _ => true | _ => false) lhs)
         then *)
           let
             val hd_and_subgoals = ehead::lhs
             val (table, nvars) = walk_atoms hd_and_subgoals ([],0)
             val atomMapper = eatomToAtom sg table
           in
             case map atomMapper hd_and_subgoals of
                  ((Pers, head, head_args)::subgoals) =>
                    {name=name, pivars=nvars, 
                      head=(head,head_args),
                      subgoals=subgoals} : bwd_rule
                | _ => raise IllFormed
           end
         (* else raise IllFormed *)
       | _ => raise IllFormed

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

  (* a stage is a name, a modifier specifying what to do when multiple rules
  * apply, and a list of rules *)
  datatype nondet = Random | Interactive | Ordered
  type stage = {name : ident, nondet : nondet, body : rule_internal list}

  fun nondetToString Random = "random"
    | nondetToString Interactive = "interactive"
    | nondetToString Ordered = "ordered"


  fun stageToString {name, nondet, body} =
  let
    val rules = map (fn r => "  " ^ (ruleToString r) ^ ".") body
    val rule_string = String.concatWith "\n" rules
    val mode_string = nondetToString nondet
  in
    mode_string ^ " stage " ^ name ^ " = {\n"
    ^ rule_string
    ^ "\n}"
  end

  (* qui * stage p * S -o {stage p' * S'} =
  *   (?, p, S, p', S') *)
  type stage_rule = 
    {name : ident,
     pivars : int,
     pre_stage : ident,
     lhs : atom list,
     post_stage : ident,
     rhs : atom list}

  fun nullaryTerm t = Fn (t, [])
  fun unaryPred p arg = (Lin, p, [nullaryTerm arg])

  (* XXX also remove qui? *)
  fun stageRuleToRule {name, pivars, pre_stage, lhs, post_stage, rhs} =
  let
    val lhs = (unaryPred "stage" pre_stage)::lhs
    val rhs = (unaryPred "stage" post_stage)::rhs
  in
    {name=name, pivars=pivars, lhs=lhs, rhs=rhs}
  end

  (* program is a set of stages, a set of stage rules, and an identifier for an
  * initial stage *)
  type program = {stages : stage list, 
                  links : stage_rule list,
                  init_stage : ident,
                  init_state : context}
  (* XXX incorporate sigma? *)
  (* program definitions/#run/#trace directives? *)

  fun programToString ({stages, links, init_stage, init_state} : program) =
    let
      val stage_strings = map stageToString stages
      val stages_string = String.concatWith "\n" stage_strings
      val link_strings = map (ruleToString o stageRuleToRule) links
      val links_string = String.concatWith "\n" link_strings
      val init_state_string = contextToString init_state
    in
      "Stages:\n" ^ stages_string ^ "\n" ^
      "Links:\n" ^ links_string ^ "\n" ^
      "Initial stage: " ^ init_stage ^ "\n" ^
      "Initial state:\n" ^ init_state_string ^ "\n"
    end

  fun cnst s = Fn (s, [])

  (* reduce the outer level of a prog to just another stage *)
  (* progToRulesets : program -> rulesets * context *)
  fun progToRulesets ({stages, links, init_stage, init_state} : program)
    : (stage list) * context
    =
  let
    val outer_level_rules = map stageRuleToRule links
    (* XXX nondet = Random? could be ordered. *)
    val outer_level = {name="outer_level", nondet=Random, body=outer_level_rules}
    val ctx = (unaryPred "stage" init_stage)::init_state
  in
    (outer_level::stages, ctx)
  end

  (** Test Programs **)
  val [a,b,c,d,e] = map cnst ["a","b","c","d","e"]
  
(*
* stage paths = {
*   p/edge : edge X Y -o path X Y.
*   p/trns : path X Y * path Y Z -o path X Z.
* }
* n.b. this program doesn't really make sense; just an arbitrary syntax example.
*)

  fun edge x y = (Lin, "edge", [x,y])
  fun path x y = (Lin, "path", [x,y])

  val rule1'1 : rule_internal = 
   {name="p/edge", pivars = 2,
    lhs = [edge (Var 0) (Var 1)], rhs = [path (Var 0) (Var 1)]}

  val rule1'2 : rule_internal =
   {name="p/trns", pivars = 3,
    lhs = [path (Var 0) (Var 1), path (Var 1) (Var 2)],
    rhs = [path (Var 0) (Var 2)]}

  val stage_paths : stage =
    {name = "paths",
     nondet = Random,
     body = [rule1'1, rule1'2]}

  val init1 = 
    [edge a b, edge b c, edge a d, edge b d, edge d e]

  val prog1 : program =
    {stages = [stage_paths],
     links = [],
     init_stage = "paths",
     init_state = init1}


  (* Testing external to internal translation *)
  val ext1 =
    {name="r1", lhs=[ELin ("a", [EVar "X", EVar "Y"])],
                 rhs=[ELin ("b", [EVar "X"]), ELin ("c", [EVar "Y"])]}

  val linpred = Pred (Prop, [])

  (* program is a set of phases, a set of phase rules, and an identifier for an
  * initial phase *)
  (* type program = (phase list) * (phase_rule list) * ident *)

  val sg1 =
    [("a", linpred),
     ("b", linpred),
     ("c", linpred)]

 val etoi_test1 = externalToInternal sg1 ext1

end
