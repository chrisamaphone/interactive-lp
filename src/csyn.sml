(* Transfers the very general parsed syntax to Ceptre's syntax. 
 * 
 * The objective of this file is really to do as little as possible:
 * the only transformation that happens is desugaring the $ syntax. *)

structure CSyn =
struct
   structure C = Ceptre
   structure P = Parse

   (* Utility functions *)

   local 
      val set = ref StringRedBlackSet.empty
      val gensym_ctr = ref 0
   in
   fun remember s = set := StringRedBlackSet.insert (!set) s
   fun gensym () = 
   let
      val count = !gensym_ctr
      val name = "anon" ^ (Int.toString count)
      val () = gensym_ctr := count + 1
   in
      if StringRedBlackSet.member (!set) name
         then gensym ()
      else (remember name; name)
   end
   end
 
   fun caps s =
      case String.explode s of
         [] => raise Fail ("caps called on empty identifier (internal)")
       | (c::_) => Char.isUpper c

   (* Syntax *)

   datatype term =
      Fn of C.ident * term list 
    | Var of C.ident option
    | SLit of string
    | ILit of IntInf.int
   type atom = C.mode * C.pred * (term list)
   datatype prem = 
      Eq of term * term
    | Neq of term * term
    | Tensor of prem * prem
    | One
    | Atom of atom
   type fwd_rule = {name: C.ident, lhs: prem, rhs: atom list}
   type bwd_rule = {name: C.ident, subgoals: prem, head: C.pred * term list} 
   type stage    = {name: C.ident, body: fwd_rule list} 
