structure CoreEngine:>
sig
   type ctx_var
   type transition
   type fastctx
   type sense = fastctx * Ceptre.term list -> Ceptre.term list list

   val transitionToString : transition -> string
   
   (* Turns a program and a context into a fast context *)
   val init: Ceptre.sigma
             -> (string * Ceptre.builtin) list
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

end = 
struct

fun debug f = () (* Not-trace-mode *)
(* fun debug f = f () (* Trace mode *) *)

type ctx_var = int
datatype value = Var of ctx_var | Rule of Ceptre.pred * value list | Sensed

type transition =
   {r: Ceptre.ident * int, tms : Ceptre.term option vector, Vs: value list}

fun vectorToList v = 
   List.tabulate (Vector.length v, fn i => valOf (Vector.sub (v, i)))

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

fun ground tm = 
   case tm of
      C.Var _ => false
    | C.Fn (_, tms) => List.all ground tms 
    | C.SLit _ => true
    | C.ILit _ => true 

fun ground_prefix' tms accum = 
   case tms of 
      [] => (rev accum, [])
    | tm :: tms => if ground tm
                      then ground_prefix' tms (tm :: accum)
                   else (rev accum, tm :: tms)

fun ground_prefix tms = ground_prefix' tms []

type fast_ruleset = {name: C.ident * int, pivars: int, lhs: C.atom list} list

