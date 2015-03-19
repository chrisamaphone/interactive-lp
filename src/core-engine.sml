structure CoreEngine:>
sig
   type ctx_var
   type transition
   type fastctx
   type sense = fastctx * Ceptre.term list -> Ceptre.term list list

   val transitionToString : transition -> string
   
   (* Turns a program and a context into a fast context *)
   val init: (string * sense) list 
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
{r: Ceptre.ident, tms : Ceptre.term vector, S: ctx_var list}

  fun vectorToList v = 
    List.tabulate (Vector.length v, fn i => Vector.sub (v, i))

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
   datatype 'a t = N | L of 'a | C of 'a t * 'a t
   fun N @ t = t
     | t @ N = t
     | t @ s = C (t, s) 

   fun flatten' t acc = 
      case t of 
         N => acc
       | L x => (x :: acc)
       | C (t1, t2) => flatten' t1 (flatten' t2 acc) 

   val flatten = fn t => flatten' t []

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
   lmap: fast_ruleset M.dict,
   rmap: C.atom list M.dict}

type ctx = 
  {next: ctx_var,
   concrete: (ctx_var * C.atom) list}

datatype fastctx = 
   FC of {prog: fastctx prog, 
          ctx: ctx}

type sense = fastctx * Ceptre.term list -> Ceptre.term list list
                               
fun init senses prog initial_ctx: fastctx = 
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


(* Matching of a pattern (C.term) against a ground term *)
fun match_term (p: C.term, t: C.term) (subst: msubst): msubst option = 
   case (p, t) of 
      (C.Var n, t) =>
        (case Vector.sub (subst, n) of 
            NONE => SOME (Vector.update (subst, n, SOME t))
          | SOME t' => 
               if t = t' then SOME subst else NONE)
    | (C.Fn (f, ps), C.Fn (g, ts)) => 
         if f = g then match_terms (f, ps, ts) subst else NONE
    | _ => NONE

and match_terms (f, ps, ts) subst: msubst option = 
   case (ps, ts) of
      ([], []) => SOME subst
    | (p :: ps, t :: ts) => 
         Option.mapPartial
            (match_terms (f, ps, ts)) 
            (match_term (p, t) subst)
    | _ => raise Fail ("Arity error for "^f)

fun is_in x exclude = List.exists (fn y => x = y) exclude
 
fun match_hyp exclude subst (a, ps) (x, (m, b, ts)) =
   if a = b andalso not (is_in x exclude)
      then Option.map (fn subst => (x, subst)) (match_terms (a, ps, ts) subst)
   else NONE


(* Search the context for all (non-excluded) matches *)
fun search_context ctx used subst prem = 
   case prem of 
      (C.Lin, a, ps) => List.mapPartial (match_hyp used subst (a, ps)) ctx
    | (C.Pers, a, ps) => List.mapPartial (match_hyp [] subst (a, ps)) ctx

fun search_premises rule ctx used subst prems = 
   case prems of 
      [] => Tree.L {r = rule, tms = Vector.map valOf subst, S = rev used}
    | prem :: prems => 
         List.foldl 
            (Tree.append (fn (x, subst) => 
               search_premises rule ctx (x :: used) subst prems))
            Tree.N (search_context ctx used subst prem)

val unknown = fn n => Vector.tabulate (n, fn _ => NONE)

fun possible_steps stage (FC {prog = {lmap, ...}, ctx = {concrete, ...}}) =
   case M.find lmap stage of
      NONE => raise Fail ("Stage "^stage^" unknown to the execution engine")
    | SOME ruleset => 
        (Tree.flatten
           (List.foldl 
              (Tree.append (fn {name, pivars, lhs} =>
                 (search_premises name concrete [] (unknown pivars) lhs)))
              Tree.N ruleset))


fun ground gsubst ps = 
   case ps of 
      C.Var i => Vector.sub (gsubst, i)
    | C.Fn (a, ts) => C.Fn (a, map (ground gsubst) ts)

fun add_to_ctx gsubst ((mode, a, ps), ({next, concrete}, xs)) = 
  ({next = next + 1, 
    concrete = (next, (mode, a, map (ground gsubst) ps)) :: concrete},
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
