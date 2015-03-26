structure Preprocess =
struct

  open Ceptre
  open Parse

  exception IllFormed
  exception Unimp

  (* gensym names *)

  val gensym_ctr = ref 0

  fun gensym () =
  let
    val count = !gensym_ctr
    val name = "`anon" ^ (Int.toString count)
    val () = gensym_ctr := count + 1
  in
    name
  end

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

  (* Stuff without vars can go directly into IL syntax *)
  fun extractGroundTerm syn =
    case syn of
         Id id => if caps id then raise IllFormed else
                  Fn (id, [])
       | App (f, args) =>
           let
             val termArgs = map extractGroundTerm args
           in
             case extractGroundTerm f of
                  Fn (f, []) => Fn (f, termArgs)
                | _ => raise IllFormed
           end
       | _ => raise IllFormed 

  (* XXX should look up bwd stuff in the sig *)
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
  
  (* Stuff without vars can go directly into IL syntax *)
  fun extractGroundAtom syn =
    case syn of
         Bang syn =>
         let
           val at = extractGroundAtom syn 
         in
           case at of
                (Lin, p, args) => (Pers, p, args)
              | _ => raise IllFormed 
         end
       | Id pred => (Lin, pred, [])
       | App (Id pred, args) =>
           let
             val argTerms = map extractGroundTerm args
           in
             (Lin, pred, argTerms)
           end
       | _ => 
           let
             val error = "failed to parse "^(synToString syn)^
              " as a ground atom.\n"
             val () = print error
           in
             raise IllFormed
           end

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

  fun extractRHSAtom syn =
    case extractAtom syn [] of
         (atom, []) => atom
        | _ => raise IllFormed

  fun extractRHS syn acc =
    case syn of
         One () => acc
       | Star (a, rhs) =>
         (case extractAtom a [] of
               (atom, []) => extractRHS rhs (atom::acc)
              | _ => raise IllFormed)
       | syn => 
           (case extractAtom syn [] of
                 (atom, []) => atom::acc
               | _ => raise IllFormed)


  (* XXX no longer strictly necessary w/rob's change. *)
  fun extractID (Id f) = f
    | extractID _ = raise IllFormed


  fun declToRule sg syntax =
    case syntax of
          Decl (Ascribe (Id name, Lolli (lhs_syn, rhs_syn))) =>
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

  fun separate f l =
  let
    fun help f prefix [] = NONE
      | help f prefix (x::xs) = 
          if f x then SOME (x, prefix xs)
          else help f (fn postfix => (prefix (x::postfix))) xs
  in
    help f (fn x => x) l
  end

  fun stageAtom (Lin, p, args) = p = "stage"
    | stageAtom _ = false

  (* XXX hardcode stage keyword? *)
  (* XXX stages with arguments? *)
  fun ruleToStageRule {name, pivars, lhs, rhs} =
    case separate stageAtom lhs of
         SOME ((Lin, "stage", [Fn (pre_stage, [])]), lhs') =>
    (case separate stageAtom rhs of
          SOME ((Lin, "stage", [Fn (post_stage, [])]), rhs') =>
            SOME
            {name=name, pivars=pivars, lhs=lhs', rhs=rhs',
            pre_stage=pre_stage, post_stage=post_stage}
        | _ => NONE)
        | _ => NONE

  fun extractContextAtoms syn = 
    case syn of 
         Comma (syn1, syn2) => 
           extractContextAtoms syn1 @ extractContextAtoms syn2
       | _ => [ extractGroundAtom syn ]

  fun extractContext top =
    case top of
         Context (name, NONE) => (name, [])
       | Context (name, SOME atoms) => (name, extractContextAtoms atoms)
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

  (* interpret a Special "#trace" *)
  fun extractSpecial args ctxs =
    case args of
         ("trace", [limit, Id stage, ctx]) =>
         let 
           val limit = 
           (case limit of
                 Wild () => NONE 
               | Num n => SOME (IntInf.toInt n)
               | _ => raise IllFormed
           )  
           val ctx = 
           (case ctx of
                Id ctx => 
                (case lookup ctx ctxs of
                      NONE => raise IllFormed
                    | SOME ctx => ctx
                )
              | EmptyBraces () => []
              | Braces syn => extractContextAtoms syn
              | _ => raise IllFormed
           )
         in
           (limit, stage, ctx)
         end
       | _ => raise IllFormed

  fun extractPredDecl data predclass =
    let
      val Fn (id, args) = extractGroundTerm data
    in
      (id, Ceptre.Pred (predclass, args))
    end

  fun extractIDTms (Fn (i, [])) = i
    | extractIDTms _ = raise IllFormed

  (* XXX need ceptre fn to extract pivars from bwd rules *)

  (* return a {name,lhs,rhs} in external_rule syntax *)
  fun extractBwd syn name subgoals =
    case syn of
         Arrow (lhs, rhs) =>
         let
           val (subgoal, _) = extractAtom lhs []
         in
           extractBwd rhs name (subgoal::subgoals)
         end
       | _  =>
           let
             val () = case syn of 
                          Id _ => () 
                        | App _ => () 
                        | _ => raise IllFormed 
             val (pred, dollars) = extractAtom syn []
             val pred =
              (case pred of
                    ELin p => EPers p
                  | EPers p => EPers p)
             (* this check might make sense if we change extractAtom
             val () = (case pred of EPers _ => () | _ => raise IllFormed)
             *)
             val () = (case dollars of [] => () | _ => raise IllFormed)
           in
             {name=name, lhs=subgoals, rhs=[pred]} : Ceptre.rule_external
           end
  
  datatype csyn = CStage of stage | CRule of rule_internal 
                | CNone of syn
                | CError of top 
                | CCtx of ident * context  (* named ctx *)
                | CProg of (int option) * ident * context 
                    (* limit, initial phase & initial ctx *)
                | CDecl of decl
                | CBwd of bwd_rule

  (* checks decl wrt sg *)
  (* returns a csyn, either a CDecl or a CBwd *)
  fun extractDecl sg top =
    case top of
         Decl (Ascribe (data, class)) =>
         (case class of
               App (class, []) => extractDecl sg (Decl (Ascribe (data, class)))
            (* first-order types *)
             | Id "type" => CDecl (extractID data, Ceptre.Type)
            (* predicates *)
             | Pred () => (* parse data as f t...t *)
                CDecl (extractPredDecl data Ceptre.Prop)
             | Id "bwd" =>
                 CDecl (extractPredDecl data Ceptre.Bwd)
             | Id "sense" => (* Parse as a Ceptre.Pred Bwd *)
                 CDecl (extractPredDecl data Ceptre.Sense)
             | Id "action" => (* parse as Ceptre.pred Act *)
                 CDecl (extractPredDecl data Ceptre.Act)
            (* first-order terms *)
             | Id ident => (* data : ident *)
                (* Look up ident in sg.
                 * if it's a type, parse data as name * argtp list and
                 * return a (name, Ceptre.Tp (argtps, ident)) *)
                 (case lookup ident sg of
                      SOME Ceptre.Type =>
                        let
                          val Fn (name, argtps) = extractGroundTerm data
                          val idents = map extractIDTms argtps
                        in
                          CDecl (name, Ceptre.Tp (idents, ident))
                        end
                 (* if it's a bwd pred, data should just be an id. *)
                    | SOME (Ceptre.Pred (Bwd, arg_tps)) =>
                      let
                        val name = extractID data 
                        val ebwd = extractBwd class name [] 
                        val bwd = externalToBwd sg ebwd
                      in
                        CBwd bwd
                      end
                    | _ => raise IllFormed)
            (* backward chaining rules *)
             | Arrow rule =>
                 let
                   val name = extractID data
                   val ebwd = extractBwd class name []
                   val bwd = externalToBwd sg ebwd
                 in
                   CBwd bwd
                 end
             | App (pred, args) => (* data : pred arg1 .. argn *)
                 let
                   val name = extractID data
                   val ebwd = extractBwd class name []
                   val bwd = externalToBwd sg ebwd
                 in
                   CBwd bwd
                 end
             | _ => 
                 let
                   val error = "unable to parse decl " ^ (synToString data) ^
                   " : " ^ (synToString class) ^ "\n"
                   val () = print error
                 in
                   raise IllFormed
                 end)
      | Decl unnamed => 
          let
            val id = gensym ()
          in
            extractDecl sg (Decl (Ascribe (Id id, unnamed)))
          end
      | _ => raise IllFormed

  fun extractTop sg ctxs top =
    case top of
         Stage _ => CStage (extractStage sg top)
       | Decl (Ascribe (Id _, Lolli _)) => CRule (declToRule sg top)            
       | Decl (Lolli rule) =>
           let
             val name = gensym ()
             val named_syn = Ascribe (Id name, Lolli rule)
           in
             extractTop sg ctxs (Decl named_syn)
           end
       | Decl s => (extractDecl sg top
                      handle IllFormed => CNone s)
       | Context _ => CCtx (extractContext top)
       | Special args => CProg (extractSpecial args ctxs)

  fun csynToString (CStage stage) = stageToString stage
    | csynToString (CRule rule) = ruleToString rule
    | csynToString (CNone s) = "(" ^ (synToString s) ^ " doesn't parse yet)"
    | csynToString (CError _) = "(parse error!)"
    | csynToString (CCtx (name, ctx)) = name ^ " : " ^ (contextToString ctx)
    | csynToString (CProg (_,stg,ctx)) = 
        "#trace * " ^ stg ^ " " ^ (contextToString ctx) ^ "."
    | csynToString (CDecl (name,class)) = 
          name ^ " : " ^ (classToString class) ^ "."
    | csynToString (CBwd bwd) = "bwd" (* XXX *)


  fun stage_exists s (stages : Ceptre.stage list) =
    List.exists (fn {name, body} => name = s) stages

  (* turn a whole list of top-level decls into a list of progs. *)
  fun process' tops sg bwds contexts stages links progs =
    case tops of
         [] => ({header=sg,rules=bwds} : Ceptre.sigma, progs)
       | (top::tops) => 
           (case extractTop sg contexts top of
                 CStage stage => 
                  process' tops sg bwds contexts (stage::stages) links progs
               | CRule rule => 
                   (case ruleToStageRule rule of 
                         SOME link => 
                          process' tops sg bwds contexts stages 
                            (link::links) progs
                       | NONE => (* XXX error? *)
                          process' tops sg bwds contexts stages links progs)
               | CNone _ => process' tops sg bwds contexts stages links progs
               | CError _ => process' tops sg bwds contexts stages links progs
                            (* XXX error? *)
               | CCtx c => process' tops sg bwds (c::contexts) stages links progs
               | CDecl d =>
                   process' tops (d::sg) bwds contexts stages links progs
               | CBwd bwd => (* XXX *)
                   process' tops sg (bwd::bwds) contexts stages links progs 
               | CProg (limit, init_stage, init_ctx) =>
                   (* XXX ignore limit for now *)
                   case stage_exists init_stage stages of
                        true =>
                          let
                            val prog = {stages=stages, links=links, 
                              init_stage=init_stage, init_state = init_ctx}
                          in
                            process' tops sg bwds contexts stages links 
                              (prog::progs)
                          end
                      | _ => process' tops sg bwds contexts stages links progs
                              (* XXX some kind of error should happen...*)
             )

  fun process tops = process' tops [] [] [] [] [] []

  (* testing *)
  
  fun catch f = (fn x => f x handle IllFormed => CError x)
  fun mapcatch f = map (catch f)
    
  val [tiny1, tiny2] = Parse.parsefile ("../examples/tiny.cep")

  val small = Parse.parsefile ("../examples/small.cep")

  fun sub l n = List.nth(l,n)

end
