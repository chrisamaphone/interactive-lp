structure Top =
struct

  fun top fname =
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

end
