structure Signature = 
struct
   datatype topdecl = 
      StageDecl     of Ceptre.ident * Ceptre.rule_internal_new list
    | FwdRuleDecl   of Ceptre.rule_internal_new
    | CtxDecl       of Ceptre.ident * Ceptre.atom list
    | TraceDecl     of unit
    | TypeDecl      of Ceptre.ident
    | PredDecl      of Ceptre.ident * Ceptre.ident list * Ceptre.predClass
    | ConstDecl     of Ceptre.ident * Ceptre.ident list * Ceptre.ident
    | BwdRuleDecl   of Ceptre.bwd_rule_new
    | BuiltinDecl   of Ceptre.ident * Ceptre.builtin
    | StageModeDecl of Ceptre.ident * Ceptre.nondet
 
   datatype namespace = 
      FIRST (* First order data: types and terms *)
    | PRED (* Predicates and contexts *) 
    | BUILTIN (* Builtins *) 
    | STAGE (* Stages *)
    | RULE (* Both backward-chaining and forward-chaining rules *) 
    | STAGE_RULE of Ceptre.ident (* Rule in a stage *)
    | NOTHING

   fun clsToString (id, [], cls) = id^": "^cls
     | clsToString (id, ids, cls) = id^" "^String.concatWith " " ids^": "^cls

   fun topdeclToString topdecl =
      case topdecl of
         StageDecl (id, body) => 
            "stage "^id^" {\n"^
            String.concatWith "\n" (map (topdeclToString o FwdRuleDecl) body)^
            "\n}"
       | FwdRuleDecl {name, pivars, ...} => 
            "forward chaining rule "^name^
            " with "^Int.toString pivars^" free variables..."
       | CtxDecl (id, ctx) => 
            "context "^id^" { "^
            String.concatWith ", " (map Ceptre.atomToString ctx)^" }"          
       | TraceDecl _ => "#trace ..."
       | TypeDecl id => id^": type."
       | PredDecl (a, ids, Ceptre.Prop) => clsToString (a, ids, "pred")^"."  
       | PredDecl (a, ids, Ceptre.Bwd) => clsToString (a, ids, "bwd")^"."
       | PredDecl (a, ids, Ceptre.Sense) => clsToString (a, ids, "sense")^"."  
       | PredDecl (a, ids, Ceptre.Act) => clsToString (a, ids, "action")^"."
       | ConstDecl (c, ids, cls) => clsToString (c, ids, cls)^"."
       | BwdRuleDecl {name, pivars, ...} => 
            "backward chaining rule "^name^
            " with "^Int.toString pivars^" free variables..."
       | BuiltinDecl (id, Ceptre.NAT) => "#builtin NAT "^id
       | BuiltinDecl (id, Ceptre.NAT_ZERO) => "#builtin NAT_ZERO "^id
       | BuiltinDecl (id, Ceptre.NAT_SUCC) => "#builtin NAT_SUCC "^id
       | StageModeDecl (id, Ceptre.Interactive) => "#interactive "^id^"."
       | StageModeDecl (id, _) => "???"

   fun id topdecl = 
      case topdecl of
         StageDecl (id, _) => (STAGE, id)
       | FwdRuleDecl {name, ...} => (RULE, name)
       | CtxDecl (id, _) => (PRED, id)
       | TraceDecl _ => (NOTHING, "#trace")
       | TypeDecl id => (FIRST, id) 
       | PredDecl (id, _, _) => (PRED, id)
       | ConstDecl (id, _, _) => (FIRST, id)
       | BwdRuleDecl {name, ...} => (RULE, name)
       | BuiltinDecl (_, Ceptre.NAT) => (BUILTIN, "NAT")
       | BuiltinDecl (_, Ceptre.NAT_ZERO) => (BUILTIN, "NAT_ZERO")
       | BuiltinDecl (_, Ceptre.NAT_SUCC) => (BUILTIN, "NAT_SUCC")
       | StageModeDecl _ => (NOTHING, "#interactive?")

   fun describe topdecl = 
      case topdecl of
         StageDecl _ => "stage"
       | FwdRuleDecl _ => "forward-chaining rule"
       | CtxDecl _ => "context"
       | TraceDecl _ => "#trace declaration"
       | TypeDecl _ => "type"
       | PredDecl (_, _, Ceptre.Prop) => "predicate"
       | PredDecl (_, _, Ceptre.Bwd) => "backward-chaining predicate"
       | PredDecl (_, _, Ceptre.Sense) => "sensing preducate"
       | PredDecl (_, _, Ceptre.Act) => "acting predicate"
       | ConstDecl (_, _, id) => "constant of type "^id
       | BwdRuleDecl id => "backward-chaining rule"
       | BuiltinDecl _ => "#builtin declaration"
       | StageModeDecl _ => "#interactive declaration"  

   type signat = topdecl list
   fun add signat topdecl = signat @ [topdecl]
   fun find signat x = 
      case (signat, x) of 
         ([], _) => NONE
       | (StageDecl (id, body) :: topdecls, (STAGE_RULE id', r)) =>
            if id = id' then find (map FwdRuleDecl body) (RULE, r)
            else find topdecls x
       | (topdecl :: topdecls, _) => 
            if id topdecl = x then SOME topdecl 
            else find topdecls x
end
