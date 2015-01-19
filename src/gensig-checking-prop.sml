(*
* Propositional case of generative signature checking.
* Chris Martens, cmartens@cs.cmu.edu
* Snapshot Friday, November 7, 2014:
*   - inversions seem to work properly!
*   - buildTrace loops, though. currently very naive and broken implementation.
*)

structure Check = (* : GENSIGS = *)
struct

  type atom = int

  type rname = string
  type genrule = rname * (atom list) * (atom list)
  type gensig = genrule list
  type context = atom list
  type multistep = (atom list) * (atom list)

  type state_transition = atom * (atom list) * (atom option)
  type state_machine = state_transition list

  (* flat languages *)
  datatype word =
      ONCE of rname
    | REPEAT of rname
  datatype flat = 
      EMPTY 
    | SEQ of word * flat
    | BRANCH of flat * flat


  (* util *)

  fun filter_nones [] = []
    | filter_nones (NONE::L) = filter_nones L
    | filter_nones ((SOME x)::L) = x::(filter_nones L)


  fun mapi' i f [] = []
    | mapi' i f (x::xs) = (f(i,x))::(mapi' (i+1) f xs)

  fun mapi f l = mapi' 0 f l

  fun member x = List.exists (fn x' => x = x')

  fun deleteAll x = List.filter (fn x' => x <> x')

  fun deleteFirst x [] = []
    | deleteFirst x (y::ys) = if x = y then ys else y::(deleteFirst x ys)

  fun deleteFirstIfMember x [] = NONE
    | deleteFirstIfMember x (y::ys) = if x = y then SOME ys else
      (case deleteFirstIfMember x ys of
            NONE => NONE
          | SOME ys' => SOME (y::ys'))

  fun just w = SEQ (ONCE w, EMPTY)

  fun concatMap f ls = List.concat (map f ls)

  (* helper fns *)

  fun langFromList [] = EMPTY
    | langFromList (w::ws) = SEQ (w, langFromList ws)

  fun terminal a [] = true
    | terminal a ((ins, outs)::rules)
      = not (member a ins) andalso terminal a rules

  fun lookup GI rname =
    case GI of
         [] => NONE
       | (r::GI') => 
           (case r of (rname', lhs, rhs) => 
            if rname = rname' then SOME (lhs, rhs) 
            else lookup GI' rname)

  fun overlap ts1 ts2 =
    List.filter (fn t1 => List.exists (fn t2 => t1 = t2) ts2) ts1 

  fun removeOverlap ts1 ts2 =
    List.filter (fn t1 => not (List.exists (fn t2 => t1 = t2) ts2)) ts1

  fun seqSnoc EMPTY                   w = SEQ (w, EMPTY)
    | seqSnoc (SEQ (REPEAT w, EMPTY)) (REPEAT w') =
      (* collapse adjacent equal repeating sequences *)
        if w = w' then SEQ (REPEAT w, EMPTY)
                  else SEQ (REPEAT w, (SEQ (REPEAT w', EMPTY)))
    | seqSnoc (SEQ (w', L'))          w = SEQ (w', seqSnoc L' w)
    | seqSnoc (BRANCH (L1, L2)) w = raise Match (* shouldn't happen *)
    
    (*
  fun seqSnoc L w = case L of
                     EMPTY => SEQ (w, EMPTY)
                   | SEQ(w', L') => if w = w' then SEQ(w
                   | SEQ (w', L') => SEQ (w', seqSnoc L' w)
                   (* | BRANCH (L1, L2) => BRANCH (seqSnoc L1 w, seqSnoc L2 w)
                   * * this case is weird & shouldn't happen *)
                   *)


  (*** Inversion ***)

  val sym = ref ~1
  fun gensym () =
    !sym before sym := !sym - 1

  type inversions = multistep list


  fun firstSplits GI L rhs prefix =
  (* returns a list of triples (L1, w, L2) 
  *   where w produces some atom in the rhs
  *   and L1 and L2 are the languages matching what comes before & after w in L.
  * *)
    case L of
         EMPTY => []
       | SEQ (ONCE w, L') =>
           let
             val SOME (ants, sucs) = lookup GI w
             val ts = overlap sucs rhs
           in
             case ts of
                  [] => firstSplits GI L' rhs (seqSnoc prefix (ONCE w))
                | _ => [(prefix, w, L')]
           end
       | SEQ (REPEAT w, L') =>
           let
             val SOME (ants, sucs) = lookup GI w
             val ts = overlap sucs rhs
           in
             case ts of
                  [] => firstSplits GI L' rhs (seqSnoc prefix (REPEAT w))
                | _ => [(seqSnoc prefix (REPEAT w), w, SEQ(REPEAT w, L'))]
           end
       | BRANCH (L1, L2) => 
           (firstSplits GI L1 rhs prefix)@(firstSplits GI L2 rhs prefix)


  type sub = int * context

  fun ctx_eq [] [] = true
    | ctx_eq (x::xs) ys = 
      (case deleteFirstIfMember x ys of
            NONE => false
          | SOME ys => ctx_eq xs ys)
    | ctx_eq _ _ = false 

  (* commutative monoid difference *)
  fun ctx_diff C []        = SOME C
    | ctx_diff [] (c::C)   = NONE
    | ctx_diff C1 (c2::C2) =
        (case deleteFirstIfMember c2 C1 of
              NONE     => NONE
            | SOME C1' => ctx_diff C1' C2)

  (* intersection *)
  fun ctx_intersect [] _ accum = accum
    | ctx_intersect _ [] accum = accum
    | ctx_intersect (c1::C1) C2 accum =
      (case deleteFirstIfMember c1 C2 of
           NONE => ctx_intersect C1 C2 accum
         | SOME C2' => ctx_intersect C1 C2' (c1::accum)
      )

  (* complement intersect. C1 \ (C1 /\ C2) *)
  fun ctx_xnor C1 [] = C1
    | ctx_xnor [] C2 = []
    | ctx_xnor (c1::C1) C2 =
      (case deleteFirstIfMember c1 C2 of
            NONE     => c1::(ctx_xnor C1 C2)
          | SOME C2' => ctx_xnor C1 C2')
      

  (* unifyCtx : context * (int option) -> context * (int option) -> sub list option *)
  fun unifyCtx (ctx1, NONE) (ctx2, NONE) = 
        if ctx_eq ctx1 ctx2 then SOME [] else NONE
    | unifyCtx (ctx1, SOME var1) (ctx2, NONE) =
        (* check ctx1 <= ctx2; unify var1 with ctx2-ctx1 *)
        (case ctx_diff ctx2 ctx1 of
              NONE        => NONE
            | SOME ctx2m1 =>
                let
                  val var1' = gensym ()
                in
                  SOME [(var1, ctx2m1)]
                end)
    | unifyCtx (ctx1, NONE) (ctx2, SOME var2) =
        (* symmetric case to previous:
        *   check ctx2 <= ctx1; unify var2 with ctx1-ctx2 *)
        (case ctx_diff ctx1 ctx2 of
              NONE => NONE
            | SOME ctx1m2 =>
                let
                  val var2' = gensym ()
                in
                  SOME [(var2, ctx1m2)]
                end)
    | unifyCtx (ctx1, SOME var1) (ctx2, SOME var2) =
       (* should always succeed.
       *  var1 |-> var, ctx2 - (ctx1 intersect ctx2)
       *  var2 |-> var, ctx1 - (ctx1 intersect ctx2)
       *)
       let
         val var = gensym()
         val ctx1' = ctx_xnor ctx2 ctx1
         val ctx2' = ctx_xnor ctx1 ctx2
       in
         SOME [(var1, var::ctx1'), (var2, var::ctx2')]
       end

  fun isvar x = x < 0

  (* separate context into (nonvarparts, var) *)
  fun separate' [] accum = (accum, NONE)
    | separate' (x::xs) accum =
      if isvar x then (accum@xs, SOME x)
      else separate' xs (x::accum)
  fun separate C = separate' C []

  fun unseparate (C, NONE) = C
    | unseparate (C, SOME V) = V::C

  fun applySubs [] CV = CV (* identity sub *)
    | applySubs subs (C, NONE) = (C, NONE)
    | applySubs ((v, C')::subs) (C, (SOME V)) =
      if v = V then
        let
          val (C', V') = separate C'
        in
          (C@C', V')
        end
      else (C, SOME V)

  fun applySubs' subs ctx = unseparate (applySubs subs (separate ctx))

  fun applySubsToSplit subs (pre, L, post) =
    (applySubs' subs pre, L, applySubs' subs post)

  fun checkLangReach GI (start, L, final) = 
    case L of
        EMPTY => (* if L is empty, make sure start and final are unifiable. *)
            unifyCtx (separate start) (separate final)
      | _ => SOME [] (* postpone deciding. *)
        
  fun matchTrace GI (start, final) (L1, w, L2) =
  (* matches a trace type (start, final) with a split lang (L1, w, L2) *)
  (* returns a ((ctx * lang * ctx) * (ctx * lang * ctx)) option *)
      let
        val SOME (ants, sucs) = lookup GI w
        val theta = gensym ()
        val pre  = (start, L1, theta::ants)
        val middle = theta::sucs
        (* remove any overlap of final&sucs from each *)
        val post2 = removeOverlap final middle
        val post1 = removeOverlap middle final
        val post = (post1, L2, post2)
        (* check for inconsistencies & propagate constraints *)
        val subsPre = checkLangReach GI pre 
      in
        case subsPre of
             NONE => NONE
           | SOME subsPre =>
               let
                 val pre' = applySubsToSplit subsPre pre
                 val post' = applySubsToSplit subsPre post
                 val subsPost = checkLangReach GI post'
               in
                 case subsPost of
                      NONE => NONE
                    | SOME subsPost =>
                        let
                          val post'' = applySubsToSplit subsPost post'
                        in
                          SOME (pre', post'')
                        end
               end
      end

      (*
        val subsPost = checkLangReach GI post
      in 
        case (subsPre, subs) of
             (SOME pre', SOME post') => SOME (pre', post')
            | _           => NONE
      end
      *)

  (* invs : gensig -> flat -> multistep -> inversions *)
  (* invs GI L (start, end) =>
  *    NONE       if no trace exists from start to end 
  *  | SOME invs  if (start, end) splits into invs where invs has the form
  *                 (start, s1), (s1', s2), ..., (sn, end)
  *)
  fun invs GI L (lhs, rhs) =
  let
    val splits = firstSplits GI L rhs EMPTY
    val trace_splits = map (fn s => matchTrace GI (lhs, rhs) s) splits
  in
    case trace_splits of [] => [[(lhs, L, rhs)]]
       | _ =>
    let
      val splits = filter_nones trace_splits
      fun recur ((lhs, L1, mid), (mid', L2, rhs))  =
        let
          val splits' = invs GI L2 (mid', rhs)
        in
          map (fn t => (lhs, L1, mid)::(mid', L2, rhs)::t) splits'
        end
    in
      concatMap recur splits
    end
  end

  (* invert : (atom * gensig) -> context -> multistep list *)
  fun invert (gen, GI) L ts = invs GI L (gen, ts)

  fun lang_prefix L1 L2 =
    case (L1, L2) of
         (EMPTY, _) => SOME L2 
       | (_, EMPTY) => NONE
       | (SEQ (ONCE r, L1'), SEQ (ONCE r', L2')) => 
           if r = r' then lang_prefix L1' L2'
           else NONE
       | (SEQ (ONCE r, L1'), SEQ (REPEAT r', L2')) =>
           if r = r' then lang_prefix L1' (SEQ (REPEAT r', L2'))
           else lang_prefix (SEQ (ONCE r, L1')) L2'
       | (SEQ (REPEAT r, L1'), SEQ (ONCE r', L2')) => NONE
       | (SEQ (REPEAT r, L1'), SEQ (REPEAT r', L2')) =>
           if r = r' then 
             (case lang_prefix L1' L2' of
                  SOME L => SOME (SEQ (REPEAT r, L))
                | NONE => NONE)
           else lang_prefix (SEQ (REPEAT r, L1')) L2'
       | (L1, BRANCH (L2, L2')) =>
           (case lang_prefix L1 L2 of
                 NONE => lang_prefix L1 L2'
               | SOME L => SOME L)
       | (BRANCH (L1, L1'), L2) =>
           (case lang_prefix L1 L2 of
                 NONE => NONE
               | SOME L => (case lang_prefix L1' L2 of
                                 NONE => NONE
                               | SOME L' => SOME (BRANCH(L, L'))))

  (* 
  *
  * buildTrace determines whether (and how) a set of goal inversions is
  * producible from a set of input inversions.
  *
  * Each input inversion is given a name, so has the form
  * ("name", lhs, L, rhs)
  *
  * And a goal inversion is of the form
  * (lhs, L, rhs)
  *
  * The output should be a list of the same length as the set of goal
  * inversions, each element a list of "name"s comprising a derivation of the
  * goal from rules in the GI or named inversions in the input.
  *
  * buildTrace : gensig -> flat 
  *               -> (string * ctx * flat * ctx) list -> (ctx * flat * ctx) 
  *                 -> trace option
  * 
  * buildtrace GI lang input_invs goal =
  *   NONE               if goal_invs cannot be derived from input_invs
  * | SOME T  if T : lhs --L--> rhs where goal = (lhs, L, rhs)
  *)
  fun buildTrace GI input_invs (lhs, L, rhs) =
  case unifyCtx (separate lhs) (separate rhs) of
       SOME _ => SOME [] (* XXX return w/applied subs? *)
     | NONE =>
    (* pseudocode:
    * - if name:(lhs, L', mid) where L = L'L'', is in input_invs, and
    *     buildTrace GI input_invs (mid, L'', rhs) returns some T,
    *     then return name::T.
    *)
         let
           val candidates = filter_nones
            (map
              (fn (name, lhs', L', rhs') => 
                (* XXX check that lhs' <= lhs *)
                  (case lang_prefix L' L of
                        NONE => NONE
                      | SOME suffix => SOME (name, rhs', suffix)))
              input_invs)
           fun check_candidates [] = NONE
             | check_candidates ((name, rhs', suffix)::cs) =
                 (case buildTrace GI input_invs (rhs', suffix, rhs) of
                   (* XXX  this is broken and inf loops. *)
                       NONE => check_candidates cs
                     | SOME T => SOME (name::T))
         in
           check_candidates candidates
         end

  fun gensigToLang _ = raise Match (* XXX *)

  datatype response = Error of string | Yes | No

  (* checkRule : context * gensig -> rule -> response *)
  fun checkRule (gen, GI) (ant, suc) =
  (* checks if the program rule (ant, suc) preserves the generative invariant
  * induced by (gen, GI). *)
  let
    val lang = gensigToLang (gen, GI)
  in
    case lang of
        NONE      => Error "GI not well-formed"
      | SOME L =>
         let
           val invs = invert (gen, GI) L ant
  (* stage 2: check that the conclusion of the rule is provable from the initial
  * GI state ([gen] usually) or along the same flat language.
  *)
           val named_invs =
             map
             (fn inv =>
              mapi (fn (i,(x,y,z)) => ("inv"^(Int.toString i), x, y, z)) inv)
             invs
           val traces = map (fn inv => buildTrace GI inv (gen, L, suc)) named_invs
           val traces' = filter_nones traces
         in
           case traces' of [] => No | _ => Yes
         end
  end

end

structure Test = 
struct
  open Check

  val gen = 0
  val a = 1
  val b = 2
  val c = 3
  val a_or_b = 4
  val cs = 5
  val genc = 6
  val genb = 7
  val nvotes = 8
  val ballot = 9


  (* testing context unification *)
  val ctx1 = [a, a, b, c]
  val ctx2 = [c, c, c, a, c, c, c]
  val test_unify = unifyCtx (ctx1, SOME (gensym())) (ctx2, SOME (gensym ()))


  (* testing specific GIs *)

  (* Generative signature:
  * gen -o {a_or_b * cs}.
  * a_or_b -o {a}.
  * a_or_b -o {b}.
  * cs -o {c * cs}.
  * cs -o {1}.
  *)

  (*
  val gensig : gensig =
     [([gen], [a_or_b, cs]),
     ([a_or_b], [a]),
     ([a_or_b], [b]),
     ([cs], [c, cs]),
     ([cs], [])]
  *)
  val gensig : gensig =
     [("g1", [gen], [a, cs]),
     ("g2", [gen], [b, cs]),
     ("g3", [cs], [c, cs]),
     ("g4", [cs], [])]

  val gensig2 : gensig =
    [("g1", [gen], [b, c]),
     ("g2", [gen], [a]),
     ("g3", [gen], [a, cs]),
     ("g4", [cs], [c, cs]),
     ("g5", [cs], [c])]

  val gensig3 : gensig =
    [("g1", [gen], [b, c, c]),
     ("g2", [gen], [a, cs]),
     ("g3", [cs], [c, cs]),
     ("g4", [cs], [c])]
  
  val del = gensym ()

  (* g1 | (g2g3*g4) *)
  val lang3 : flat = BRANCH (SEQ (ONCE "g1", EMPTY), 
                             SEQ (ONCE "g2", SEQ (REPEAT "g3", SEQ (ONCE "g4",
                              EMPTY))))

  fun abcs_invert_test () = invert ([gen], gensig3) lang3 [del, a, c, c]


  val fptp : gensig =
    [("g1", [gen], [genc, gen]),
     ("g2", [genc], [nvotes, genb]),
     ("g3", [genb], [ballot, genb]),
     ("g4", [genb], [])]

  val lang_fptp : flat = (* g1*g2*g3*g4* *)
    SEQ (REPEAT "g1", SEQ (REPEAT "g2", SEQ (REPEAT "g3", SEQ (REPEAT "g4",
    EMPTY))))


  fun fptp_invert_test () = invert ([gen], fptp) lang_fptp [del, nvotes]

  (* testing language prefix *)
  val l1 = langFromList [ONCE "g2", REPEAT "g3", ONCE "g4"]
  val l2 = langFromList [ONCE "g2"]
  val l3 = langFromList [ONCE "g2", REPEAT "g3"]
  val l4 = langFromList [ONCE "g2", ONCE "g3"]

  (* XXX test branching lang prefix *)

  (* testing buildTrace *)


end
