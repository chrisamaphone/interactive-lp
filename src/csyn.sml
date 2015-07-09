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
   type stage    = {name: C.ident, nondet: C.nondet, body: fwd_rule list} 
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
    | CProg of (int option) * C.ident * C.context 
    | CType of C.ident
    | CTerm of C.ident * C.ident list * C.ident
    | CPred of C.ident * C.ident list * C.predClass
    | CDecl of C.decl
    | CBwd of C.bwd_rule
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

   fun extractPred data class = 
      case data of
         P.Id id => 
           (remember id; CPred (id, [], class))
       | P.App (P.Id id, tms) => 
           (remember id; CPred (id, map extractID tms, class))
       | _ => raise Fail ("Expected declaration, got: "^P.synToString data)

   fun extractStage name tops = 
      {name = name,
       nondet = C.Random,
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
         
   (* Declarations, which are potentially ambiguous
    * 
    * Because a : v is 
    *   - A type declaration (a has type v) if v is a type
    *   - A backward chaining rule (the rule a says v is true) if v is a prop
    * we pass in the set of known type names to distinguish these cases. *)
   fun extractDecl types data class = raise Match

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
       | P.Decl (P.Ascribe (data, P.Pred ())) => extractPred data C.Prop
       | P.Decl (P.Ascribe (data, P.Id "bwd")) => extractPred data C.Bwd
       | P.Decl (P.Ascribe (data, P.Id "sense")) => extractPred data C.Sense
       | P.Decl (P.Ascribe (data, P.Id "action")) => extractPred data C.Act

       | P.Decl (P.Ascribe (data, class)) => extractDecl types data class
       | P.Decl syn => extractDecl types (P.Id (gensym ())) syn 

       | P.Special (directive, args) => raise Match
           (* case directive of
                "trace" => CProg (extractTrace args ctxs sg)
              | "builtin" => CBuiltin (extractBuiltin args sg)
              | "interactive" =>
                  (case args of
                       [Id name] => CStageMode (name, C.Interactive)
                      | _ => raise IllFormed)
              | _ => raise IllFormed *)

end
