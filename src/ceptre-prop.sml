(* Propositional fragment of Ceptre programs *)

structure CeptreProp = struct

  type atprop = int
  datatype atom = Lin of atprop | Pers of atprop

  type ident = string
  type rule = {name : ident, lhs : atom list, rhs : atom list} 

  (* a phase is a name & a list of rules *)
  type phase = {name : ident, body : rule list}

  (* qui * phase p * S -o {phase p' * S'} =
  *   (?, p, S, p', S') *)
  type phase_rule = 
    {name : ident, 
     pre_phase : ident, 
     lhs : atom list,
     post_phase : ident,
     rhs : atom list}

  (* program is a set of phases, a set of phase rules, an identifier for an
  * initial phase, and an initial state *)
  type program = 
    {phases : phase list, 
     links : phase_rule list, 
     init_phase : ident,
     init_state : atom list}

  fun lookup_phase phase phases =
    List.find (fn {name,body} => name = phase) phases

  exception Unimp
  exception Impossible

  (* Stringifiers *)

  fun state_to_string (phase_id, state) =
  let
    fun atom_to_string (Lin x) = Int.toString x
      | atom_to_string (Pers x) = "!"^(Int.toString x)
    val atom_strings = map atom_to_string state
    val state_string = String.concatWith ", " atom_strings
  in
    "PHASE: "
    ^ phase_id
    ^ " | "
    ^ state_string
  end

  (* Core program evolution logic *)

  structure IS = struct
    fun member state atom = List.exists (fn x => x=atom) state
    fun deleteOne nil atom = raise Impossible
      | deleteOne (x::xs) atom = if x = atom then xs else
          x::(deleteOne xs atom)
    fun addList state atoms = state@atoms
  end

  fun existsAll atoms state =
    foldl (fn (a, b) => b andalso IS.member state a) true atoms

  fun applicable_rules state rules =
    List.filter (fn {name,lhs,rhs} => existsAll lhs state) rules

  fun applicable_phase_rules state current_phase phase_rules =
    List.filter
      (fn {name, pre_phase, lhs, post_phase, rhs}
        => current_phase = pre_phase
            andalso (existsAll lhs state))
      phase_rules

  (* quiescent : phase -> state -> bool *)
  (* not currently used?
  fun quiescent {name, body} state =
    List.null (applicable_rules state body)
    *)

  (** selecting rules **)
  fun removeAtoms state atoms =
    foldl (fn (at, st) => IS.deleteOne st at) state atoms

  (* XXX make this actually random *)
  val rand = Random.rand (293847, 923423)

  fun select_random rs =
  let
    val idx = Random.randRange (0, List.length rs - 1) rand
  in
    List.nth (rs, idx)
  end

  datatype 'a answer = DONE of 'a | NEXT of 'a

  (* step : program -> phase -> atom list -> (ident * atom list) answer *)
  fun step (prog:program) (phase as {name=phase_name, body=rules}) state =
    (* XXX check for quiescence - if so, add qui, check global rules *)
    (* (might have to do the above many times) *)
    (* check phase's rules *)
        (case applicable_rules state rules of
              nil => (* quiesced within the phase *)
              let 
                val {phases, links, ...} = prog
              in
              (case applicable_phase_rules state phase_name links of
                    nil => DONE (phase, state) (* globally quiesced *)
                  | ls => 
                      let
                        val {name,pre_phase,lhs,post_phase,rhs}
                        : phase_rule
                          = select_random ls
                        val state' = removeAtoms state lhs
                        val state'' = IS.addList state' rhs
                        val SOME phase' = lookup_phase post_phase phases
                        (* match exception here means an ill-formed phase link
                        * (post-phase is not in the program) *)
                      in
                        NEXT (phase', state'')
                      end
              )
              end
            | rs => 
                let
                  val {name, lhs, rhs} = select_random rs
                  val state' = removeAtoms state lhs
                  val state'' = IS.addList state' rhs
                in NEXT (phase, state'') 
                end )

  (* step_star : program -> phase -> atom list -> (ident * (atom list)) *)
  fun step_star prog (phase as {name,body}) state =
    let (* DEBUG *)
      val () = print ((state_to_string (name, state))^"\n")
    in
      (case (step prog phase state) of
         DONE (phase', state')  => (phase', state') 
       | NEXT (phase', state')  => step_star prog phase' state')
    end

  (* run : program -> (ident * (atom list)) option *)
  fun run (prog as {phases,links,init_phase,init_state}) =
    (case lookup_phase init_phase phases of
         NONE => 
          let
            val () = print ("Couldn't find initial phase "^init_phase)
          in
            NONE
          end
      |  SOME phase => SOME (step_star prog phase init_state) )


  (* tests *)
  val (a,b,c,d,e) = (Lin 1, Lin 2, Lin 3, Lin 4, Lin 5)
  val rules1 =
    [{name = "r1", lhs = [a], rhs = [b,b]},
     {name = "r2", lhs = [b], rhs = [c]}]
  val init1 = [a,a,a]  
  val prog1 = {phases=[{name="phase1",body=rules1}],
               links=[],
               init_phase="phase1",
               init_state=init1}

  val rules2 =
    [{name = "r1", lhs = [c], rhs = [a]}]
  val prog2 : program =
    {phases=[{name="phase1",body=rules1},
             {name="phase2",body=rules2}],
     links=[{name="link1",pre_phase="phase1",post_phase="phase2",
              lhs=[],rhs=[]}],
     init_phase="phase1",
     init_state=init1}
    
end
