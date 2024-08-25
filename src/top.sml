structure Top =
struct

  fun progs quiet fname =
  let
    val parsed = Parse.parsefile fname

    (* Modified loader to test type checker *)
    fun loop types signat [] = ()
      | loop types signat (top :: tops) =
        let
           val csyn = CSyn.extractTop types top
           val decl = TypeCheck.typecheckDecl signat csyn
           val types =  
              case decl of 
                 Signature.TypeDecl a => StringRedBlackSet.insert types a
               | _ => types 
           val () = if quiet then () else print (Signature.topdeclToString decl^"\n")
        in loop types (Signature.add signat decl) tops end
    val () = loop StringRedBlackSet.empty [] parsed 

    val (sg:Ceptre.sigma, programs) = Preprocess.process parsed
  in
    (sg, programs)
  end 

   fun run quiet fname index =
     let
       val (sigma, progs) = progs quiet fname
       val (init_ctx, end_ctx, trace) = Exec.run sigma (List.nth (progs, index))
       (* convert the trace to a graph and write it to a dotfile *)
       val traceGraph = Traces.traceToGraph init_ctx trace
       val graphString = Dot.graphToString traceGraph
       val dotfile = TextIO.openOut "trace.dot"
       val () = TextIO.output (dotfile, graphString)
       val () = TextIO.flushOut dotfile
       val () = TextIO.closeOut dotfile
       (* Print out the context and trace *)
       val ctx_string = Ceptre.contextToString end_ctx
       val trace_strings = map Traces.stepToString trace
       val trace_string = String.concatWith "\n" trace_strings
       val result_string = 
         "\n\nFinal state:\n" 
        ^ ctx_string ^ "\n" ^
        "\nTrace: \n"
        ^ trace_string ^ "\n"
       val () = if quiet then () else print result_string
     in
       SOME end_ctx (* XXX also trace? *)
     end
     handle Subscript => 
       (if quiet then () else print ((Int.toString index)^" is an invalid program index!\n")
       ; NONE)

  (* runFirst : string -> Ceptre.context *)
  (* extracts the first program from the file, then runs it to quiescence,
  * returning the final context. *) 
  fun runFirst quiet fname = run quiet fname 0
    (*
    case progs fname of
         (_, []) => NONE
       | (sg:Ceptre.sigma, prog::_) => 
           let
             val () = print "Running the following program:\n"
             val () = print (Ceptre.programToString prog) 
           in
             SOME (Exec.run sg prog)
           end
    *)

end
