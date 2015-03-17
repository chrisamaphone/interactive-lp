structure Top =
struct

  fun progs fname =
  let
    val parsed = Parse.parsefile fname
    val sg = [] (* XXX *)
    val preproc = map (Preprocess.extractTop sg) parsed
    val strings = map (Preprocess.csynToString) preproc
    val () = print "\nPrinting processed program...\n\n"
    val () = List.app (fn s => print (s^"\n")) strings
    val programs = Preprocess.process parsed
  in
    programs
  end

  (* runFirst : string -> Ceptre.context *)
  (* extracts the first program from the file, then runs it to quiescence,
  * returning the final context. *) 
  fun runFirst fname =
    case progs fname of
         [] => NONE
       | (prog::_) => 
           let
             val () = print "Running the following program:\n"
             val () = print (Ceptre.programToString prog) 
           in
             SOME (Exec.run prog)
           end


end
