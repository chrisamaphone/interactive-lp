val () = 
   case CommandLine.arguments () of
      [ fname ] => Top.runFirst fname
    | _ => print ("Usage: "^CommandLine.name ()^" CEPTREFILE.cep\n")