(*
   fun termToString term = 
      case term of
         Fn (p, []) => p
       | Fn (p, args) => C.withArgs p (map termToString args)
       | Var NONE => "_"
       | Var (SOME id) => id
       | SLit s => "\""^String.toCString s^"\""
       | ILit i => IntInf.toString i

   fun atomToString (C.Lin, p, args) = withArgs p (map termToString args)
     | atomToString (C.Pers, p, args) = withArgs ("!"^p) (map termToString args)

   fun premToString prem =
      case prem of 
         Eq (tm1, tm2) => termToString tm1 ^" == "^termToString tm2
       | Neq (tm1, tm2) => termToString tm1 ^" <> "^termToString tm2
       | Tensor (prem1, prem2) => premToString prem1 ^" * "^premToString prem2
       | One => "()"
       | Atom atom => atomToString atom 
*)

   datatype csyn =
      CStage of stage
    | CRule of fwd_rule 
    | CCtx of C.ident * atom list
    | CTrace of (IntInf.int option) * C.ident * (atom list)
    | CType of C.ident
    | CPred of C.ident * C.ident list * C.predClass
    | CConst of C.ident * C.ident list * C.ident
    | CBwd of bwd_rule
    | CBuiltin of string * C.builtin
    | CStageMode of C.ident * C.nondet

   (* Basics: terms and atoms *)

   fun extractID syn =
      case syn of
         P.Id id => id
       | _ => raise Fail ("Expected identifier, found: "^P.synToString syn) 

   fun extractTerm syn =
      case syn of
         P.Id id => (if caps id then Var (SOME id) else Fn (id, []))
       | P.Wild () => Var NONE
       | P.App (P.Id f, args) => Fn (f, map extractTerm args)
       | P.Num i => ILit i
       (* TODO: Add string literals once they're parsed? *)
       | _ => raise Fail ("Cannot parse as term: "^P.synToString syn) 

   fun extractAtom (perm, syn) = 
      case syn of 
         P.Id pred => (perm, pred, [])
       | P.App (P.Id pred, args) => (perm, pred, map extractTerm args)
       | _ => raise Fail ("Could not parse as atom: "^P.synToString syn)  

   (* extractDuplciates, extractConj, and extractPrem all need the
    * same understanding of what a premise looks like.
    *
    * extractDuplicates implements the functionality of $atom, which
    * is syntactic sugar for "atom" appearing both in premise and
    * conclusion of a rule. *)
   fun extractDuplicates allowed syn =
      case syn of
         P.One () => []
       | P.Star (syn1, syn2) => 
         extractDuplicates allowed syn1 @ extractDuplicates allowed syn2
       | P.Dollar syn => 
           (if allowed 
               then [(C.Lin, syn)] 
            else raise Fail ("Found $ notation where it is not allowed"))
       | _ => []

   fun extractConj syn =
      case syn of 
         P.One () => []
       | P.Star (syn1, syn2) => extractConj syn1 @ extractConj syn2
       | P.Bang syn => [ (C.Pers, syn) ]
       | syn => [ (C.Lin, syn) ]

   fun extractPrem syn = 
      case syn of
         P.One () => One
       | P.Star (syn1, syn2) => Tensor (extractPrem syn1, extractPrem syn2)
       | P.Unify (syn1, syn2) => Eq (extractTerm syn1, extractTerm syn2)
       | P.Differ (syn1, syn2) => Neq (extractTerm syn1, extractTerm syn2)
       | P.Bang syn => Atom (extractAtom (C.Pers, syn))
       | P.Dollar syn => Atom (extractAtom (C.Lin, syn))
       | syn => Atom (extractAtom (C.Lin, syn))

   (* Rules, predicates, and contexts *)

   fun extractRule id (lhs, rhs) = 
      {name = id, lhs = extractPrem lhs, 
       rhs = map extractAtom (extractConj rhs @ extractDuplicates true lhs)}

   fun extractCls data class = 
      case data of
         P.Id id => 
           (remember id; (id, [], class))
       | P.App (P.Id id, tms) => 
           (remember id; (id, map extractID tms, class))
       | _ => raise Fail ("Expected declaration, got: "^P.synToString data)

   fun extractStage name tops = 
      {name = name,
       body = map (fn (P.Decl (P.Lolli rule)) => 
                        (extractRule (gensym ()) rule)
                    | (P.Decl (P.Ascribe (P.Id id, P.Lolli rule))) => 
                        (remember id; extractRule id rule)
                    | decl => raise Fail ("Only rules can appear in stages.\n"^
                                          P.topToString "Found: "decl))
                 tops}

   fun extractContext syn = 
      case syn of
         P.Comma (syn1, syn2) => extractContext syn1 @ extractContext syn2
       | P.Bang syn => [ extractAtom (C.Pers, syn) ]
       | syn => [ extractAtom (C.Lin, syn) ]

   fun extractBwd (name, prem, rhs) = 
      case rhs of 
         P.Arrow (lhs, rhs) =>
            extractBwd (name, Tensor (extractPrem lhs, prem), rhs)
       | P.Id a => 
            {name=name, subgoals=prem, head=(a, [])}
       | P.App (P.Id a, tms) => 
            {name=name, subgoals=prem, head=(a, map extractTerm tms)}  
       | syn => raise Fail ("Not allowed in backward chaining rule: "^
                            P.synToString syn)

   (* Declarations are potentially ambiguous: generates either CType or CBwd
    * 
    * Because a : v is 
    *   - A type declaration (a has type v) if v is a type
    *   - A backward chaining rule (the rule a says v is true) if v is a prop
    * we pass in the set of known type names to distinguish these cases. *)
   fun extractDecl types data class = 
      case (data, class) of
         (P.Id did, P.Id cid) => 
           (if StringRedBlackSet.member types cid 
               then CConst (extractCls data cid)
            else (remember did; CBwd (extractBwd (did, One, class))))
       | (_, P.Id cid) => CConst (extractCls data cid)
       | (P.Id did, P.Arrow (lhs, rhs)) => 
           (remember did; CBwd (extractBwd (did, extractPrem lhs, rhs)))
       | (P.Id did, syn) => (remember did; CBwd (extractBwd (did, One, syn)))
       | _ => raise Fail ("Invalid declaration: "^
                          P.synToString (P.Ascribe (data, class)))

   fun extractTop types top =
      case top of
         P.Stage (s, tops) =>
           (remember s; CStage (extractStage s tops))
       | P.Context (s, NONE) => (remember s; CCtx (s, []))
       | P.Context (s, SOME syn) => (remember s; CCtx (s, extractContext syn))

       | P.Decl (P.Ascribe (P.Id s, P.Lolli rule)) => 
           (remember s; CRule (extractRule s rule))
       | P.Decl (P.Lolli rule) => 
           (CRule (extractRule (gensym ()) rule))

       | P.Decl (P.Ascribe (P.Id id, P.Id "type")) => (remember id; CType id)
       | P.Decl (P.Ascribe (dc, P.Pred ())) => CPred (extractCls dc C.Prop)
       | P.Decl (P.Ascribe (dc, P.Id "bwd")) => CPred (extractCls dc C.Bwd)
       | P.Decl (P.Ascribe (dc, P.Id "sense")) => CPred (extractCls dc C.Sense)
       | P.Decl (P.Ascribe (dc, P.Id "action")) => CPred (extractCls dc C.Act)

       | P.Decl (P.Ascribe (dc, class)) => extractDecl types dc class
       | P.Decl syn => extractDecl types (P.Id (gensym ())) syn 

       | P.Special (directive, args) =>
           (case directive of
                "trace" =>
                   (case args of 
                       [ limit, P.Id stage, ctx ] => 
                       let 
                          val limit = 
                             case limit of 
                                P.Wild () => NONE
                              | P.Num n => SOME n
                              | _ => raise Fail "First arg of #trace must be \
                                                \number or wildcard '_'" 
                          val ctx = 
                             case ctx of
                                P.EmptyBraces () => []
                              | P.Braces syn => extractContext syn
                              | syn => [ extractAtom (C.Lin, syn) ]
                       in
                          CTrace (limit, stage, ctx)
                       end
                     | _ => raise Fail "Format: #trace <opt_ident> <ident> \
                                       \<context>")
              | "builtin" => 
                   (case args of 
                       [ P.Id "NAT", P.Id pred ] => 
                          CBuiltin (pred, C.NAT)
                     | [ P.Id "NAT_ZERO", P.Id const ] => 
                          CBuiltin (const, C.NAT_ZERO)
                     | [ P.Id "NAT_SUCC", P.Id const ] => 
                          CBuiltin (const, C.NAT_SUCC)
                     | _ => raise Fail "Format: #builtin <builtin> <ident>")
              | "interactive" =>
                   (case args of
                       [ P.Id name ] => CStageMode (name, C.Interactive)
                     | _ => raise Fail "Format: #interactive <ident>")
              | _ => raise Fail ("Unknown directive #"^directive))
end
