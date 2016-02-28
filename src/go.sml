val () = print ("Ceptre!\n")

val () = 
   case CommandLine.arguments () of
      [ fname ] => ignore (Top.runFirst fname)
    | _ => print ("Usage: "^CommandLine.name ()^" CEPTREFILE.cep\n")
