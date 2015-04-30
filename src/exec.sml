structure Exec = 
struct

exception BadProg

fun currentPhase ctx =
   case List.mapPartial 
           (fn (x, "stage", [Ceptre.Fn (id, [])]) => SOME id
           | _ => NONE)
           ctx of
      [ id ] => id
    | _ => raise BadProg 

fun lookupPhase id ({stages,...}:Ceptre.program) =
  let
    fun lookupInList stages =
    (case stages of
       ((p as {name,body})::stages) => 
         if name = id then p
         else lookupInList stages
      | _ => raise BadProg)
  in
    lookupInList stages
  end

structure Rand = RandFromRandom(structure Random = AESRandom)

(* pick one element from a list *)
fun pick L = List.nth (L, Rand.randInt (List.length L))

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
  (program as {init_stage,...} : Ceptre.program) 
  (print : string -> unit)
=
let
  fun loop stage fastctx = 
  let
    val ctx = CoreEngine.context fastctx
    (* Write out the context *)
    val ctx_string = Ceptre.contextToString ctx
    val () = print ("\n---- " ^ ctx_string ^ "\n")
    (* general transition handling *)
    fun take_transition T =
      let
        (* XXX todo: use second output for trace term *)
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
      in
        loop stage_id fastctx'
      end
  in
     case CoreEngine.possible_steps stage fastctx of
        [] => 
        let
          val (fastctx, var) = CoreEngine.insert fastctx qui
        in
          case CoreEngine.possible_steps "outer_level" fastctx of 
              [] => fastctx (* DONE *)
            | L => 
              let 
                val T = pick L
                val () = print "Applying stage transition "
                val () = print (CoreEngine.transitionToString T) 
              in
                take_transition T
              end
        end
      | L => 
          let
            val T = pick L
            val () = print "\nApplying transition "
            val () = print (CoreEngine.transitionToString T)
          in
            take_transition T
          end
  end

  val (stages, ctx) = Ceptre.progToRulesets program
  val senses = PullSensors.builtins (* XXX fix *)
  val builtins = [] (* XXX fix *)
  val fastctx = CoreEngine.init sigma builtins senses stages ctx
in
   CoreEngine.context (loop init_stage fastctx)
end

fun run (sigma : Ceptre.sigma) (program as {init_state,...} : Ceptre.program) = 
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
