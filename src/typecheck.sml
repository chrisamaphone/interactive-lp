structure TypeCheck = 
struct
   structure CS = CSyn
   structure S = Signature

   fun pair f {tms, tps} = 
      case (tms, tps) of 
         ([], []) => []
       | (tm :: tms, tp :: tps) => (tm, tp) :: pair f {tms = tms, tps = tps}
       | ([], _) => raise Fail (f^" was given too few arguments, needs "^
                                Int.toString (length tps)^" more")
       | (_, []) => raise Fail (f^" was given "^Int.toString (length tms)^
                                " too many arguments")

   fun expectedNot id expected decl = 
      case decl of
         NONE => raise Fail ("Expected a "^expected^", but "^id^" is undefined")
       | SOME decl => raise Fail ("Expected a "^expected^
                                  ", but "^id^" is a "^S.describe decl)
      

   (*** Variables ***)

   (* Variables are handled in a (relatively inefficient) imperative
    * style. A vartp of NONE means that, in this position, we're not
    * allowing any non-ground terms. Otherwise, a vartp is an
    * association list from identifiers to types, with placeholders
    * standing in for wildcards. *)

   type vartp = {id: Ceptre.ident option, tp: Ceptre.ident} list ref option

   fun addVar (vartp: vartp) tp = 
      case vartp of 
         NONE => raise Fail ("Cannot have a wildcard here")
       | SOME vars => length (!vars) 
                      before (vars := !vars @ [ {id = NONE, tp = tp} ])

   fun checkVarList (n, vars) newid newtp =
      case vars of 
         [] => (n, [ {id = SOME newid, tp = newtp} ])
       | {id, tp} :: vars' =>
           (if id <> SOME newid
               then let 
                       val (n', vars') = checkVarList (n+1, vars') newid newtp
                    in 
                       (n', {id = id, tp = tp} :: vars') 
                    end
            else if tp = newtp 
               then (n, vars)
            else raise Fail (newid ^" cannot have type "^newtp^" because it "^
                             "was elsewhere inferred to have type "^tp))

   fun checkVar (vartp: vartp) id tp = 
      case vartp of
         NONE => raise Fail ("Cannot have an unbound variable "^id^" here")
       | SOME vars => 
         let val (n, vars') = checkVarList (0, !vars) id tp
         in 
            vars := vars';
            n 
         end

   fun synthVar (vartp: vartp) newid = 
      case vartp of 
         NONE => raise Fail ("Cannot have an unbound variable "^newid^" here")
       | SOME vars => 
            Option.map #tp (List.find (fn {id, tp} => id = SOME newid) (!vars))



   (*** First order data ***)

   fun checkIsType signat id: Ceptre.ident = 
      case S.find signat (S.FIRST, id) of
         SOME (S.TypeDecl _) => id
       | decl => expectedNot id "type" decl

   fun getNatType signat = 
      case S.find signat (S.BUILTIN, "NAT") of 
         NONE => raise Fail ("Integer literal used, but builtin NAT "^
                             "is not defiend.")
       | SOME (S.BuiltinDecl (tp, Ceptre.NAT)) => tp
       | _ => raise Fail ("Ill-formed signatre (internal error: NAT)")

   (* Just checks the outer layer of a term for the purported type.
    * NOT FULL TYPE SYNTHESIS *)
   fun synthTerm signat vartp tm = 
      case tm of 
         CS.Fn (f, tms) => 
           (case S.find signat (S.FIRST, f) of
               SOME (S.ConstDecl (_, _, tp)) => SOME tp
             | decl => expectedNot f "constant" decl)
       | CS.Var id => Option.mapPartial (synthVar vartp) id
       | CS.ILit i => SOME (getNatType signat)
       | CS.SLit s => raise Fail ("No type for string literals") 

   fun checkTerm signat vartp (tm, tp) = 
      case tm of 
          CS.Fn (f, tms) => 
            (case S.find signat (S.FIRST, f) of 
                SOME (S.ConstDecl (_, tps, tp')) =>
                  (if tp <> tp' 
                      then raise Fail (f^" has type "^tp'^
                                       ", but we expected a "^tp^" here")
                   else Ceptre.Fn (f, map (checkTerm signat vartp)
                                         (pair f {tms = tms, tps = tps})))
              | decl => expectedNot f "constant" decl)
        | CS.Var NONE => Ceptre.Var (addVar vartp tp)
        | CS.Var (SOME id) => Ceptre.Var (checkVar vartp id tp)
        | CS.ILit i => 
            (if getNatType signat = tp 
                then Ceptre.ILit i
             else raise Fail ("Integer literals have type "^getNatType signat^
                              ", but we expected a "^tp^" here"))
        | CS.SLit s => raise Fail ("No type for string literals")



   (*** Propositions and rules ***)

   fun synthMatchingTerms signat vartp thing (tm1, tm2) =
      case (synthTerm signat vartp tm1, synthTerm signat vartp tm2) of
          (NONE, NONE) => raise Fail ("Cannot synthesize type of either \
                                      \term being compared for "^thing)
        | (SOME tp, NONE) => tp
        | (NONE, SOME tp) => tp
        | (SOME tp, SOME tp') => 
             if tp = tp' then tp 
             else raise Fail ("The types being compared for "^thing^" don't "^
                              "match: left hand side has type "^tp^
                              ", right hand side has type "^tp')
                        
   fun checkPrem signat vartp isTop prem = 
      case prem of 
         CS.Eq (tm1, tm2) =>
         let val tp = synthMatchingTerms signat vartp "equality" (tm1, tm2)
         in Ceptre.Eq (checkTerm signat vartp (tm1, tp), 
                       checkTerm signat vartp (tm2, tp))
         end
       | CS.Neq (tm1, tm2) =>
         let val tp = synthMatchingTerms signat vartp "inequality" (tm1, tm2)
         in Ceptre.Neq (checkTerm signat vartp (tm1, tp), 
                        checkTerm signat vartp (tm2, tp))
         end
       | CS.Tensor (prem1, prem2) => 
            Ceptre.Tensor (checkPrem signat vartp isTop prem1, 
                           checkPrem signat vartp isTop prem2)
       | CS.One => Ceptre.One

       (* Special top-level premises *)
       | CS.Atom (Ceptre.Lin, "qui", []) => 
            if isTop then Ceptre.Atom (Ceptre.Lin, "qui", [])
            else raise Fail ("'qui' can only appear in top-level rules")
       | CS.Atom (_, "qui", []) => 
            raise Fail ("'qui' must be linear predicate with no arguments")
       | CS.Atom (Ceptre.Lin, "stage", [ CS.Fn (stage, []) ]) =>
           ((* case S.find signat (S.STAGE, stage) of
               SOME (S.StageDecl _) => *)
                  if isTop 
                     then Ceptre.Atom (Ceptre.Lin, "stage", 
                                       [ Ceptre.Fn (stage, []) ])
                  else raise Fail ("'stage' can only appear in top-level rules")
            (* | decl => expectedNot stage "stage" decl*))
       | CS.Atom (_, "stage", _) =>
            raise Fail ("'stage' must be a linear predicate with one argument")

       | CS.Atom (mode, a, tms) =>  
           (case S.find signat (S.PRED, a) of 
               SOME (S.PredDecl (_, _, Ceptre.Act)) =>
                  raise Fail (a^" is an action predicate and cannot appear "^
                              "in a premise/left-hand side")
             | SOME (S.PredDecl (_, tps, _)) =>
                  Ceptre.Atom (mode, a, map (checkTerm signat vartp) 
                                            (pair a {tms = tms, tps = tps}))
             | decl => expectedNot a "predicate" decl)

   fun checkConcAtom signat vartp isTop (mode, a, tms) =
      case S.find signat (S.PRED, a) of 
         SOME (S.PredDecl (_, _, Ceptre.Sense)) =>
            raise Fail (a^" is an sensing predicate and cannot appear in a "^
                        "conclusion/right-hand side")
       | SOME (S.PredDecl (_, _, Ceptre.Bwd)) =>
            raise Fail (a^" is a backward-chaining predicate and "^
                        "cannot appear in a conclusion/right-hand side")
       | SOME (S.PredDecl (_, tps, _)) =>
            (mode, a, map (checkTerm signat vartp) (pair a {tms=tms, tps=tps}))
       | decl => (* Special top-level conclusions *)
            (case (mode, a, tms) of 
                (Ceptre.Lin, "stage", [ CS.Fn (stage, []) ]) =>
                  ((*case S.find signat (S.STAGE, stage) of 
                      SOME (S.StageDecl _) => *)
                         if isTop then (Ceptre.Lin, a, [Ceptre.Fn (stage, [])])
                         else raise Fail ("'stage' can only appear in "^
                                          "top-level rules")
                   (* | decl => expectedNot stage "stage" decl*))
              | (_, "stage", _) => 
                   raise Fail ("'stage' must be a linear predicate with "^
                               "one argument")
              | _ => expectedNot a "predicate" decl)

   fun checkCtxAtom signat (mode, a, tms) = 
      case S.find signat (S.PRED, a) of
         SOME (S.CtxDecl (_, atoms)) => atoms
       | SOME (S.PredDecl (_, tps, Ceptre.Prop)) =>
            [ (mode, a, map (checkTerm signat NONE)
                           (pair a {tms=tms, tps=tps})) ]
       | SOME (S.PredDecl (_, _, class)) => 
            raise Fail ("Context must contain only predicates declared as "^
                        "'pred', but "^a^" is a "^Ceptre.pclassToString class)
       | decl => expectedNot a "predicate" decl 

   fun checkRule signat isTop {name, lhs, rhs} = 
   let
      val vartp = ref []
      val lhs = checkPrem signat (SOME vartp) isTop lhs
      val pivars = length (!vartp)
      val rhs = map (checkConcAtom signat (SOME vartp) isTop) rhs
      val () = if length (!vartp) = pivars then () 
               else raise Fail ("Variable "^(case #id (List.last (!vartp)) of
                                                NONE => "wildcard"
                                              | SOME id => id)^
                                " bound in conclusion of "^name^
                                " but not in premise")
   in
      {name = name, pivars = pivars, lhs = lhs, rhs = rhs}
   end

   fun checkBwd signat {name, subgoals, head = (a, tms)} =
   let 
      val vartp = ref []
      val tms = 
         case S.find signat (S.PRED, a) of
            SOME (S.PredDecl (_, tps, Ceptre.Bwd)) =>
               map (checkTerm signat (SOME vartp)) (pair a {tms=tms, tps=tps})
          | decl => expectedNot a "backward-chaining predicate" decl
      val subgoals = checkPrem signat (SOME vartp) false subgoals
   in
      {name = name, pivars = length (!vartp),
       head = (a, tms), 
       subgoals = subgoals}
   end

   fun checkStage signat body = 
      (* XXX TODO check that rule names in body are unique! *)
      map (checkRule signat false) body

   (*** Signatures ***)

   fun checkUnique signat id desc decl: S.topdecl =
      case S.find signat id of 
         SOME decl =>
            raise Fail ("Cannot redefine "^(#2 id)^" as a "^desc^"; that "^
                        "identifier is already used as a "^S.describe decl)
       | NONE => (* Check reserved namespaces *)
            (case id of 
                (S.PRED, "qui") => 
                   raise Fail ("'qui' cannot be declared as a predicate") 
              | (S.PRED, "stage") => 
                   raise Fail ("'stage' cannot be declared as a predicate")
              | _ => decl)

   fun typecheckDecl signat csyn =
      case csyn of
         CS.CStage {name, body} => checkUnique signat (S.STAGE, name) "stage" 
           (S.StageDecl (name, checkStage signat body))
       | CS.CRule fwd => checkUnique signat (S.RULE, #name fwd) "rule" 
           (S.FwdRuleDecl (checkRule signat true fwd))
       | CS.CCtx (name, ctx) => checkUnique signat (S.PRED, name) "context"
           (S.CtxDecl (name, List.concat (map (checkCtxAtom signat) ctx)))
       | CS.CTrace _ => (* XXX TODO CHECK WELL-FORMEDNESS OF TRACE DECL *)
           (S.TraceDecl ())
       | CS.CType ty => checkUnique signat (S.FIRST, ty) "type" 
           (S.TypeDecl ty)
       | CS.CPred (a, tys, cls) => checkUnique signat (S.PRED, a) "predicate" 
           (S.PredDecl (a, map (checkIsType signat) tys, cls))
       | CS.CConst (c, tys, cls) => checkUnique signat (S.FIRST, c) "constant"
           (S.ConstDecl (c, map (checkIsType signat) tys, 
                         checkIsType signat cls))
       | CS.CBwd bwd => checkUnique signat (S.RULE, #name bwd) "rule"
           (S.BwdRuleDecl (checkBwd signat bwd))
       | CS.CBuiltin (a, Ceptre.NAT) =>
           (case (S.find signat (S.FIRST, a), 
                  S.find signat (S.BUILTIN, "NAT")) of 
               (_, SOME _) => raise Fail "NAT builtin already defined"
             | (SOME (S.TypeDecl _), NONE) => S.BuiltinDecl (a, Ceptre.NAT)
             | (decl, NONE) => expectedNot a "type" decl)
       | CS.CBuiltin (c, Ceptre.NAT_ZERO) =>
           (case (S.find signat (S.FIRST, c), 
                  S.find signat (S.BUILTIN, "NAT_ZERO"),
                  S.find signat (S.BUILTIN, "NAT")) of
               (_, _, NONE) => raise Fail "NAT builtin not yet defined" 
             | (_, SOME _, _) => raise Fail "NAT_ZERO builtin already defined"
             | (SOME (S.ConstDecl (_, [], nat)), NONE, 
                SOME (S.BuiltinDecl (declared_nat, Ceptre.NAT))) =>
                 (if nat = declared_nat 
                     then S.BuiltinDecl (c, Ceptre.NAT_ZERO)
                  else raise Fail "Wrong type for this to be NAT_ZERO")
             | (SOME (S.ConstDecl _), NONE, _) =>
                  raise Fail ("NAT_ZERO builtin must have zero arguments")
             | (decl, NONE, _) => expectedNot c "constant" decl)
       | CS.CBuiltin (c, Ceptre.NAT_SUCC) =>
           (case (S.find signat (S.FIRST, c),
                  S.find signat (S.BUILTIN, "NAT_SUCC"),
                  S.find signat (S.BUILTIN, "NAT")) of
               (_, _, NONE) => raise Fail "NAT builtin not yet defined"
             | (_, SOME _, _) => raise Fail "NAT_ZERO builtin already defined"
             | (SOME (S.ConstDecl (_, [nat1], nat2)), NONE,
                SOME (S.BuiltinDecl (declared_nat, Ceptre.NAT))) => 
                 (if nat1 = declared_nat andalso nat1 = nat2
                     then S.BuiltinDecl (c, Ceptre.NAT_SUCC)
                  else raise Fail "Wrong type for this to be NAT_SUCC")
             | (SOME (S.ConstDecl _), NONE, _) =>
                  raise Fail "NAT_SUCC builtin must have one argument"
             | (decl, NONE, _) => expectedNot c "constant" decl)
       | CS.CStageMode (stage, nondet_mode) => 
           (case S.find signat (S.STAGE, stage) of
               SOME (S.StageDecl _) => S.StageModeDecl (stage, nondet_mode)
             | decl => expectedNot stage "stage" decl)
end
