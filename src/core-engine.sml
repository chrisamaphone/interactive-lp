structure CoreEngine:>
sig
   eqtype ctx_var
   type transition
   type fastctx
   type sense = fastctx * Ceptre.term list -> Ceptre.term list list
 
   (* XXX move this elsewhere *)
   datatype value = 
      Var of ctx_var 
    | Rule of Ceptre.pred * value list 
    | Pair of value * value 
    | Inl of value 
    | Inr of value 
    | Unit

   val transitionToString: transition -> string
   val varToString: ctx_var -> string
   val valueToString: value -> string

   (* variables in the context that a particular transition depends on (both
   * linear and persistent, intermixed for now *)
   val transitionDeps: 
      transition -> ctx_var list

   val valueDeps:
      value -> ctx_var list

   (* The proof term rule(arg) has positive type *)
   (* The transition would be let p = rule(arg) *)
   val transitionProof: 
      transition -> {rule: Ceptre.ident, tms : Ceptre.term list, arg: value}
   
   (* Turns a program and a context into a fast context *)
   val init: Ceptre.sigma
             -> (string * sense) list 
             -> Ceptre.stage list 
             -> Ceptre.context 
             -> fastctx

   (* A fast context is just a context with some extra stuff *)
   val context: fastctx -> Ceptre.context
  
   (* Given a ruleset identifier, find all transitions in the given context *)
   val possible_steps: Ceptre.ident -> fastctx -> transition list

   (* Run a given transition *)
   val apply_transition: fastctx -> transition 
          -> fastctx * (ctx_var * Ceptre.atom) list

   (* Insert a ground atom into the context *)
   val insert: fastctx -> Ceptre.atom -> fastctx * ctx_var

   (* Remove an atom from the context. Raises Subscript if it's not there. *)
   val remove: fastctx -> ctx_var -> fastctx

   (* Remove all of a lis tof atoms from the context. *)
   val removeAll: fastctx -> ctx_var list -> fastctx

   (* Look up all atoms with a particular name *)
   val lookup: fastctx -> Ceptre.ident -> (ctx_var * Ceptre.term list) list

   (* get the (var * Ceptre.atom) list under the fastctx *)
   val get_concrete : fastctx -> (ctx_var * Ceptre.atom) list

end = 
struct

fun debug f = () (* Not-trace-mode *)
(* fun debug f = f () *) (* Trace mode *) 

type ctx_var = int

datatype value = 
   Var of ctx_var 
 | Rule of Ceptre.pred * value list 
 | Pair of value * value 
 | Inl of value 
 | Inr of value 
 | Unit

fun valueDeps v = 
   case v of 
      Var x => [x]
    | Rule (_, vs) => List.concat (map valueDeps vs)
    | Pair (v1, v2) => valueDeps v1 @ valueDeps v2
    | Inl v => valueDeps v
    | Inr v => valueDeps v
    | Unit => []   

type transition =
   {r: Ceptre.ident * int, tms : Ceptre.term option vector, Vs: value list}


fun vectorToList v = 
   List.tabulate (Vector.length v, fn i => valOf (Vector.sub (v, i)))

fun transitionProof ({r = (r, _), Vs, tms}: transition) = 
   {rule = r, tms = vectorToList tms, arg = hd Vs}

fun transitionDeps ({Vs, ...}: transition) = 
   valueDeps (hd Vs)

(* To String Functions *)

fun varToString i = "x"^(Int.toString i)

fun valueToString v =
  case v of
       Var x => varToString x
     | Rule (name, args) =>
        let
          val arg_strings = map valueToString args
          val args_string = String.concatWith " " arg_strings
        in
          "("^name^" "^args_string^")" 
        end
     | Pair (v1, v2) => "["^(valueToString v1)^", "^(valueToString v2)^"]"
     | Inl v => "(inl "^(valueToString v)^")"
     | Inr v => "(inr "^(valueToString v)^")"
     | Unit => "[]"

fun transitionToString {r = (r, _), tms, Vs} =
   Ceptre.withArgs r (map Ceptre.termToString (vectorToList tms))

local
   val i = ref 0
in
val gen = fn () => (!i before i := !i + 1)
(* fun check (x, a, ts) = i := Int.max (!i, x + 1) *)
(* XXX do our own numbering *)
end

structure ND = NondetEager


structure C = Ceptre
structure S = IntRedBlackSet
structure M = StringRedBlackDict
structure I = IntRedBlackDict

(****** Variable substitutions ******)

type msubst = C.term option vector
val nosubst: msubst = Vector.tabulate (0, fn _ => NONE)


(* apply_subst subst term = subst(term)
 * 
 * Applies substitution as far as possible, leaving variables if any
 * occur. *)

(*
fun apply_subst (subst: msubst) (t: C.term) = 
   case t of 
      C.Var n => 
        (case Vector.sub (subst, n) of 
            NONE => t
          | SOME t' => t')
    | C.Fn (f, ts) => C.Fn (f, List.map (apply_subst subst) ts)
    | C.SLit _ => t
    | C.ILit _ => t  
*)

fun ground_term_partial bi (subst: msubst) (t: C.term) =
   case t of 
      C.Var n =>
        (case Vector.sub (subst, n) of
            NONE => NONE
          | SOME t' => SOME t')
    | C.Fn (f, tms) =>
        (case (M.find bi f, ground_terms_partial bi subst tms []) of
            (_, NONE) => NONE
          | (NONE, SOME tms) => SOME (C.Fn (f, tms)) 
          | (SOME C.NAT_ZERO, SOME []) => SOME (C.ILit 0)
          | (SOME C.NAT_SUCC, SOME [C.ILit n]) => SOME (C.ILit (n+1))
          | _ => raise Fail "ground_term_partial: type error")
    | C.SLit _ => SOME t
    | C.ILit _ => SOME t

and ground_terms_partial bi (subst: msubst) (tms: C.term list) accum = 
   case tms of 
      [] => SOME (rev accum)
    | tm :: tms => 
        (case ground_term_partial bi subst tm of
            NONE => NONE
          | SOME tm => ground_terms_partial bi subst tms (tm :: accum))

fun ground_prefix bi subst tms accum = 
   case tms of 
      [] => (rev accum, [])
    | tm :: tms => 
        (case ground_term_partial bi subst tm of
            NONE => (rev accum, tm :: tms)
          | SOME tm => ground_prefix bi subst tms (tm :: accum))

datatype grounding = Term of C.term | Pattern of C.term
fun ground bi subst t =  
   case ground_term_partial bi subst t of 
      NONE => Pattern t
    | SOME t => Term t 

fun ground_for_debugging bi subst t =  
   case ground_term_partial bi subst t of 
      NONE => "["^C.termToString t^"]"
    | SOME t => C.termToString t 


type fast_ruleset = {name: C.ident * int, pivars: int, lhs: C.prem} list

(* LHSes are connected to a particluar ruleset *)
(* RHSes are just mapped from their names *)
type 'a prog = 
  {senses:  ('a * Ceptre.term list -> Ceptre.term list list) M.dict,
   bwds: (int * Ceptre.bwd_rule) list M.dict,
   lmap: fast_ruleset M.dict,
   rmap: C.atom list I.dict, 
   builtin: C.builtin M.dict}

type ctx = 
  {next: ctx_var,
   concrete: (ctx_var * C.atom) list}

datatype fastctx = 
   FC of {prog: fastctx prog, 
          ctx: ctx}

fun fc_concrete (FC {ctx = {concrete, ...}, ...}) = concrete
fun fc_bwds (FC {prog = {bwds, ...}, ...}) = bwds
fun fc_lmap (FC {prog = {lmap, ...}, ...}) = lmap
fun fc_senses (FC {prog = {senses, ...}, ...}) = senses
fun fc_builtin (FC {prog = {builtin, ...}, ...}) = builtin

type sense = fastctx * Ceptre.term list -> Ceptre.term list list
                               
fun init (sigma: C.sigma) senses prog initial_ctx: fastctx = 
let
   (* Add unique identifiers to all forward-chaining rules *)
   fun number_list uid [] = []
     | number_list uid (x :: xs) =
          (uid, x) :: number_list (uid+1) xs

   fun number_prog uid [] = []
     | number_prog uid ({name, body, nondet} :: stages) =  
          {name = name, body = number_list uid body, nondet=nondet}
          :: number_prog (uid + length body) stages

   val bwd_rules = number_list 0 (#rules sigma)
   val prog = number_prog (length bwd_rules) prog

   fun compile_lhses {name, body, nondet} = 
      (name, 
       List.map
          (fn (uid, {name, pivars, lhs, rhs}) => 
              {name = (name, uid), pivars = pivars, 
               lhs = 
               (* XXX REPLACE WITH IDENTITY WHEN TYPES CHANGE *)
               List.foldr (fn (a,p) => C.Tensor (C.Atom a, p)) C.One lhs})
          body)

   fun compile_rhses ({name, body, nondet}, map) = 
      List.foldl 
          (fn ((uid, {rhs, ...}: Ceptre.rule_internal), rmap) => 
              I.insert rmap uid rhs)
          map body

   fun insert_bwd_rule ((id, rule: Ceptre.bwd_rule), m) =
   let val key = (#1 (#head rule)) 
   in M.insertMerge m key [ (id, rule) ] (fn rules => (id, rule) :: rules)
   end

   val prog: fastctx prog = 
      {senses = List.foldl (fn ((k, v), m) => M.insert m k v)
                   M.empty senses,
       bwds = List.foldl (fn (rule, m) => insert_bwd_rule (rule, m))
                 M.empty bwd_rules,
       lmap = List.foldl (fn ((k, v), m) => M.insert m k v)
                 M.empty (map compile_lhses prog),
       rmap = List.foldl compile_rhses 
                 I.empty prog,
       builtin = List.foldl (fn ((k, v), m) => M.insert m k v)
                    M.empty (#builtin sigma)}

   val ctx: ctx = 
      List.foldl 
         (fn ((mode, a, tms), {next, concrete}) =>
          let 
             val atom =
                case ground_terms_partial (#builtin prog) nosubst tms [] of
                   SOME tms => (mode, a, tms)
                 | NONE => raise Fail "Initial context not ground" 
          in 
             {next = next+1, concrete = ((next, atom) :: concrete)}
          end)
         {next = 0, concrete = []}
         initial_ctx
in
   FC {prog = prog, ctx = ctx}
end
                        
fun context (FC {ctx = {concrete, ...}, ...}) = map #2 concrete

fun guard b = if b then ND.return () else ND.fail


(* match_term {pat, term} subst ~~> zero or one new substs
 * match_terms {pat, term} subst ~~> zero or one new substs
 * 
 * Matching of a pattern against a ***ground*** term
 * 
 * The substitution sigma provides incomplete information about the
 * pattern: in other words, we're really trying to match subst(pat)
 * against term. *)

fun match_type_error (p, t) = 
   raise Fail ("Type error, matching "^C.termToString t^
               " against pattern "^C.termToString p)

fun match_term bi {pat = p, term = t} (subst: msubst): msubst ND.m = 
let 
   val () = debug (fn () => 
      print ("Attempting match. Pattern: "^C.termToString p
             ^" term: "^C.termToString t^"\n"))
in
  (case (p, t) of 
      (C.Var n, t) =>
        (case Vector.sub (subst, n) of 
            NONE => ND.return (Vector.update (subst, n, SOME t))
          | SOME ground_pat => 
              (match_term bi {pat = ground_pat, term = t} subst))
    | (C.Fn (f, ps), C.Fn (g, ts)) => 
        (ND.bind (guard (f = g))
           (fn () =>
         match_terms bi {f = f, pat = ps, term = ts} subst))
    | (C.SLit s1, C.SLit s2) => if s1 = s2 then ND.return subst else ND.fail
    | (C.ILit i1, C.ILit i2) => if i1 = i2 then ND.return subst else ND.fail

    (* BUILTIN TYPE SPECIFICATIONS *)
    | (C.Fn (f, []), C.ILit i2) =>
        (if SOME (C.NAT_ZERO) <> M.find bi f 
            then match_type_error (p, t)
         else if i2 = 0 
            then ND.return subst
         else ND.fail)
    | (C.Fn (f, [p1]), C.ILit i2) => 
        (if SOME (C.NAT_SUCC) <> M.find bi f
            then match_type_error (p, t)
         else if i2 > 0
            then match_term bi {pat = p1, term = C.ILit (i2 - 1)} subst
         else ND.fail)

    | _ => match_type_error (p, t))
end

and match_terms bi {f, pat = ps, term = ts} subst: msubst ND.m = 
   case (ps, ts) of
      ([], []) => ND.return subst
    | (p :: ps, t :: ts) => 
         ND.bind
            (match_term bi {pat = p, term = t} subst)
            (match_terms bi {f = f, pat = ps, term = ts}) 
    | _ => raise Fail ("Arity error for "^f)

fun match_grounding_terms bi {f, pat = ps, term = ts} subst: msubst ND.m =
   case (ps, ts) of
      ([], []) => ND.return subst
    | (p :: ps, Pattern _ :: ts) => 
         match_grounding_terms bi {f = f, pat = ps, term = ts} subst
    | (p :: ps, Term t :: ts) => 
         ND.bind
            (match_term bi {pat = p, term = t} subst)
            (match_grounding_terms bi {f = f, pat = ps, term = ts}) 
    | _ => raise Fail ("Arity error for "^f)

fun match_grounding_pats bi {f, pat = ps, term = ts} subst: msubst ND.m =
   case (ps, ts) of
      ([], []) => ND.return subst
    | (Term _ :: ps, t :: ts) => 
      match_grounding_pats bi {f = f, pat = ps, term = ts} subst
    | (Pattern p :: ps, t :: ts) => 
         ND.bind
            (match_term bi {pat = p, term = t} subst)
            (match_grounding_pats bi {f = f, pat = ps, term = ts})
    | _ => raise Fail ("Arity error for "^f)

fun is_in_val x value = 
   case value of
      Unit => false
    | Pair (t1, t2) => is_in_val x t1 orelse is_in_val x t2
    | Inl t1 => is_in_val x t1
    | Inr t1 => is_in_val x t1
    | Var y => y = x 
    | Rule (r, tms) => List.exists (is_in_val x) tms 

fun is_in x exclude = List.exists (is_in_val x) exclude
 
val unknown = fn n => Vector.tabulate (n, fn _ => NONE)



(****** Logic programming engine ******)

fun match_hyp prog exclude subst (a, ps) (x, (m, b, ts)) =
   ND.bind (guard (a = b andalso not (is_in x exclude)))
     (fn () =>
   ND.bind (match_terms (fc_builtin prog) {f = a, pat = ps, term = ts} subst)
     (fn subst =>
   ND.return (Var x, subst)))

(* search_premises r bwds ctx Vs subst prems ~~~> some enabled transitions
 * 
 * Trying to complete a right focus that is in service of some left focus:
 * 
 *    ctx |- [ subst(prems) ]
 *    ------------------------
 *            ...
 *    -----------------------------------  
 *    ctx |- [ subst(old_prems @ prems) ]  ctx [ A ] |- C
 *    ------------------------------------------------------
 *         ctx [ r : old_prems -o A ] |- C
 * 
 * The argument Vs is an accumulator: given a proof term V of prems,
 * the proof terms we've already sorted out for rev(old_prems)
 * 
 * We learn more about the substitution "subst" as we go along, 
 * so we return both substitutions and the proof term we built. *)

fun search_premises' prog (r: Ceptre.ident * int) (Vs: value list) subst prem =
   case prem of
      C.Eq (t1, t2) =>
      let val bi = fc_builtin prog 
      in
        (ND.bind (case ground_term_partial bi subst t1 of 
                     SOME t1 => match_term bi {pat=t2, term=t1} subst
                   | NONE =>
                 (case ground_term_partial bi subst t2 of 
                     SOME t2 => match_term bi {pat=t1, term=t2} subst
                   | NONE => raise Fail "Non-ground equality")) 
            (fn subst => ND.return (Unit, subst)))
      end
    | C.Neq (t1, t2) => 
      let val bi = fc_builtin prog 
         val t1 = ground_term_partial bi subst t1 (* Must be SOME *)
         val t2 = ground_term_partial bi subst t2 (* Must be SOME *)
      in
        (case (t1, t2) of 
            (SOME t1, SOME t2) =>
              (if t1 = t2 then ND.return (Unit, subst) else ND.fail)
          | _ => raise Fail "Inequality between non ground terms")
      end
    | C.Tensor (prem1, prem2) =>
        (ND.bind
            (search_premises' prog r Vs subst prem1)
            (fn (V1, subst) =>
         ND.bind
            (search_premises' prog r (V1 :: Vs) subst prem2)
            (fn (V2, subst) =>
         ND.return (Pair (V1, V2), subst))))
    | C.One => ND.return (Unit, subst)
    | C.Or (prem1, prem2) => 
         ND.combine
          [ search_premises' prog r Vs subst prem1
          , search_premises' prog r Vs subst prem2 ]
    | C.Atom atom => 
         (search_atom prog Vs subst atom)

and search_premises prog (r: Ceptre.ident * int) subst prems = 
let 
   val () = debug (fn () =>
      print ("\nAttempting to run rule "^(#1 r)^"\n"))
in
  (ND.bind (search_premises' prog r [] subst prems)
      (fn (value, subst) =>
   let val () = debug (fn () =>
      print ("Rule "^(#1 r)^" successfully run, generating substitution\n"))
   in ND.return {r = r, tms = subst, Vs = [value]} end))
end

(* search_bwd bwds ctx (ts_subst, ts) bwd ~~> some extended ts_substs 
 * 
 * Trying to find ways to match a partially instantiated proposition ts,
 * with the goal of getting a fully-instantiated version that has a proof,
 * and returning a suitably updated substitution.
 * 
 *   ctx [ name : subgoals -o a ps ] |- a head
 * 
 * Assumes ts_subst has already been applied to the elements in head
 * that it was possible to ground -- these terms marked with Term, the
 * terms that are patterns to be used later on to update ts_subst are
 * marked as Pattern.
 * 
 * Assumes backward chaining rule is reasonably moded; should have as a
 * postcondition that the atoms it returns are fully instantiated. *) 

and search_bwd prog (ts_subst, head) (uid, bwd) = 
let
   val bi = fc_builtin prog
   val {name, pivars, head = (a, ps), subgoals} = bwd
   (* XXX REPLACE WITH IDENTITY ONCE TYPES FIXED *)
   val subgoals = List.foldr (fn (a,p) => C.Tensor (C.Atom a, p)) C.One subgoals
in ND.bind (match_grounding_terms bi
               {f = a, pat = ps, term = head} 
               (unknown pivars))
     (* Okay, we partially match the head of the rule, giving subst *)
     (fn subst => 
   ND.bind (search_premises prog (name, uid) subst subgoals)
     (* Here's a way to satisfy all subgoals! *)
     (fn {r, tms = subst, Vs} =>
   ND.letOne (valOf (ground_terms_partial bi subst ps [])
              handle Option => raise Fail "Non-ground result of bwd chaining")
     (* (a, ss) is the fact we've established using backward chaining;
      * it has the proof term r(Vs). 
      *
      * Now we're in the position we're in with match_hyp: we want to
      * match this new fact against the subgoal ts that we started
      * with. *)
     (fn ss => 
   ND.bind (match_grounding_pats bi {f = a, pat = head, term = ss} ts_subst)
     (* Now we have learned things about our original substitution, 
      * and can return *) 
     (fn ts_subst => 
   ND.return (Rule (a, Vs), ts_subst)))))
end

(* search_atom prog Vs subst prem ~~~> some extended substitutions
 *
 * Trying to complete an atomic right focus
 * 
 *    prog |- [ mode (a, subst(ps)) ]        *)

and search_atom prog (Vs: value list) subst (mode, a, ps) =
let 
   val () = debug
      (fn () => print ("Attempting subgoal: "^a^"("^
                       String.concatWith ","
                          (map (ground_for_debugging (fc_builtin prog) subst)
                              ps)^")\n"))

   (* val () = print "search_prem\n" *)
   (* Try to satisfy the premise by looking it up in the context *)
   val ctx = fc_concrete prog 
   val matched: (value * msubst) ND.m = 
      case mode of 
         C.Lin => 
           (ND.letMany ctx (fn hyp => match_hyp prog Vs subst (a, ps) hyp))
       | C.Pers => 
           (ND.letMany ctx (fn hyp => match_hyp prog [] subst (a, ps) hyp))

   (* Try to satisfy the premise by finding rules that match it *)
   val derived: (value * msubst) ND.m =
      case M.find (fc_bwds prog) a of
         NONE => ND.fail
       | SOME bwds_for_a => 
         let val head = map (ground (fc_builtin prog) subst) ps
         in ND.letMany bwds_for_a
               (* A rule! Does it give us a ground instance of our atom? *)
               (fn bwd => 
            search_bwd prog (subst, head) bwd)
         end

   val sensed: (value * msubst) ND.m = 
      case M.find (fc_senses prog) a of 
         NONE => ND.fail
       | SOME sense_for_a =>
         let 
            val (tsg, psng) = ground_prefix (fc_builtin prog) subst ps []
            val bi = fc_builtin prog
         in ND.letMany (sense_for_a (prog, tsg))
               (* Some outputs. Let's use them to extend the substitution. *)
               (fn ts =>
            ND.bind (match_terms bi {f = a, pat = psng, term = ts} subst)
               (* We've got the extended substitution! *)
               (fn subst =>
            ND.return (Unit, subst)))
         end

   val () = debug
      (fn () => print ("Done resolving subgoal "^a^"("^
                       String.concatWith "," (map C.termToString ps)^").\n"))
             
in
   (* This is a unique place in the code, because we **might** want to
    * determinstically order the consideration of derived, matched, and
    * sensed predicates, so we might want a definitely-ordered choice
    * here. *)
   ND.combine [ derived, matched, sensed ]
end

fun possible_steps stage prog =
   case M.find (fc_lmap prog) stage of
      NONE => raise Fail ("Stage "^stage^" unknown to the execution engine")
    | SOME ruleset => 
        (ND.list
           (ND.letMany ruleset
               (fn {name, pivars, lhs} =>
            search_premises prog name (unknown pivars) lhs)))

fun add_to_ctx gsubst bi ((mode, a, ps), ({next, concrete}, xs)) = 
  let
    val atom = (mode, a, valOf (ground_terms_partial bi gsubst ps [])
                         handle Option => raise Fail "non-ground --> ctx")
  in
    ({next = next + 1, 
      concrete = (next, atom) :: concrete},
    (next, atom) :: xs)
  end

fun apply_transition (FC {prog, ctx = {concrete, next}}) {r, tms, Vs} =
let

   (* Remove linear identifiers from context *)
   val concrete = 
      List.filter (fn (x, a) => C.Pers = #1 a orelse not (is_in x Vs)) concrete

   (* Find right hand side pattern hand side *)
   val (name, uid) = r
   val rhs = 
      case I.find (#rmap prog) uid of 
         NONE => raise Fail ("Error lookuing up rhs of rule "^name)
       | SOME rhs => rhs
  
   (* Update context, get new identifiers *)
   val (ctx, xs) = 
      List.foldr (add_to_ctx tms (#builtin prog)) 
         ({concrete = concrete, next = next}, []) rhs
in
   (FC {prog = prog, ctx = ctx}, xs)
end

fun insert (FC {prog, ctx = {concrete, next}}) (mode, a, tms) =
let 
   val tms = 
      case ground_terms_partial (#builtin prog) nosubst tms [] of
         NONE => raise Fail "Terms given to insert not ground"
       | SOME tms => tms
in
  (FC {prog = prog,
       ctx = {concrete = (next, (mode, a, tms)) :: concrete, next = next+1}},
   next)
end

fun remove (FC {prog, ctx = {concrete, next}}) x = 
   FC {prog = prog,
       ctx = {next = next,
              concrete = List.filter (fn (y, a) => x <> y) concrete}}

fun removeAll c0 xs =
  foldl (fn (x,c) => remove c x) c0 xs

fun lookup (FC {prog, ctx}) a = 
  (List.mapPartial 
     (fn (x, (m, b, tms)) => if a = b then SOME (x, tms) else NONE)
     (#concrete ctx))

fun get_concrete (FC {prog, ctx}) = #concrete ctx

end
