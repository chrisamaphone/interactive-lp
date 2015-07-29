signature PROMPT =
sig
  val prompt : CoreEngine.transition list -> CoreEngine.fastctx 
    -> CoreEngine.transition option
end

structure TextPrompt :> PROMPT =
struct

(* Pair elements of a list with their number in that list. *)
fun number' (x::xs) i = (i,x)::(number' xs (i+1))
  | number' [] _ = []
fun number xs = number' xs 0
fun numberStrings xs = 
  let
    val numbered = number xs
  in
    map (fn (i,x) => (Int.toString i)^": "^x) numbered
  end

(* XXX ignores ctx right now *)
fun prompt Ts ctx =
let
  val choices = map CoreEngine.transitionToString Ts
  val numbered = numberStrings choices
  val promptString = String.concatWith "\n" numbered
  val () = print (promptString ^ "\n?- ")
in
    case TextIO.inputLine TextIO.stdIn of
        NONE => prompt Ts ctx (* try again *)
      | SOME s =>
          (case Int.fromString s of
                  (* XXX add some error message *)
                NONE => prompt Ts ctx (* try again *)
              | SOME i =>
                  if i < (List.length Ts) then SOME (List.nth (Ts, i))
                  else prompt Ts ctx (* try again *) )
end


end
