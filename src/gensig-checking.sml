structure Check : GENSIGS =
struct

  type atom = int
  type genrule = (atom list) * (atom list)
  type gensig = genrule list
  type context = atom list
  type multistep = (atom list) * (atom list)

  type state_transition = atom * (atom list) * (atom option)
  type state_machine = state_transition list


  (* util *)
  fun member x = List.exists (fn x' => x = x')

  fun deleteAll x = List.filter (fn x' => x <> x')

  fun deleteFirst x [] = []
    | deleteFirst x (y::ys) = if x = y then ys else y::(deleteFirst x ys)

  (* model testing *)

  fun terminal a [] = true
    | terminal a ((ins, outs)::rules)
      = not (member a ins) andalso terminal a rules

  (* assumes no silent transitions *)
  fun produces state machine [] trace = SOME trace
    | produces state machine multiset trace =
      let
        val transitions = List.filter (fn (st, _, _) => st = state) machine
        val result_ = 
          List.find 
            (fn (_, ays, st') => List.all (fn a => member a multiset) ays) 
            transitions
      in
        case result_ of
             NONE => NONE
           | SOME (_, ays, SOME state') => 
              produces 
                state' machine 
                (foldl (fn (a, ms) => deleteFirst a ms) multiset ays) 
                (state::trace)
           | SOME (_, ays, NONE) =>
               if (List.null (foldl (fn (a, ms) => deleteFirst a ms) multiset ays))
               then SOME (state::trace)
               else NONE
      end

  (* Current status:
  *
  * - produces gen machine2 [c,c,c,a] nil;
  * val it = SOME [5,5,5,0] : atom list option
  * - produces gen machine2 [c,a] nil;
  * val it = SOME [5,0] : atom list option
  * - produces gen machine2 [a,b] nil;
  * val it = NONE : atom list option
  * - produces gen machine2 [b,c,c] nil;
  * val it = NONE : atom list option
  * - produces gen machine2 [b,c] nil;
  * val it = SOME [0] : atom list option
  *
  * To get this to support epsilon transitions, or nondeterministic branching,
  * would need to add in backtracking. That can be a next step.
  *)

  fun machinify G =
  let
    fun split (x::xs) ts = 
      if not (terminal x G) then
        if (List.all (fn y => terminal y G) xs) 
        then SOME (SOME x, xs@ts) 
        else NONE
      else split xs (x::ts)
      | split nil ts = SOME (NONE, ts)
    fun ruleToTransition ([s], outs) =
        (case (split outs nil) of
             SOME (s', xs) => SOME (s, xs, s')
           | NONE => NONE) 
      | ruleToTransition _ = NONE
    val transitions = List.mapPartial ruleToTransition G
  in
    if List.length transitions = List.length G
    (* ok, not the most efficient strategy... *)
    then SOME transitions
    else NONE
  end

  (* models : (atom * gensig) -> context -> bool *)
  fun models (nt, G) D = 
    (* try to translate G into a state machine *)
    let
      val M = machinify G
    in
    (* run "produces" on M and D *)
      case M of
           SOME M => Option.isSome (produces nt M D nil)
         | NONE => (print "fail: couldn't machinify\n"; false)
    end

  (* extend : gensig * genrule list -> gensig *)

  (*** Inversion ***)

  val sym = ref ~1
  fun gensym () =
    !sym before sym := !sym - 1


  fun invert_rules (_,   [])           t acc = acc
    | invert_rules (gen, (ays,bs)::rs) t acc =
      let
        val fresh = gensym ()
        val r1 = ([gen], fresh::ays)
        val r2 = (fresh::(deleteFirst t bs), [])
          (* instead of [] should be final context var 
          * OR just remainder of ts list
          * *)
        val acc = 
          if (member t bs) then r1::r2::acc
              else acc
      in
        invert_rules gen (t, rs) acc 
      end

  fun invert1 gen G t = invert_rules (gen, G) t []


  (* invert : (atom * gensig) -> context -> multistep list *)
  fun invert (gen, G) ts =
    List.concat (map (invert1 gen G) ts)

end

structure Test = 
struct
  open Check

  val gen = 0
  val a = 1
  val b = 2
  val c = 3
  val a_or_b = 4
  val cs = 5

  (* Generative signature:
  * gen -o {a_or_b * cs}.
  * a_or_b -o {a}.
  * a_or_b -o {b}.
  * cs -o {c * cs}.
  * cs -o {1}.
  *)

  (*
  val gensig : gensig =
     [([gen], [a_or_b, cs]),
     ([a_or_b], [a]),
     ([a_or_b], [b]),
     ([cs], [c, cs]),
     ([cs], [])]
  *)
  val gensig : gensig =
     [([gen], [a, cs]),
     ([gen], [b, cs]),
     ([cs], [c, cs]),
     ([cs], [])]

  val genpair = (gen, gensig)

  (* Current status of invert:
  * - invert genpair [a];
  * val it = [([0],[999,4]),([999],[])] : multistep list
  *)


  (* testing produces *)
  val machine1 =
    [
      (gen, [a], SOME cs),
      (gen, [b], SOME cs),
      (cs, [c], SOME cs),
      (cs, [], NONE)
    ]

  val machine2 =
    [
      (gen, [a], SOME cs),
      (gen, [b, c], NONE),
      (cs, [c], SOME cs),
      (cs, [], NONE)
    ]


end
