
val () = 
   case CommandLine.arguments () of
      [ "--quiet", fname ] => ignore (Top.runFirst true  fname)
    | [ fname ]            => (print "Ceptre!\n"; ignore (Top.runFirst false fname))
    | _ => print ("Usage: "^CommandLine.name ()^" [--quiet] CEPTREFILE.cep\n")
