structure Top =
struct

  fun top fname =
  let
    val parsed = Parse.parsefile fname
    val sg = [] (* XXX *)
    val preproc = map (Preprocess.extractTop sg) parsed
  in
    preproc
  end

end
