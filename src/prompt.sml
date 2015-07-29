signature PROMPT =
sig
  val prompt : CoreEngine.transition list -> CoreEngine.fastctx 
    -> CoreEngine.transition option
end

(* Simplest prompt - just prints transitions as numbered and accepts numeric
* choice on STDIN. *)
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

(* ignores ctx *)
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

(* Slightly nicer prompt - prints the context sorted by atoms' head terms *)
structure ShowCtxPrompt :> PROMPT =
struct

  open Ceptre
  exception IllFormed

  fun term_compare t1 t2 =
    case (t1, t2) of
         (ILit i1, ILit i2) => IntInf.compare (i1, i2)
       | (SLit s1, SLit s2) => String.compare (s1, s2)
       | (Fn (f1, ts1), Fn (f2, ts2)) =>
           (case String.compare (f1, f2) of
                 LESS => LESS
               | GREATER => GREATER
               | EQUAL => term_list_compare ts1 ts2)
       | _ => EQUAL (* incomparable *)

  and term_list_compare ts1 ts2 =
    case (ts1, ts2) of
         (nil, nil) => EQUAL
       | (t1::ts1, t2::ts2) =>
           (case term_compare t1 t2 of
                 GREATER => GREATER
               | LESS => LESS
               | EQUAL => term_list_compare ts1 ts2)
       | (nil, t::ts) => LESS
       | (t::ts, nil) => GREATER
  
  fun atom_compare (a1, a2) =
  let 
    val (mode1, pred1, terms1) = a1
    val (mode2, pred2, terms2) = a2
  in
    case term_list_compare terms1 terms2 of
         LESS => LESS
       | GREATER => GREATER
       | EQUAL =>
        (case String.compare (pred1, pred2) of
          LESS => LESS
        | GREATER => GREATER
        | EQUAL =>
                (case (mode1, mode2) of
                      (Pers, Lin) => LESS
                    | (Lin, Pers) => GREATER
                    | _ => EQUAL))
  end

  val sort = Mergesort.sort atom_compare


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

  fun prompt Ts ctx = 
  let
    (* context *)
    val ceptre_ctx = CoreEngine.context ctx
    val sorted_ctx = sort ceptre_ctx
    val ctx_string = Ceptre.contextToString sorted_ctx
    (* transitions *)
    val choices = map CoreEngine.transitionToString Ts
    val numbered = numberStrings choices
    val promptString = String.concatWith "\n" numbered
    (* printing *)
    val () = print ctx_string
    val () = print ("\n"^promptString^"\n?- ")
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

