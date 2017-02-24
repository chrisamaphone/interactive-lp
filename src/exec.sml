functor ExecFn (Prompt : PROMPT) = 
struct

exception BadProg

structure Rand = RandFromRandom(structure Random = AESRandom)

(* pick one element randomly from a list *)
fun pick_random [] = NONE
  | pick_random L = SOME (List.nth (L, Rand.randInt (List.length L)))

fun pick mode L ctx =
  case mode of
        Ceptre.Random => pick_random L
        (* XXX the below may not do quite the right thing. *)
      | Ceptre.Ordered => (case L of [] => NONE | (x::xs) => SOME x)
      | Ceptre.Interactive => Prompt.prompt L ctx

val qui = (Ceptre.Lin, "qui", [])

fun quiesce take_transition fastctx steps =
  let
    (* n.b. var not used *)
    val (fastctx, var) = CoreEngine.insert fastctx qui
  in
    case CoreEngine.possible_steps "outer_level" fastctx of 
      [] => (fastctx, rev steps) (* DONE *)
    | L => 
      (case pick Ceptre.Random L fastctx of
            SOME T =>
              let 
                val () = () (* print "Applying stage transition " 
                val () = print (CoreEngine.transitionToString T) 
                val () = print "\n" *)
              in
                take_transition T fastctx
              end
          | NONE => (fastctx, rev steps) (* DONE *))
  end

(* fwdchain : Ceptre.context -> Ceptre.program
*          -> Ceptre.context
*  
*  [fwdchain initialDB program]
*    runs [program] to global quiescence on [initialDB].
*)
fun fwdchain 
  (sigma : Ceptre.sigma)
  (ctx : Ceptre.atom list) 
  (program as {init_stage,stages,...} : Ceptre.program) 
  (io : Traces.step -> Ceptre.atom list -> unit) (* Communicate step w/outside world *)
