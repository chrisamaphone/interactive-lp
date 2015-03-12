structure CoreEngine:>
sig
   type fastctx
   type sense = Ceptre.context * Ceptre.ground_term list 
                -> Ceptre.ground_term list list

   (* Turns a program and a context into a fast context *)
   val init: (string * sense) list 
             -> Ceptre.phase list 
             -> Ceptre.context 
             -> fastctx

   (* A fast context is just a context with some extra stuff *)
   val context: fastctx -> Ceptre.context
  
   (* Given a ruleset identifier, find all transitions in the given context *)
   val possible_steps: Ceptre.ident -> fastctx -> Ceptre.transition list

   (* Run a given transition *)
   val apply_transition: 
      fastctx -> Ceptre.transition -> fastctx * Ceptre.context_var list

   val insert: fastctx 
               -> Ceptre.ident * Ceptre.ground_term list
               -> fastctx * Ceptre.context_var

   val remove: fastctx -> Ceptre.context_var -> fastctx

end = 
struct

val insert = fn _ => raise Fail "Not implemented"
val remove = fn _ => raise Fail "Not implemented"

local
   val i = ref 0
in
val gen = fn () => (!i before i := !i + 1)
fun check (x, a, ts) = i := Int.max (!i, x + 1)
end

datatype 'a tree = N | L of 'a | C of 'a tree * 'a tree
fun N @ t = t
  | t @ N = t
  | t @ s = C (t, s) 

fun flatten t acc = 
   case t of 
      N => acc
    | L x => (x :: acc)
    | C (t1, t2) => flatten t1 (flatten t2 acc) 

val fl = fn t => flatten t []

structure C = Ceptre
structure S = IntRedBlackSet
structure M = StringRedBlackDict

type sense = Ceptre.context * Ceptre.ground_term list 
             -> Ceptre.ground_term list list

type fast_ruleset = {name: C.ident, pivars: int, lhs: C.atom list} list

(* LHSes are connected to a particluar ruleset *)
(* RHSes are just mapped from their names *)
type fastctx = 
   {senses: sense M.dict,
    lmap: fast_ruleset M.dict, 
    rmap: C.atom list M.dict,
    ctx: C.context}
                               
fun init senses prog ctx: fastctx = 
let
   fun compile_lhses {name, body} = 
      (name, 
       List.map
          (fn {name, pivars, lhs, rhs} => 
              {name = name, pivars = pivars, lhs = lhs})
          body)
   fun compile_rhses ({name, body}: C.phase, map) = 
      List.foldl 
          (fn ({name, rhs, ...}, rmap) => 
              M.insert rmap name rhs)
          map body

   (* Make sure gensyms don't collide *)
   val () = app check (#pers ctx)
   val () = app check (#lin ctx)
in
   {senses = List.foldl (fn ((k, v), m) => M.insert m k v)
                M.empty senses,
    lmap = List.foldl (fn ((k, v), m) => M.insert m k v)
              M.empty (map compile_lhses prog),
    rmap = List.foldl compile_rhses 
              M.empty prog,
    ctx = ctx}
end
                        
fun context ({ctx, ...}: fastctx) = ctx

type msubst = C.ground_term option vector


(* Matching of a pattern (C.term) against a ground term *)
fun match_term (p: C.term, t: C.ground_term) (subst: msubst): msubst option = 
   case (p, t) of 
      (C.Var n, t) =>
        (case Vector.sub (subst, n) of 
            NONE => SOME (Vector.update (subst, n, SOME t))
          | SOME t' => 
               if t = t' then SOME subst else NONE)
    | (C.Fn (f, ps), C.GFn (g, ts)) => 
         if f = g then match_terms (f, ps, ts) subst else NONE
    (* | _ => NONE *)

and match_terms (f, ps, ts) subst: msubst option = 
   case (ps, ts) of
      ([], []) => SOME subst
    | (p :: ps, t :: ts) => 
         Option.mapPartial
            (match_terms (f, ps, ts)) 
            (match_term (p, t) subst)
    | _ => raise Fail ("Arity error for "^f)

fun is_in x exclude = List.exists (fn y => x = y) exclude
 
fun match_hyp exclude subst (a, ps) (x, b, ts) =
   if a = b andalso not (is_in x exclude)
      then Option.map (fn subst => (x, subst)) (match_terms (a, ps, ts) subst)
   else NONE


(* Search the context for all (non-excluded) matches *)
fun search_context {lin, pers} used subst prem = 
   case prem of 
      C.Lin (a, ps) => List.mapPartial (match_hyp used subst (a, ps)) lin
    | C.Pers (a, ps) => List.mapPartial (match_hyp [] subst (a, ps)) pers

fun search_premises rule ctx used subst prems = 
   case prems of 
      [] => L {r = rule, tms = Vector.map valOf subst, S = rev used}
    | prem :: prems => 
         List.foldl 
            (fn ((x, subst), ans) =>
               ans @ search_premises rule ctx (x :: used) subst prems)
            N (search_context ctx used subst prem)

val unknown = fn n => Vector.tabulate (n, fn _ => NONE)

fun possible_steps phase ({lmap, ctx, ...}: fastctx): C.transition list =
   case M.find lmap phase of
      NONE => raise Fail ("Phase "^phase^" unknown to the execution engine")
    | SOME ruleset => 
         fl (List.foldl
               (fn ({name, pivars, lhs}, ans) => 
                  ans @ search_premises name ctx [] (unknown pivars) lhs)
               N ruleset)

fun ground gsubst ps = 
   case ps of 
      C.Var i => Vector.sub (gsubst, i)
    | C.Fn (a, ts) => C.GFn (a, map (ground gsubst) ts)

fun add_to_ctx gsubst (conc, ({lin, pers}, xs)) = 
let val x = gen ()
in case conc of 
      C.Lin (a, ps) => 
         ({lin = (x, a, map (ground gsubst) ps) :: lin, pers = pers}, x :: xs)
    | C.Pers (a, ps) => 
         ({lin = lin, pers = (x, a, map (ground gsubst) ps) :: pers}, x :: xs)
end

fun apply_transition ({lmap, rmap, ctx = {pers, lin}, senses}: fastctx) {r, tms, S} =
let
   (* Remove linear identifiers from context *)
   val lin = List.filter (fn (x, _, _) => not (is_in x S)) lin

   (* Find right hand side pattern hand side *)
   val rhs =
      case M.find rmap r of
         NONE => raise Fail ("Error lookuing up rhs of rule "^r)
       | SOME rhs => rhs

   (* Update context, get new identifiers *)
   val (ctx, xs) = 
      List.foldr (add_to_ctx tms) ({pers = pers, lin = lin}, []) rhs
in
   ({lmap = lmap, rmap = rmap, ctx = ctx, senses = senses}, xs)
end

end
