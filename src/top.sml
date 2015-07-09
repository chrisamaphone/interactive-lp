structure Top =
struct

  fun progs fname =
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
           val () = print (Signature.topdeclToString decl^"\n")
        in loop types (Signature.add signat decl) tops end
    val () = loop StringRedBlackSet.empty [] parsed

    val (sg:Ceptre.sigma, programs) = Preprocess.process parsed
  in
    (sg, programs)
  end 

  (* runFirst : string -> Ceptre.context *)
  (* extracts the first program from the file, then runs it to quiescence,
  * returning the final context. *) 
  fun runFirst fname =
    case progs fname of
         (_, []) => NONE
       | (sg:Ceptre.sigma, prog::_) => 
           let
             val () = print "Running the following program:\n"
             val () = print (Ceptre.programToString prog) 
           in
             SOME (Exec.run sg prog)
           end

   fun run fname index =
     let
       val (sigma, progs) = progs fname
       val ans = Exec.run sigma (List.nth (progs, index))
     in
       print ("\n\nFinal state:\n" ^ (Ceptre.contextToString ans) ^ "\n")
       ; SOME ans
     end
     handle Subscript => 
       (print ((Int.toString index)^" is an invalid program index!\n")
       ; NONE)

end
