signature PROMPT =
sig
  val prompt : CoreEngine.transition list -> CoreEngine.fastctx 
    -> CoreEngine.transition option
end

structure PromptUtil = 
struct

  val prompt_char = "?-"
  val error = "\nInvalid index! Try again.\n"^prompt_char^" "

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

  fun acceptInput Ts =
    case TextIO.inputLine TextIO.stdIn of
        NONE => NONE (* a ctrl+D quiesces *)
      | SOME s =>
          (case Int.fromString s of
                NONE => (print error; acceptInput Ts) (* try again *)
              | SOME 0 => NONE (* quiesce *)
              | SOME i =>
                  SOME (List.nth (Ts, i-1))
                  handle Subscript => 
                    (print error; acceptInput Ts (* try again *) )
          )

  fun transitionsToString Ts =
  let
    val choices = "(quiesce)" :: (map CoreEngine.transitionToString Ts)
    val numbered = numberStrings choices
  in
    "\n" ^ (String.concatWith "\n" numbered) ^ "\n" ^ prompt_char ^ " "
  end

  (* Context utilities *)
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

  val sortByHeadTerm = Mergesort.sort atom_compare

  fun refers_to (mode, id, args) term =
  let
    fun term_match (Fn (term_id, args)) = term_id = term
      | term_match _ = false
  in
    List.exists (fn arg => term_match arg) args
  end

  (* List utils *)
  fun dedup' [] accum = accum
    | dedup' (x::xs) accum = if (List.exists (fn y => y = x) accum) 
        then dedup' xs accum else dedup' xs (x::accum)

  fun dedup l = dedup' l []


  (* Story specific context utils *)
  fun location (mode, "at", [Fn (ch, []), Fn (loc, [])]) = SOME loc
    | location _ = NONE

  fun things_at' location ctx accum =
    case ctx of 
         ((mode, id, args)::ctx) =>
          (case (id, args) of
              ("at", [Fn (ch, []), Fn (loc, [])]) => 
                if loc = location then things_at' location ctx (ch::accum)
                else things_at' location ctx accum
            | _ => things_at' location ctx accum)
       | nil => accum
  
  fun things_at location ctx =
  let
    val just_at = things_at' location ctx []
    fun one_hop atom = List.exists (fn x => refers_to atom x) just_at 
  in
    List.filter one_hop ctx
  end



end

(* Simplest prompt - just prints transitions as numbered and accepts numeric
* choice on STDIN. *)
structure TextPrompt :> PROMPT =
struct
(* ignores ctx *)
fun prompt Ts ctx =
let
  val () = print (PromptUtil.transitionsToString Ts) 
in
  PromptUtil.acceptInput Ts
end
end

(* Slightly nicer prompt - prints the context sorted by atoms' head terms *)
structure ShowCtxPrompt :> PROMPT =
struct
  fun prompt Ts ctx = 
  let
    (* context *)
    val ceptre_ctx = CoreEngine.context ctx
    val sorted_ctx = PromptUtil.sortByHeadTerm ceptre_ctx
    val ctx_string = Ceptre.contextToString sorted_ctx
    (* transitions *)
    val promptString = PromptUtil.transitionsToString Ts
    (* printing *)
    val () = print ctx_string
    val () = print promptString
  in
    PromptUtil.acceptInput Ts
  end
end

(* Assumes story world with "pc C" meaning C is the player char,
*   "at C L" meaning character C is at location L, and displays characters by
*   location *)
structure StoryPrompt :> PROMPT =
struct

  fun prompt Ts ctx = 
  let
    (* context *)
    val ceptre_ctx = CoreEngine.context ctx
    val locations : string list = List.mapPartial PromptUtil.location ceptre_ctx
    val locations = PromptUtil.dedup locations
    val lines : Ceptre.context list = map (fn l => PromptUtil.things_at l ceptre_ctx) locations
    val line_strings : string list = map Ceptre.contextToString lines
    val lines_string = String.concatWith "\n\n" line_strings
    (* transitions *)
    val promptString = PromptUtil.transitionsToString Ts
    (* printing *)
    val () = print lines_string
    val () = print promptString
  in
    PromptUtil.acceptInput Ts
  end
end