(* LHSes are connected to a particluar ruleset *)
(* RHSes are just mapped from their names *)
type 'a prog = 
  {senses:  ('a * Ceptre.term list -> Ceptre.term list list) M.dict,
   bwds: (int * Ceptre.bwd_rule) list M.dict,
   lmap: fast_ruleset M.dict,
   rmap: C.atom list I.dict}

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

type sense = fastctx * Ceptre.term list -> Ceptre.term list list
                               
fun init (sigma: C.sigma) builtins senses prog initial_ctx: fastctx = 
let
   (* Add unique identifiers to all forward-chaining rules *)
   fun number_list uid [] = []
     | number_list uid (x :: xs) =
          (uid, x) :: number_list (uid+1) xs

   fun number_prog uid [] = []
     | number_prog uid ({name, body} :: stages) =  
          {name = name, body = number_list uid body}
          :: number_prog (uid + length body) stages

   val bwd_rules = number_list 0 (#rules sigma)
   val prog = number_prog (length bwd_rules) prog

   fun compile_lhses {name, body} = 
      (name, 
       List.map
          (fn (uid, {name, pivars, lhs, rhs}) => 
              {name = (name, uid), pivars = pivars, lhs = lhs})
          body)

   fun compile_rhses ({name, body}, map) = 
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
                 I.empty prog}

   val ctx: ctx = 
      List.foldl 
         (fn (atom, {next, concrete}) =>
            {next = next+1, concrete = ((next, atom) :: concrete)})
         {next = 0, concrete = []}
         initial_ctx
in
   FC {prog = prog, ctx = ctx}
end
                        
fun context (FC {ctx = {concrete, ...}, ...}) = map #2 concrete

fun guard b = if b then ND.return () else ND.fail

(****** Variable substitutions ******)

type msubst = C.term option vector


(* apply_subst subst term = subst(term)
 * 
 * Applies substitution as far as possible, leaving variables if any
 * occur. *)

fun apply_subst (subst: msubst) (t: C.term) = 
   case t of 
      C.Var n => 
        (case Vector.sub (subst, n) of 
            NONE => t
          | SOME t' => t')
    | C.Fn (f, ts) => C.Fn (f, List.map (apply_subst subst) ts)
    | C.SLit _ => t
    | C.ILit _ => t  


(* match_term {pat, term} subst ~~> zero or one new substs
 * match_terms {pat, term} subst ~~> zero or one new substs
 * 
 * Matching of a pattern against a ground or partially-ground
 * term.  
 * 
 * The substitution sigma provides information about the pattern: in 
 * other words, we're really trying to match subst(pat) against term.
 * 
 * This definitely makes sense if term is completely ground. If term
 * is not ground any variables it contains are treated as complete
 * unknowns, so we say that the match succeeds and we don't learn
 * anything about the structure of the corresponding pattern. I'm less
 * confident that makes sense. *)

fun match_term {pat = p, term = t} (subst: msubst): msubst ND.m = 
   case (p, t) of 
      (C.Var n, t) =>
        (case Vector.sub (subst, n) of 
            NONE => if ground t
                    then ND.return (Vector.update (subst, n, SOME t))
                    else ND.return subst (* Non-ground match: imprecise (but still sound?) *)
          | SOME ground_pat => match_term {pat = ground_pat, term = t} subst)
    | (C.Fn (f, ps), C.Fn (g, ts)) => 
        (ND.bind (guard (f = g))
           (fn () =>
         match_terms {f = f, pat = ps, term = ts} subst))
    | (C.SLit s1, C.SLit s2) => if s1 = s2 then ND.return subst else ND.fail
    | (C.ILit i1, C.ILit i2) => if i1 = i2 then ND.return subst else ND.fail
    | (p, C.Var n) => 
        (ND.return subst) (* Variable found: imprecise (but still sound?) *)
    | _ => raise Fail ("Type error, matching "^C.termToString t^
                       " against pattern "^C.termToString p)

and match_terms {f, pat = ps, term = ts} subst: msubst ND.m = 
   case (ps, ts) of
      ([], []) => ND.return subst
    | (p :: ps, t :: ts) => 
         ND.bind
            (match_term {pat = p, term = t} subst)
            (match_terms {f = f, pat = ps, term = ts}) 
    | _ => raise Fail ("Arity error for "^f)


fun is_in x exclude = List.exists (fn y => Var x = y) exclude
 
val unknown = fn n => Vector.tabulate (n, fn _ => NONE)



(****** Logic programming engine ******)

fun match_hyp exclude subst (a, ps) (x, (m, b, ts)) =
   ND.bind (guard (a = b andalso not (is_in x exclude)))
     (fn () =>
   ND.bind (match_terms {f = a, pat = ps, term = ts} subst)
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
 * The argument Vs is an accumulator: 
 * the proof terms we've already sorted out for rev(old_prems)
 * 
 * We learn more about the substitution "subst" as we go along, 
 * so we return both substitutions and the proof term we built. *)

fun search_premises' prog (r: Ceptre.ident * int) (Vs: value list) subst prems =
   case prems of 
      [] => ND.return {r = r, tms = subst, Vs = rev Vs}
    | prem :: prems => 
         ND.bind
            (search_prem prog Vs subst prem)
            (fn (x: value, subst) => 
               search_premises' prog r (x :: Vs) subst prems)

and search_premises prog (r: Ceptre.ident * int) subst prems = 
let 
   val () = debug (fn () =>
      print ("\nAttempting to run rule "^(#1 r)^"\n"))
in
   search_premises' prog r [] subst prems
end

(* search_bwd bwds ctx (ts_subst, ts) bwd ~~> some extended ts_substs 
 * 
 * Trying to find ways to match a partially instantiated proposition ts,
 * with the goal of getting a fully-instantiated version that has a proof,
 * and returning a suitably updated substitution.
 * 
 *   ctx [ name : subgoals -o a ps ] |- a ts 
 * 
 * Assumes ts_subst(ts) = ts -- in other words, assumes that this is
 * already a partially-instantiated list of terms.
 * 
 * Assumes backward chaining rule is reasonably moded; should have as a
 * postcondition that the atoms it returns are fully instantiated. *) 

and search_bwd prog (ts_subst, ts) (uid, bwd) = 
let
   val {name, pivars, head = (a, ps), subgoals} = bwd
in ND.bind (match_terms {f = a, pat = ps, term = ts} (unknown pivars))
     (* Okay, we partially match the head of the rule, giving subst *)
     (fn subst => 
   ND.bind (search_premises prog (name, uid) subst subgoals)
     (* Here's a way to satisfy all subgoals! *)
     (fn {r, tms = subst, Vs} =>
   ND.letOne (map (apply_subst subst) ps)
     (* (a, ss) is the fact we've established using backward chaining;
      * it has the proof term r(Vs). We're counting on ss being ground; 
      * this should always be the case if the backward chaining logic
      * programs are well moded.
      *
      * (a, ss) is definitely a provable fact in the current program,
      * so now we're in the position we're in with match_hyp: we want
      * to match this new fact against the subgoal ts that we started
      * with. *)
     (fn ss => 
   let val () = debug (fn () => 
                   print ("Matching derived fact "^a^"("^String.concatWith "," (map C.termToString ss)^")\n"^
                          "              against "^a^"("^String.concatWith "," (map C.termToString ts)^")\n"))
   in ND.bind (match_terms {f = a, pat = ts, term = ss} ts_subst)
     (* Now we have learned things about our original substitution, 
      * and can return *) 
     (fn ts_subst => 
   let val () = debug (fn () => 
                   print ("Match was successful\n"))
   in ND.return (Rule (a, Vs), ts_subst) end)end)))
end

(* search_prem bwds ctx Vs subst prem ~~~> some extended substitutions
 *
 * Trying to complete an atomic right focus
 * 
 *    ctx |- [ mode (a, subst(ps)) ]        *)

and search_prem prog (Vs: value list) subst (mode, a, ps) = 
let 
   val () = debug 
      (fn () => print ("Current subgoal: "^a^"("^
                       String.concatWith "," (map C.termToString ps)^")\n"))

   val () = debug
      (fn () => print ("Resolving subgoal "^a^"("^
                       String.concatWith "," (map C.termToString ps)^")"^
                       " from the context.\n"))

   (* val () = print "search_prem\n" *)
   (* Try to satisfy the premise by looking it up in the context *)
   val ctx = fc_concrete prog 
   val matched: (value * msubst) ND.m = 
      case mode of 
         C.Lin => ND.letMany ctx (fn hyp => match_hyp Vs subst (a, ps) hyp) 
       | C.Pers => ND.letMany ctx (fn hyp => match_hyp [] subst (a, ps) hyp)

   val () = debug
      (fn () => print ("Resolving subgoal "^a^"("^
                       String.concatWith "," (map (C.termToString o apply_subst subst) ps)^")"^
                       " with backward chaining.\n"))

   (* Try to satisfy the premise by finding rules that match it *)
   val derived: (value * msubst) ND.m =
      case M.find (fc_bwds prog) a of
         NONE => ND.fail
       | SOME bwds_for_a => 
         let val tsx = map (apply_subst subst) ps
         in ND.letMany bwds_for_a
               (* A rule! Does it give us a ground instance of our atom? *)
               (fn bwd => 
            search_bwd prog (subst, tsx) bwd)
         end

   val () = debug
      (fn () => print ("Resolving subgoal "^a^"("^
                       String.concatWith "," (map C.termToString ps)^")"^
                       " with sensing predicates.\n"))

   val sensed: (value * msubst) ND.m = 
      case M.find (fc_senses prog) a of 
         NONE => ND.fail
       | SOME sense_for_a =>
         let val (tsg, psng) = ground_prefix (map (apply_subst subst) ps)
         in ND.letMany (sense_for_a (prog, tsg))
               (* Some outputs. Let's use them to extend the substitution. *)
               (fn ts =>
            ND.bind (match_terms {f = a, pat = psng, term = ts} subst)
               (* We've got the extended substitution! *)
               (fn subst =>
            ND.return (Sensed, subst)))
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

fun add_to_ctx gsubst ((mode, a, ps), ({next, concrete}, xs)) = 
  let
    val atom = (mode, a, map (apply_subst gsubst) ps)
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
      List.foldr (add_to_ctx tms) ({concrete = concrete, next = next}, []) rhs
in
   (FC {prog = prog, ctx = ctx}, xs)
end

fun insert (FC {prog, ctx = {concrete, next}}) atom =
   (FC {prog = prog,
        ctx = {concrete = (next, atom) :: concrete, next = next+1}},
    next)

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

end
