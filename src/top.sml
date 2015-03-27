structure Top =
struct

  fun progs fname =
  let
    val parsed = Parse.parsefile fname
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
