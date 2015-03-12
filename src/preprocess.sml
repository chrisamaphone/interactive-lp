structure Preprocess =
struct

  open Parse
  open Ceptre

  exception IllFormed
  exception Unimp

  (* translating from Parse.syn to Ceptre.external_rule *)

  fun caps s =
    case String.explode s of
         [] => raise IllFormed
       | (c::_) => Char.isUpper c

  val wild_gensym = ref 0
  fun wild () = 
    let
      val w = !wild_gensym
      val () = wild_gensym := w + 1
    in
      w
    end

  fun extractTerm syn =
    case syn of
         Id id => if caps id 
                  then EVar id
                  else EFn (id, [])
       | App (f, args) =>
           let
             val termArgs = map extractTerm args
           in
             case extractTerm f of
                  EFn (f, []) => EFn (f, termArgs)
                | _ => raise IllFormed
           end
       | Wild () => EVar ("_X"^Int.toString (wild ()))
       | _ => raise IllFormed

  fun extractAtom syn rhs =
    case syn of
         Bang syn =>
           let
             val (at, rhs) = extractAtom syn rhs
           in
             case at of
                  ELin at => (EPers at, rhs)
                | _ => raise IllFormed
           end
       | Dollar syn => 
           let
             val (at, rhs) = extractAtom syn rhs
           in
             case at of
                  (* $A means A added to RHS *)
                  ELin at => (ELin at, (ELin at)::rhs)
                | _ => raise IllFormed
           end
       | Id pred => (ELin (pred,[]), rhs)
       | App (Id pred, args) =>
           let
             val argTerms = map extractTerm args
           in
             (ELin (pred, argTerms), rhs)
           end
       | _ => raise IllFormed
  
  fun extractLHS syn acc rhs =
    case syn of
         Star (a, lhs) =>
           let
             val (atom, rhs) = extractAtom a rhs
           in
               extractLHS lhs (fn x => atom::(acc x)) rhs
           end
       | syn => 
           let
             val (atom, rhs) = extractAtom syn rhs
           in
             (acc atom, rhs)
           end

  fun extractRHS syn acc =
    case syn of
         Star (a, rhs) =>
         (case extractAtom a [] of
               (atom, []) => extractRHS rhs (atom::acc)
              | _ => raise IllFormed)
       | syn => 
           (case extractAtom syn [] of
                 (atom, []) => atom::acc
               | _ => raise IllFormed)

  fun declToRule sg syntax =
    case syntax of
          Decl (Ascribe (App (Id name, []), 
                Lolli (lhs_syn, SOME rhs_syn))) => (* XXX MATCH ERROR - RJS *)
            let
              val (lhs, residual) = extractLHS lhs_syn (fn x => [x]) []
              val rhs = extractRHS rhs_syn residual
              (* external syntax *)
              val erule = {name = name, lhs = lhs, rhs = rhs}
              val () = wild_gensym := 0 (* reset for each rule *)
            in
              externalToInternal sg erule
            end
        | _ => raise IllFormed

  fun extractStage sg syntax =
    case syntax of
          Stage (name, rules_syntax) =>
          let
            val rules = map (declToRule sg) rules_syntax
          in
            {name = name, body = rules}
          end
        | _ => raise IllFormed

  datatype csyn = CStage of stage | CRule of rule_internal | CNone
                | CError of top

  fun extractTop sg top =
    case top of
         Stage _ => CStage (extractStage sg top)
       | Decl (Ascribe (App (Id _, []), Lolli _)) => CRule (declToRule sg top)
       | _ => CNone (* XXX *)

  fun csynToString (CStage stage) = stageToString stage
    | csynToString (CRule rule) = ruleToString rule
    | csynToString CNone = "(doesn't parse yet)"
    | csynToString (CError _) = "(parse error!)"

  (* XXX handle signatures *)
  (* XXX turn these into an actual prog. *)

  (* testing *)
  
  fun catch f = (fn x => f x handle IllFormed => CError x)
  fun mapcatch f = map (catch f)
    
  val [tiny1, tiny2] = Parse.parsefile ("../examples/tiny.cep")

  val small = Parse.parsefile ("../examples/small.cep")

  fun sub l n = List.nth(l,n)

end
