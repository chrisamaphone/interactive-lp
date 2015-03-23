structure CoreEngine:>
sig
   type ctx_var
   type transition
   type fastctx
   type sense = fastctx * Ceptre.term list -> Ceptre.term list list

   val transitionToString : transition -> string
   
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
   val apply_transition: fastctx -> transition -> fastctx * ctx_var list

   (* Insert a ground atom into the context *)
   val insert: fastctx -> Ceptre.atom -> fastctx * ctx_var

   (* Remove an atom from the context. Raises Subscript if it's not there. *)
   val remove: fastctx -> ctx_var -> fastctx

   (* Look up all atoms with a particular name *)
   val lookup: fastctx -> Ceptre.ident -> (ctx_var * Ceptre.term list) list

end = 
struct


type ctx_var = int
datatype value = Var of ctx_var | Rule of Ceptre.pred * value list

type transition =
   {r: Ceptre.ident, tms : Ceptre.term option vector, Vs: value list}

fun vectorToList v = 
   List.tabulate (Vector.length v, fn i => valOf (Vector.sub (v, i)))

fun transitionToString {r, tms, Vs} =
   Ceptre.withArgs r (map Ceptre.termToString (vectorToList tms))

local
   val i = ref 0
in
val gen = fn () => (!i before i := !i + 1)
(* fun check (x, a, ts) = i := Int.max (!i, x + 1) *)
(* XXX do our own numbering *)
end

(* Little data structure of result trees *)
structure Tree = 
struct
   datatype 'a t = N | L of 'a | M of 'a t list
   fun N @ t = t
     | t @ N = t
     | t @ s = M [ t, s ] 

   fun flatten' (t, acc) = 
      case t of 
         N => acc
       | L x => (x :: acc)
       | M ts => List.foldr flatten' acc ts

   fun bind (t: 'a t) (f: 'a -> 'b t): 'b t  = 
      case t of 
         N => N
       | L x => f x
       | M xs => M (map (fn y => bind y f) xs) 

   fun many (ts: 'a t list) = 
      case ts of 
         [] => N
       | [ t ] => t
       | _ => M ts  

   fun letOne (t: 'a) (f: 'a -> 'b t): 'b t = f t

   fun letMany (ts: 'a list) (f: 'a -> 'b t): 'b t =
      many (List.mapPartial 
              (fn t => (case f t of N => NONE | t => SOME t)) 
              (ts)) 

   fun bindMany (ts: 'a t list) (f: 'a -> 'b t): 'b t =
      many (List.mapPartial 
              (fn t => (case bind t f of N => NONE | t => SOME t))
              (ts))

   fun require x (ts: unit -> 'a t): 'a t = if x then ts () else N

   fun fromOpt NONE = N
     | fromOpt (SOME x) = L x

   fun map f t =
      case t of
         N => N
       | L x => L (f x)
       | M xs => M (List.map (map f) xs)

   (* Ad-hoc merge of List.mapPartial and bind... *)
   fun mapList f xs = 
      case xs of
         [] => N
       | x :: xs => f x @ mapList f xs

   val flatten = fn t => flatten' (t, [])

   fun append f (a, t) = t @ f a

   (* Okay these actually have the right names *)
   fun guard false = N
     | guard true = L ()

end

structure C = Ceptre
structure S = IntRedBlackSet
structure M = StringRedBlackDict
structure I = IntRedBlackDict

type fast_ruleset = {name: C.ident, pivars: int, lhs: C.atom list} list

(* LHSes are connected to a particluar ruleset *)
(* RHSes are just mapped from their names *)
type 'a prog = 
  {senses:  ('a * Ceptre.term list -> Ceptre.term list list) M.dict,
   bwds: Ceptre.bwd_rule list M.dict,
   lmap: fast_ruleset M.dict,
   rmap: C.atom list M.dict}

type ctx = 
  {next: ctx_var,
   concrete: (ctx_var * C.atom) list}

datatype fastctx = 
   FC of {prog: fastctx prog, 
          ctx: ctx}

type sense = fastctx * Ceptre.term list -> Ceptre.term list list
                               
fun init (sigma: C.sigma) senses prog initial_ctx: fastctx = 
let
   fun compile_lhses {name, body} = 
      (name, 
       List.map
          (fn {name, pivars, lhs, rhs} => 
              {name = name, pivars = pivars, lhs = lhs})
          body)

   fun compile_rhses ({name, body}: C.stage, map) = 
      List.foldl 
          (fn ({name, rhs, ...}, rmap) => 
              M.insert rmap name rhs)
          map body

   fun insert_bwd_rule (rule: Ceptre.bwd_rule, m) =
   let val key = (#1 (#head rule)) 
   in M.insertMerge m key [ rule ] (fn rules => rule :: rules)
   end

   val prog: fastctx prog = 
      {senses = List.foldl (fn ((k, v), m) => M.insert m k v)
                   M.empty senses,
       bwds = List.foldl (fn (rule, m) => insert_bwd_rule (rule, m))
                 M.empty (#rules sigma),
       lmap = List.foldl (fn ((k, v), m) => M.insert m k v)
                 M.empty (map compile_lhses prog),
       rmap = List.foldl compile_rhses 
                 M.empty prog}

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

fun match_term {pat = p, term = t} (subst: msubst): msubst Tree.t = 
   case (p, t) of 
      (C.Var n, t) =>
        (case Vector.sub (subst, n) of 
            NONE => Tree.L (Vector.update (subst, n, SOME t))
          | SOME ground_pat => match_term {pat = ground_pat, term = t} subst)
    | (C.Fn (f, ps), C.Fn (g, ts)) => 
        (Tree.bind (Tree.guard (f = g))
           (fn () =>
         match_terms {f = f, pat = ps, term = ts} subst))
    | (p, C.Var n) => 
        (Tree.L subst) (* Variable found: imprecise (but still sound?) *)

and match_terms {f, pat = ps, term = ts} subst: msubst Tree.t = 
   case (ps, ts) of
      ([], []) => Tree.L subst
    | (p :: ps, t :: ts) => 
         Tree.bind
            (match_term {pat = p, term = t} subst)
            (match_terms {f = f, pat = ps, term = ts}) 
    | _ => raise Fail ("Arity error for "^f)


fun is_in x exclude = List.exists (fn y => Var x = y) exclude
 
val unknown = fn n => Vector.tabulate (n, fn _ => NONE)



(****** Logic programming engine ******)

fun match_hyp exclude subst (a, ps) (x, (m, b, ts)) =
   Tree.bind (Tree.guard (a = b andalso not (is_in x exclude)))
     (fn () =>
   Tree.bind (match_terms {f = a, pat = ps, term = ts} subst)
     (fn subst =>
   Tree.L (Var x, subst)))

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

fun search_premises r bwds ctx (Vs: value list) subst prems = 
   case prems of 
      [] => Tree.L {r = r, tms = subst, Vs = rev Vs}
    | prem :: prems => 
         Tree.bind 
            (search_prem bwds ctx Vs subst prem)
            (fn (x: value, subst) => 
               search_premises r bwds ctx (x :: Vs) subst prems)

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

and search_bwd bwds ctx (ts_subst, ts) bwd = 
let
   (* val () = print "search_bwd\n" *)
   val {name, pivars, head = (a, ps), subgoals} = bwd
in Tree.bind (match_terms {f = a, pat = ps, term = ts} (unknown pivars))
     (* Okay, we partially match the head of the rule, giving subst *)
     (fn subst => 
   Tree.bind (search_premises name bwds ctx [] subst subgoals)
     (* Here's a way to satisfy all subgoals! *)
     (fn {r, tms = subst, Vs} =>
   Tree.letOne (map (apply_subst subst) ps)
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
   Tree.bind (match_terms {f = a, pat = ts, term = ss} ts_subst)
     (* Now we have learned things about our original substitution, 
      * and can return *) 
     (fn ts_subst => 
   Tree.L (Rule (a, Vs), ts_subst)))))
end

(* search_prem bwds ctx Vs subst prem ~~~> some extended substitutions
 *
 * Trying to complete an atomic right focus
 * 
 *    ctx |- [ mode (a, subst(ps)) ]        *)

and search_prem bwds ctx (Vs: value list) subst (mode, a, ps) = 
let 
   (* val () = print "search_prem\n" *)
   (* Try to satisfy the premise by looking it up in the context *)
   val matched: (value * msubst) Tree.t = 
      case mode of 
         C.Lin => Tree.letMany ctx (fn hyp => match_hyp Vs subst (a, ps) hyp) 
       | C.Pers => Tree.letMany ctx (fn hyp => match_hyp [] subst (a, ps) hyp)

   (* Try to satisfy the premise by finding rules that match it *)
   val derived: (value * msubst) Tree.t =
      case M.find bwds a of
         NONE => Tree.N
       | SOME bwds_for_a => 
         let val tsx = map (apply_subst subst) ps
         in Tree.letMany bwds_for_a
               (* A rule! Does it give us a ground instance of our atom? *)
               (fn bwd => 
            search_bwd bwds ctx (subst, tsx) bwd)
         end
in
   Tree.@ (derived, matched)
end



fun possible_steps stage (FC {prog = {lmap, bwds, ...}, ctx = {concrete, ...}}) =
   case M.find lmap stage of
      NONE => raise Fail ("Stage "^stage^" unknown to the execution engine")
    | SOME ruleset => 
        (Tree.flatten
           (List.foldl 
              (Tree.append (fn {name, pivars, lhs} =>
                 (search_premises name bwds concrete [] (unknown pivars) lhs)))
              Tree.N ruleset))

fun add_to_ctx gsubst ((mode, a, ps), ({next, concrete}, xs)) = 
  ({next = next + 1, 
    concrete = (next, (mode, a, map (apply_subst gsubst) ps)) :: concrete},
   next :: xs)

fun apply_transition (FC {prog, ctx = {concrete, next}}) {r, tms, Vs} =
let

   (* Remove linear identifiers from context *)
   val concrete = 
      List.filter (fn (x, a) => C.Pers = #1 a orelse not (is_in x Vs)) concrete

   (* Find right hand side pattern hand side *)
   val rhs = 
      case M.find (#rmap prog) r of 
         NONE => raise Fail ("Error lookuing up rhs of rule "^r)
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

fun lookup (FC {prog, ctx}) a = 
  (List.mapPartial 
     (fn (x, (m, b, tms)) => if a = b then SOME (x, tms) else NONE)
     (#concrete ctx))

end
