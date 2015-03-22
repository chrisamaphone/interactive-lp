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

type transition =
   {r: Ceptre.ident, tms : Ceptre.term option vector, S: ctx_var list}

fun vectorToList v = 
   List.tabulate (Vector.length v, fn i => valOf (Vector.sub (v, i)))

fun transitionToString {r, tms, S} =
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

   fun letMany (ts: 'a list) (f: 'a -> 'b t): 'b t =
      many (List.mapPartial 
              (fn t => (case f t of N => NONE | t => SOME t)) 
              (ts)) 

   fun bindMany (ts: 'a t list) (f: 'a -> 'b t): 'b t =
      many (List.mapPartial 
              (fn t => (case bind t f of N => NONE | t => SOME t))
              (ts))

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
   bwds: Ceptre.bwd_rule list,
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
   val prog: fastctx prog = 
      {senses = List.foldl (fn ((k, v), m) => M.insert m k v)
                   M.empty senses,
       bwds = #rules sigma,
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

type msubst = C.term option vector

(* Matching of a pattern (C.term) against a ground or partially-ground
 * term.  If the "ground" term t is not fully ground, then we will 
 * treat any variable occurances as complete wildcards (no unification 
 * is performed). *)
fun match_term (p: C.term, t: C.term) (subst: msubst): msubst Tree.t = 
   case (p, t) of 
      (C.Var n, t) =>
        (case Vector.sub (subst, n) of 
            NONE => Tree.L (Vector.update (subst, n, SOME t))
          | SOME t' => match_term (t', t) subst)
    | (C.Fn (f, ps), C.Fn (g, ts)) => 
         if f = g then match_terms (f, ps, ts) subst else Tree.N
    | (p, C.Var n) => Tree.L subst (* Variable found: imprecise *)

and match_terms (f, ps, ts) subst: msubst Tree.t = 
   case (ps, ts) of
      ([], []) => Tree.L subst
    | (p :: ps, t :: ts) => 
         Tree.bind
            (match_term (p, t) subst)
            (match_terms (f, ps, ts)) 
    | _ => raise Fail ("Arity error for "^f)

(* Applies the substitution as far as possible, leaving variables if
 * any occur *)
fun apply_subst (subst: msubst) (t: C.term) = 
   case t of 
      C.Var n => 
        (case Vector.sub (subst, n) of 
            NONE => t
          | SOME t' => t')
    | C.Fn (f, ts) => C.Fn (f, List.map (apply_subst subst) ts)

fun is_in x exclude = List.exists (fn y => x = y) exclude
 
val unknown = fn n => Vector.tabulate (n, fn _ => NONE)

fun match_hyp exclude subst (a, ps) (x, (m, b, ts)) =
   if a = b andalso not (is_in x exclude)
      then Tree.map (fn subst => (x, subst)) (match_terms (a, ps, ts) subst)
   else Tree.N

(* Search the context for all (non-excluded) matches *)

(* Trying to find ways to match a partially instantiated proposition ts
 * If rules are reasonably moded, we will return 
 * 
 *   ctx [ name : subgoals -o b ps ] |- a ts *)

fun search_bwd bwds ctx Vs subst (a, ts) bwd = 
let
   val ts = map (apply_subst subst) ts
   val {name, pivars, head = (b, ps), subgoals} = bwd
in
   if a = b
      then Tree.N
           (* Tree.bind (match_terms (a, ts, ps) (unknown pivars))
             (fn subst => 
           Tree.bind (search_premises name bwds ctx Vs subst subgoals) 
             (fn {r, tms, Vs} =>
           Tree.L (~1, map (apply_subst tms) ps))) *)
   else Tree.N
end

(* Trying to complete a right focus that is in service of some left focus:
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

and search_premises r bwds ctx Vs subst prems = 
   case prems of 
      [] => Tree.L {r = r, tms = subst, S = rev Vs}
    | prem :: prems => 
         Tree.bind 
            (search_prem bwds ctx Vs subst prem)
            (fn (x, subst) => 
               search_premises r bwds ctx (x :: Vs) subst prems)

(* Trying to complete an atomic right focus
 * 
 *    ctx |- [ mode (a, subst(ps)) ]        *)

and search_prem bwds ctx Vs subst (mode, a, ps) = 
let 
   (* Try to satisfy the premise by looking it up in the context *)
   val matched: (ctx_var * msubst) Tree.t = 
      case mode of 
         C.Lin => Tree.letMany ctx (fn hyp => match_hyp Vs subst (a, ps) hyp) 
       | C.Pers => Tree.letMany ctx (fn hyp => match_hyp [] subst (a, ps) hyp)

   (* Try to satisfy the premise by finding rules that match it *)
   val tsx = map (apply_subst subst) ps 
   val derived: (ctx_var * msubst) Tree.t =
      Tree.letMany bwds (fn bwd => search_bwd bwds ctx Vs subst (a, tsx) bwd)
in
   Tree.@ (derived, matched)
end



(*
(* tsubst(t) is a term that may not be fully ground *)
(* Try to learn as much about psubst as possible from t(tsubst) *)
fun partial_match_term (p, psubst) (t, tsubst) = 
   case p of
      

fun partial_match_termss f ([], psubst) ([], tsubst) = SOME psubst
  | partial_matches f (p :: ps, psubst) (t :: ts, tsubst) = 
      (Option.mapPartial 
         (fn subst => partial_matches f (ps, subst) (ts, tsubst))
         (partial_match (p, psubst) (t, tsubst)))
  | partial_matches _ _ = 
      (raise Fail ("partial_matches: arities don't match for "^f))

 *)
(*
fun backward_chain_rule {name, pivars, head, subgoals} term subst =
let
   val t = 
  (case partial_match pivars head (prem, subst) of
      NONE => Tree.N
    | SOME subst => 
*)

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

fun apply_transition (FC {prog, ctx = {concrete, next}}) {r, tms, S} =
let

   (* Remove linear identifiers from context *)
   val concrete = 
      List.filter (fn (x, a) => C.Pers = #1 a orelse not (is_in x S)) concrete

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