: CoreEngine.fastctx * Ceptre.context * Traces.trace
=
let
  fun loop (stage : string) fastctx steps = 
  let
    (* Write out the context *)
    val ceptre_ctx = CoreEngine.context fastctx
    val ctx_string = Ceptre.contextToString ceptre_ctx
    (* val () = print ("\n---- " ^ ctx_string ^ "\n") *)
    (* general transition handling *)
    fun take_transition T ctx =
      let
        val (oldvars, fastctx', newvars : (CoreEngine.ctx_var * Ceptre.atom) list) = 
          CoreEngine.apply_transition ctx T

        (* XXX no actions anymore 
        val actions =
          List.mapPartial
          (fn (x, (_,p,args)) =>
            case Acting.lookup p Acting.action_table of
                  SOME action => SOME (x, action, args)
                | NONE => NONE)
          newvars
        val () = print 
          ("\n About to run "
          ^Int.toString(List.length actions)^" actions\n")
        val (xs, actions) = unzip1_2 actions 
        val () = List.app (fn (f,args) => f (ctx, args)) actions
        val fastctx' = CoreEngine.removeAll fastctx' xs
        *)
        
        (* Read out new stage from program *)
        val [(x, [Ceptre.Fn (stage_id, [])])] = 
          CoreEngine.filterCtx fastctx' "stage"

        (* get trace step *)
        val step = Traces.transitionToStep T oldvars newvars

        (* Let outside world know about step *)
        val () = io step (CoreEngine.context fastctx')
      in
        loop stage_id fastctx' (step::steps)
      end
  in (* body of loop fn *)
     case CoreEngine.possible_steps stage fastctx of
        [] => (* No steps in current stage: quiescence *)
          quiesce take_transition fastctx steps 
      | L => (* Steps available in current stage *)
          (case Ceptre.lookupStage stage stages of
                NONE => raise BadProg
              | SOME {nondet,...} =>
                  (case pick nondet L fastctx of
                        SOME T =>
                            take_transition T fastctx
                      | NONE => (* quiesce take_transition fastctx steps *)
                        (* end the program *)
                        (fastctx, rev steps)
                  )
          )
  end


  val (stages, ctx) = Ceptre.progToRulesets program
  val senses = PullSensors.builtins (* XXX fix *)
  val init_ctx = CoreEngine.init sigma senses stages ctx
  val (end_ctx, trace) = loop init_stage init_ctx []
in
   (init_ctx, CoreEngine.context end_ctx, trace)
end


  fun stepToLogLine {rule, consts, input, input_deps, outputs} =
  let
    (* Transition *)
    val constStrings = map Ceptre.termToString consts
    val constsString = String.concatWith " " constStrings
    val transition = rule^" "^constsString
    (* Removed predicates *)
    val removed = map (Ceptre.atomToString o (#2)) input_deps
    val removedString = "{"^ (String.concatWith ", " removed) ^"}"
    (* Added predicates *)
    val added = map (Ceptre.atomToString o (#2)) outputs
    val addedString = "{"^(String.concatWith ", " added)^"}"
  in
    "--- STEP:    "^transition^"\n"^
    "    REMOVED: "^ removedString  ^"\n"^
    "    ADDED:   "^ addedString ^"\n"
  end


  (* Create a string from l by comma-separating f of each element, then 
    * prepend left and append right. *)
  fun listToString l f left right =
  let
    val pieces = map f l
    val commasep = String.concatWith ", " pieces
    val combined = left ^ commasep ^ right
  in
    combined
  end

  fun quote s = "\""^s^"\""

  (* {varname: string, pred: string, mode: string, args: string array } *)
  fun bindingToJSON (var:CoreEngine.ctx_var, ((mode, pred, terms) : Ceptre.atom)) =
  let
    val varString = quote (CoreEngine.varToString var)
    val predString = quote pred
    val modeString' = (case mode of Ceptre.Lin => "lin" | Ceptre.Pers => "pers")
    val modeString = quote modeString'
    val argString = listToString terms (quote o Ceptre.termToString) "[" "]"
  in
    "{\"varname\": "^ varString ^", "^
    "\"mode\": "^ modeString ^", "^
    "\"pred\": "^ predString ^", "^ "\"args\": "^ argString ^"}"
  end

  fun ruleAppToJSON rule args =
  let
    val rfield = (quote "rulename") ^ ": " ^ (quote rule)
    val argstring = listToString args (quote o Ceptre.termToString) "[" "]"
    val argfield = (quote "args") ^ ": " ^ argstring
  in
    "{"^ rfield ^ ", " ^ argfield ^ "}"
  end

  fun contextToJSON ctx =
    listToString ctx (quote o Ceptre.atomToString) "[" "]"

  (* XXX Move to traces.sml *)
  (* Format:
  *   term: {id: string, args: term array}
  *   resource: {varname: string, pred:string, args: term array}
  *   step: {command, removed, added} where
  *     command: rulename
  *     removed: array of resources
  *     added: array of resources 
  *   context: array of resources - current context
  **)
  fun stepToJSONLine {rule, consts, input, input_deps, outputs} ctx =
  let
    val command = ruleAppToJSON rule consts
    val removed = listToString input_deps bindingToJSON "[" "]"
    val added   = listToString outputs bindingToJSON "[" "]"
    val context = contextToJSON ctx
  in
    "{\"command\": "^command^",\n"^
    " \"removed\": "^removed^",\n"^
    " \"added\": "^added^",\n"^
    " \"context\": "^context^"\n}"
  end

fun run (sigma : Ceptre.sigma) (program as {init_state,...} : Ceptre.program)
  : CoreEngine.fastctx * Ceptre.context * Traces.trace  =
let
  (* val senses = XXX (* set up sensors *) *)
  val logfile = TextIO.openOut "log.txt"
  fun log step ctx = 
    let
      (* Log file *)
      val step_string = stepToLogLine step
      val () = TextIO.output (logfile, step_string)
      val () = TextIO.flushOut logfile
      (* JSON file *)
      val jsonfile = TextIO.openOut "ceptre.json"
      val step_json = stepToJSONLine step ctx
      val () = TextIO.output (jsonfile, step_json)
      val () = TextIO.flushOut jsonfile
      val () = TextIO.closeOut jsonfile
    in () end
in
  fwdchain sigma init_state program (* senses *) log
  before
  TextIO.closeOut logfile
end

end

structure Exec = ExecFn (TextPrompt)

