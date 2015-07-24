structure Exec = 
struct

exception BadProg

(*
fun currentStage ctx =
   case List.mapPartial 
           (fn (x, "stage", [Ceptre.Fn (id, [])]) => SOME id
           | _ => NONE)
           ctx of
      [ id ] => id
    | _ => raise BadProg 
*)

structure Rand = RandFromRandom(structure Random = AESRandom)

(* pick one element randomly from a list *)
fun pick_random L = List.nth (L, Rand.randInt (List.length L))

(* Pair elements of a list with their number in that list. *)
fun number' (x::xs) i = (i,x)::(number' xs (i+1))
  | number' [] _ = []
fun number xs = number' xs 0
fun numberStrings xs = 
  let
    val numbered = number xs
  in
    map (fn (i,x) => (Int.toString i)^": "^x) numbered
  end

(* Prompt the user for a choice between transitions. *)
fun promptChoice Ts =
  let
    val choices = map CoreEngine.transitionToString Ts
    val numbered = numberStrings choices
    val promptString = String.concatWith "\n" numbered
    val () = print (promptString ^ "\n?- ")
  in
    case TextIO.inputLine TextIO.stdIn of
        NONE => promptChoice Ts (* try again *)
      | SOME s =>
          (case Int.fromString s of
                  (* XXX add some error message *)
                NONE => promptChoice Ts (* try again *)
              | SOME i =>
                  if i < (List.length Ts) then i
                  else promptChoice Ts (* try again *) )
  end

fun pick mode L =
  case mode of
        Ceptre.Random => pick_random L
      | Ceptre.Ordered => (case L of [] => raise BadProg | (x::xs) => x)
      | Ceptre.Interactive =>
          let
            val choice = promptChoice L
          in
            List.nth (L,choice)
          end

val qui = (Ceptre.Lin, "qui", [])

fun unzip1_2' ((x,y,z)::l) xs yzs =
      unzip1_2' l (x::xs) ((y,z)::yzs)
  | unzip1_2' nil xs yzs = (xs, yzs)
fun unzip1_2 l = unzip1_2' l [] []


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
: Ceptre.context * Traces.trace
=
let
  fun loop (stage : string) fastctx steps = 
  let
    val ctx = CoreEngine.context fastctx
    (* Write out the context *)
    val ctx_string = Ceptre.contextToString ctx
    val () = print ("\n---- " ^ ctx_string ^ "\n")
    (* general transition handling *)
    fun take_transition T =
      let
        val (fastctx', newvars) = 
          CoreEngine.apply_transition fastctx T
        val actions =
          List.mapPartial
          (fn (x, (_,p,args)) =>
            case Acting.lookup p Acting.action_table of
                  SOME action => SOME (x, action, args)
                | NONE => NONE)
          newvars
        (* debug: *)
        val () = print 
          ("\n About to run "
          ^Int.toString(List.length actions)^" actions\n")
        val (xs, actions) = unzip1_2 actions 
        val () = List.app (fn (f,args) => f (ctx, args)) actions
        val fastctx' = CoreEngine.removeAll fastctx' xs
        
        (* READ OUT NEW PHASE FROM PROGRAM *)
        val [(x, [Ceptre.Fn (stage_id, [])])] = 
          CoreEngine.lookup fastctx' "stage"

        (* get trace step *)
        val step = Traces.transitionToStep T
      in
        loop stage_id fastctx' (step::steps)
      end
  in
     case CoreEngine.possible_steps stage fastctx of
        [] => 
        let
          val (fastctx, var) = CoreEngine.insert fastctx qui
        in
          case CoreEngine.possible_steps "outer_level" fastctx of 
              [] => (fastctx, steps) (* DONE *)
            | L => 
              let 
                val T = pick Ceptre.Random L
                val () = print "Applying stage transition "
                val () = print (CoreEngine.transitionToString T) 
              in
                take_transition T
              end
        end
      | L => 
          (case Ceptre.lookupStage stage stages of
                NONE => raise BadProg
              | SOME {nondet,...} =>
                let
                  val T = pick nondet L
                  val () = print "\nApplying transition "
                  val () = print (CoreEngine.transitionToString T)
                in
                  take_transition T
                end)
  end

  val (stages, ctx) = Ceptre.progToRulesets program
  val senses = PullSensors.builtins (* XXX fix *)
  val init_ctx = CoreEngine.init sigma senses stages ctx
  val (end_ctx, trace) = loop init_stage init_ctx []
in
   (CoreEngine.context end_ctx, trace)
end

fun run (sigma : Ceptre.sigma) (program as {init_state,...} : Ceptre.program)
  : Ceptre.context * Traces.trace  =
let
  (* val senses = asfasdf (* XXX set up sensors *) *)
  val logfile = TextIO.openOut "log.txt"
  fun print s = (TextIO.output (logfile, s); TextIO.flushOut logfile)
in
  fwdchain sigma init_state program (* senses *) print
  before
  TextIO.closeOut logfile
end

end
