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
                val () = print "Applying stage transition "
                val () = print (CoreEngine.transitionToString T) 
                val () = print "\n"
              in
                take_transition T fastctx
              end
          | NONE => (fastctx, rev steps) (* DONE *))
  end

(*
fun unzip1_2' ((x,y,z)::l) xs yzs =
      unzip1_2' l (x::xs) ((y,z)::yzs)
  | unzip1_2' nil xs yzs = (xs, yzs)
fun unzip1_2 l = unzip1_2' l [] []
*)

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
  (print : string -> unit)
: CoreEngine.fastctx * Ceptre.context * Traces.trace
=
let
  fun loop (stage : string) fastctx steps = 
  let
    (* Write out the context *)
    val ceptre_ctx = CoreEngine.context fastctx
    val ctx_string = Ceptre.contextToString ceptre_ctx
    val () = print ("\n---- " ^ ctx_string ^ "\n")
    (* general transition handling *)
    fun take_transition T ctx =
      let
        val (fastctx', newvars : (CoreEngine.ctx_var * Ceptre.atom) list) = 
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
          CoreEngine.lookup fastctx' "stage"

        (* get trace step *)
        val step = Traces.transitionToStep T newvars
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
                          let
                            val () = print "\nApplying transition "
                            val () = print (CoreEngine.transitionToString T)
                          in
                            take_transition T fastctx
                          end
                      | NONE => (* quiesce take_transition fastctx steps *)
                        (* end the program *)
                        (fastctx, rev steps)
                          ))
  end


  val (stages, ctx) = Ceptre.progToRulesets program
  val senses = PullSensors.builtins (* XXX fix *)
  val init_ctx = CoreEngine.init sigma senses stages ctx
  val (end_ctx, trace) = loop init_stage init_ctx []
in
   (init_ctx, CoreEngine.context end_ctx, trace)
end

fun run (sigma : Ceptre.sigma) (program as {init_state,...} : Ceptre.program)
  : CoreEngine.fastctx * Ceptre.context * Traces.trace  =
let
  (* val senses = XXX (* set up sensors *) *)
  val logfile = TextIO.openOut "log.txt"
  fun print s = (TextIO.output (logfile, s); TextIO.flushOut logfile)
in
  fwdchain sigma init_state program (* senses *) print
  before
  TextIO.closeOut logfile
end

end

structure Exec = ExecFn (TextPrompt)

