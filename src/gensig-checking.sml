(*
* First-order, flat-language-based generative invariant checking.
* - Chris Martens, 11/11/2014
*
*)

structure Check = (* : GENSIG_CHECKING = *)
struct

  open LinearLogicPrograms

  (* flat languages *)
  datatype word =
      ONCE of rname
    | REPEAT of rname
  datatype flat = 
      EMPTY 
    | SEQ of word * flat
    | BRANCH of flat * flat

  (* helper fns (things that don't belong in util because they're dependent on
  * types defined in this module) *)
  
  open Util

  fun isvar (AT x) = x < 0
    | isvar _ = false

  (* is the predicate name in 2 atoms the same? *)
  fun eqpred (AP (p, _)) (AP (p', _)) = p = p'
    | eqpred (AT a) (AT a') = a = a'
    | eqpred _ _ = false

  fun memberModuloArgument pred =
    List.exists (fn p => eqpred p pred)

  fun langFromList [] = EMPTY
    | langFromList (w::ws) = SEQ (w, langFromList ws)

  fun just w = SEQ (ONCE w, EMPTY)

  fun lookup GI rname =
    case GI of
         [] => NONE
       | (r::GI') => 
           (case r of (rname', pi, lhs, exists, rhs) => 
            if rname = rname' then SOME (pi, lhs, exists, rhs) 
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
    
  
  (* Gensyms for context variables. *)
  val sym = ref ~1
  fun gensym () = !sym before sym := !sym - 1

  (* Unification *)

  type sub = int * context
  structure CM = CommutativeMonoid
  
  (* XXX modify to unify vars in terms *)
  (* unifyCtx : context * (int option) -> context * (int option) -> sub list option *)
  fun unifyCtx (ctx1:atom list, NONE) (ctx2:atom list, NONE) = 
        if CM.eq ctx1 ctx2 then SOME [] else NONE
    | unifyCtx (ctx1, SOME var1) (ctx2, NONE) =
        (* check ctx1 <= ctx2; unify var1 with ctx2-ctx1 *)
        (case CM.diff ctx2 ctx1 of
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
        (case CM.diff ctx1 ctx2 of
              NONE => NONE
            | SOME ctx1m2 =>
                let
                  val var2' = gensym ()
                in
                  SOME [(var2, ctx1m2)]
                end)
    | unifyCtx (ctx1:atom list, SOME var1) (ctx2:atom list, SOME var2) =
       (* should always succeed.
       *  var1 |-> var, ctx2 - (ctx1 intersect ctx2)
       *  var2 |-> var, ctx1 - (ctx1 intersect ctx2)
       *)
       let
         val var = gensym()
         val ctx1' = CM.xnor ctx2 ctx1
         val ctx2' = CM.xnor ctx1 ctx2
       in
         SOME [(var1, (AT var)::ctx1'), (var2, (AT var)::ctx2')]
       end

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


  (*** Inversion ***)

  (* firstSplits : gensig -> flat -> context -> (context * flat * context) list
  *                 -> (context * flat * context) list
  * (4th arg is an accumulator; call at top-level with firstSplits .. .. .. []) 
  *
  * This function decides how a rhs should be split at first (to be called
  * recursively in the "invs" function).
  * 
  **)
  fun firstSplits GI L rhs prefix =
  (* returns a list of triples (L1, w, L2) 
  *   where w produces some atom in the rhs
  *   and L1 and L2 are the languages matching what comes before & after w in L.
  * *)
    case L of
         EMPTY => []
       | SEQ (ONCE w, L') =>
           let
             (* XXX do what w/pivars, exvars? *)
             val SOME (pivars, ants, exvars, sucs) = lookup GI w
             val ts = overlap sucs rhs
           in
             case ts of
                  [] => firstSplits GI L' rhs (seqSnoc prefix (ONCE w))
                | _ => [(prefix, w, L')]
           end
       | SEQ (REPEAT w, L') =>
           let
             (* XXX do what w/pivars, exvars? *)
             val SOME (pivars, ants, exvars, sucs) = lookup GI w
             val ts = overlap sucs rhs
           in
             case ts of
                  [] => firstSplits GI L' rhs (seqSnoc prefix (REPEAT w))
                | _ => [(seqSnoc prefix (REPEAT w), w, SEQ(REPEAT w, L'))]
           end
       | BRANCH (L1, L2) => 
           (firstSplits GI L1 rhs prefix)@(firstSplits GI L2 rhs prefix)
  
  fun checkLangReach GI (start:atom list, L, final:atom list) = 
    case L of
        EMPTY => (* if L is empty, make sure start and final are unifiable. *)
            unifyCtx (separate start) (separate final)
      | _ => SOME [] (* postpone deciding. *)
        
  fun matchTrace (GI:gensig) (start, final) (L1, w, L2) =
  (* matches a trace type (start, final) with a split lang (L1, w, L2) *)
  (* returns a ((ctx * lang * ctx) * (ctx * lang * ctx)) option *)
      let
        (* XXX what to do about pivars and exvars? *)
        val SOME (pivars, ant, exvars, sucs) = lookup GI w
        val theta = gensym ()
        val pre  = (start, L1, [AT theta, ant])
        val middle = (AT theta)::sucs
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

  (* invs : gensig -> flat -> multistep -> inversions *)
  (* invs GI L (start, end) =>
  *    NONE       if no trace exists from start to end 
  *  | SOME invs  if (start, end) splits into invs where invs has the form
  *                 (start, s1), (s1', s2), ..., (sn, end)
  *)
  fun invs (GI:gensig) L (lhs : atom list, rhs : atom list) =
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
  (* XXX this just reshuffles args; probably not needed... *)
  fun invert (gen, (GI:gensig)) L ts = invs GI L (gen, ts)


  (*** Reachability checking ***)

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


  (*** Putting Inversion & Reachability Checking together: Rule Checking ***)

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

  (* nested inside Check *)
  structure Test = 
  struct

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
    val ctx1 = map (fn x => AT x) [a, a, b, c]
    val ctx2 = map (fn x => AT x) [c, c, c, a, c, c, c]
    val del1 = AT (gensym())
    val del2 = AT (gensym())
    val test_unify = unifyCtx (ctx1, SOME del1) (ctx2, SOME del2)


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


    (* from (int * (int list)) rules to the general first-order form of gensig rules *)
    fun simple (name, ant, sucs) =
      (name, 0, AT ant, 0, map (fn x => AT x) sucs)

    val gensig1 : gensig =
      map simple
      [("g1", gen, [a, cs]),
        ("g2", gen, [b, cs]),
        ("g3", cs, [c, cs]),
        ("g4", cs, [])]

    val gensig2 : gensig =
      map simple
      [("g1", gen, [b, c]),
      ("g2", gen, [a]),
      ("g3", gen, [a, cs]),
      ("g4", cs, [c, cs]),
      ("g5", cs, [c])]

    val gensig3 : gensig =
      map simple
      [("g1", gen, [b, c, c]),
      ("g2", gen, [a, cs]),
      ("g3", cs, [c, cs]),
      ("g4", cs, [c])]


    val del = gensym ()

    (* g1 | (g2g3*g4) *)
    val lang3 : flat = BRANCH (SEQ (ONCE "g1", EMPTY), 
                              SEQ (ONCE "g2", SEQ (REPEAT "g3", SEQ (ONCE "g4",
                                EMPTY))))

    fun abcs_invert_test () = invert ([AT gen], gensig3) lang3 
      [AT del, AT a, AT c, AT c]


    val fptp_prop : gensig =
      [("g1", 0, AT gen, 0, [AT genc, AT gen]),
      ("g2", 0, AT genc, 0, [AT nvotes, AT genb]),
      ("g3", 0, AT genb, 0, [AT ballot, AT genb]),
      ("g4", 0, AT genb, 0, [])]

    val fptp_fo : gensig =
      [("g1", 0, AT gen, 1, [AP ("genc", [LOCAL 0]), AT gen]),
      ("g2", 2, AP ("genc", [LOCAL 0]), 0, [AP ("nvotes", [LOCAL 0, LOCAL 1]),
                                            AP ("genb", [LOCAL 0])]),
      ("g3", 1, AP ("genb", [LOCAL 0]), 0, [AP ("ballot", [LOCAL 0]),
                                            AP ("genb", [LOCAL 0])]),
      ("g4", 1, AP ("genb", [LOCAL 0]), 0, [])]

    val lang_fptp : flat = (* g1*g2*g3*g4* *)
      SEQ (REPEAT "g1", SEQ (REPEAT "g2", SEQ (REPEAT "g3", SEQ (REPEAT "g4",
      EMPTY))))


    fun fptp_invert_test () = 
      invert ([AT gen], fptp_prop) lang_fptp [AT del, AT nvotes]

    (* testing language prefix *)
    val l1 = langFromList [ONCE "g2", REPEAT "g3", ONCE "g4"]
    val l2 = langFromList [ONCE "g2"]
    val l3 = langFromList [ONCE "g2", REPEAT "g3"]
    val l4 = langFromList [ONCE "g2", ONCE "g3"]


    val gensig_blocksworld : gensig = 
      [("g1", 0, AT gen, 1, 
          [AT gen, AP ("genblocks", [LOCAL 0]), AP ("ontable", [LOCAL 0]) ]),
       ("g2", 1, AP ("genblocks", [LOCAL 0]), 0, [AP ("clear", [LOCAL 0])]),
       ("g3", 1, AP ("genblocks", [LOCAL 0]), 1,
          [AP ("on", [LOCAL 1, LOCAL 0]), AP ("genblocks", [LOCAL 1])]),
       ("g4", 0, AT gen, 1, [AP ("arm_holding", [LOCAL 0])]),
       ("g5", 0, AT gen, 0, [AP ("arm_free", [])])]
    

    (* testing buildTrace *)

  end


end

