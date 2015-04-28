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
    (* Check for action predicates; run them and remove them *) 
    (* XXX removing them is going to be super annoying.
    val actions = List.filter
        (fn (_,pred,_args) => 
          case lookup pred Actions.actionTable of
               SOME _ => true
             | NONE => false)
    (* XXX val ctx' = removeAll ctx ctx' *)
    val () = List.app (fn a => Acting.run (a, ctx)) actions

    *)


    val () = List.app (fn p => Acting.maybe_run (p, ctx)) ctx
    (* XXX the above is probably not the most efficient way to implement action
    * predicates!!! *)
    (* n.b. this doesn't remove anything yet. *)
  in
     case CoreEngine.possible_steps stage fastctx of
        [] => 
        let
          val (fastctx, var) = CoreEngine.insert fastctx qui
        in
          (case CoreEngine.possible_steps "outer_level" fastctx of 
              [] => fastctx (* DONE *)
            | L => 
              let 
                val T = pick L
                val () = print "Applying stage transition "
                val () = print (CoreEngine.transitionToString T) 

                (* XXX todo: use second output for trace term *)
                val (fastctx', _) = CoreEngine.apply_transition fastctx T
                
                (* READ OUT NEW PHASE FROM PROGRAM *)
                val [(x, [Ceptre.Fn (stage_id, [])])] = 
                  CoreEngine.lookup fastctx' "stage"
              in
                loop stage_id fastctx'
              end)
        end
      | L => 
          let
            val T = pick L
            val () = print "\nApplying transition "
            val () = print (CoreEngine.transitionToString T)
          in
             loop stage 
             (#1 (CoreEngine.apply_transition fastctx T))
          end
  end

  val (stages, ctx) = Ceptre.progToRulesets program
  val senses = PullSensors.builtins (* XXX fix *)
  val fastctx = CoreEngine.init sigma senses stages ctx
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
