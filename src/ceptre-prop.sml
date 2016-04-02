(* Propositional fragment of Ceptre programs *)

(*
* Implements two kinds of sensor atoms:
* Push sensors and pull sensors.
*
* Push sensors affect the *state update* part of the program -- they allow
* additional atoms to be inserted into the state. They act like positive atoms.
*
* Pull sensors affect the *rule applicability checking* part of the program
* -- they enable a rule to "query" the runtime environment by mentioning a pull
* sensor in its lhs. (Including reflective queries, e.g. for negation.) They act
* like negative atoms. A check for a pull sensor will be executed for every rule
* that mentions one, as long as its prefix (lhs before the sensor is mentioned)
* is satisfied.
*
*)

structure CeptreProp = struct

  type atprop = int
  type var = int
  datatype pull_sensor = ReadString of var | NoCs | Read1 | Read0
  datatype atom = Lin of atprop | Pers of atprop | Sense of pull_sensor

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

  fun sensorToString (ReadString x) = "ReadString "^(Int.toString x)
    | sensorToString NoCs = "NoCs"
    | sensorToString Read1 = "Read1"
    | sensorToString Read0 = "Read0"

  fun atom_to_string (Lin x) = Int.toString x
    | atom_to_string (Pers x) = "!"^(Int.toString x)
    | atom_to_string (Sense s) = "sense "^(sensorToString s)

  fun state_to_string (phase_id, state) =
  let
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

    fun tryDeleteOne nil atom = NONE
      | tryDeleteOne (x::xs) atom =
          if x = atom then (SOME xs) else 
            (case tryDeleteOne xs atom of
                  NONE => NONE
                | SOME st => SOME (x::st))

    fun deleteOne nil atom = 
          let
            val () = print ("failed to delete "^(atom_to_string atom))
          in
            raise Impossible
          end
      | deleteOne (x::xs) atom = if x = atom then xs else
          x::(deleteOne xs atom)

    fun addList state atoms = state@atoms
  end

  fun existsAll atoms state =
    foldl (fn (a, b) => b andalso IS.member state a) true atoms

  fun applicable_rules state rules =
    List.filter (fn {name,lhs,rhs} => existsAll lhs state) rules

  structure PullSensors =
  struct
    val c = Lin 3
    (* val all = [ReadString, NoCs, Read0, Read1] *)

    (* in the first-order case this would return a substitution *)
    fun query state sensor =
      (case sensor of
            ReadString x =>
            (case TextIO.inputLine (TextIO.stdIn) of
                  NONE => NONE
                | SOME s => SOME [(x, s)])
          | NoCs => if List.exists (fn x => x=c ) state 
                    then NONE else SOME []
          | Read0 =>
              (case TextIO.inputLine (TextIO.stdIn) of
                    NONE => NONE
                  | SOME i => 
                      (case Int.fromString i of 
                            SOME i => if i = 0 then SOME [] else NONE
                          | NONE => SOME []))
          | Read1 =>
              (case TextIO.inputLine (TextIO.stdIn) of
                    NONE => NONE
                  | SOME i => (case Int.fromString i of
                                    SOME i => if i = 1 then SOME [] else NONE
                                  | NONE => NONE )))
  end

  (* XXX eventually this should be invoked as rhs but at this point we're
  * getting into a first-order impl. *)
  fun apply [] atoms = atoms
    | apply ((var,value)::sub) atoms =
      (* XXX not real *)
      atoms

  fun sat [] _ = true
    | sat (x::xs) (state : atom list) =
      (case x of
            Lin _ => (case IS.tryDeleteOne state x of
                           NONE => false
                         | SOME state' => sat xs state')
          | Pers _ => raise Unimp
          | Sense sensor =>
              case PullSensors.query state sensor of
                   NONE => false
                | SOME subst => sat (apply subst xs) state
      )

  fun applicable_rules state rules =
    List.filter (fn {name,lhs,rhs} => sat lhs state) rules

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

  (** selecting rules **)

  fun removeAtoms state [] = state
    | removeAtoms state (at::atoms) =
      (case at of
            Lin x => removeAtoms (IS.deleteOne state at) atoms
          | Pers x => state
          | Sense s => state)
    
    (*
    foldl (fn (at, st) => IS.deleteOne st at) state atoms
    *)

  (* XXX make this actually random *)
  val rand = Random.rand (293847, 923423)

  fun select_random rs =
  let
    val idx = Random.randRange (0, List.length rs - 1) rand
  in
    List.nth (rs, idx)
  end

  datatype 'a answer = DONE of 'a | NEXT of 'a

  structure PushSensors =
  struct
    datatype sensor = CoinFlip

    val all = [CoinFlip]

    val heads = Lin 10
    val tails = Lin 11

    fun sense state [] = state
      | sense state (sensor::sensors) =
        let 
          val state' =
            (case sensor of
              CoinFlip => if Random.randRange (0,1) rand = 0
                      then heads::state else tails::state)
        in
          sense state' sensors
        end

  end

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
                  | ls => (* applicable phase links *)
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
                  val state = removeAtoms state lhs
                  val state = IS.addList state rhs
                  (* check for sensing preds *)
                  (* XXX turning off push sensors for now
                  val state = PushSensors.sense state PushSensors.all 
                  *)
                in NEXT (phase, state) 
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
    
  (* Testing pull sensors *)
  val rules3 =
    {name="r1", lhs=[a, Sense (ReadString (~1))], rhs=[]}::rules1

  val prog3 =
    {phases=[{name="phase1",body=rules3},
             {name="phase2",body=rules2}],
     links=[{name="link1",pre_phase="phase1",post_phase="phase2",
              lhs=[],rhs=[]}],
     init_phase="phase1",
     init_state=init1}

  (* Slightly bigger test case:
  *  Two controls, one of which eats an a and one of which spits one out.
  *
  *  phase read = {
  *    stdin X -o input X.
  *  }
  *
  *  phase process = {
  *    input 1 -o a.
  *    input 0 * a -o .
  *  }
  *
  *  phase clean = {
  *    input _ -o .
  *  }
  *
  *  qui * phase read -o phase process.
  *  qui * phase process -o phase clean.
  *  qui * phase clean -o phase read.
  *
  *)

  val tok = Lin 77
  val input_1 = c
  val input_0 = d

  val read_rule1 =
    {name = "read_rule1", lhs=[tok, Sense Read1], rhs=[input_1]}
  val read_rule2 =
    {name = "read_rule2", lhs=[tok, Sense Read0], rhs=[input_0]}
  
  val process_rule1 =
    {name = "proc_rule1", lhs=[input_1], rhs=[a]}
  val process_rule2 =
    {name = "proc_rule2", lhs=[input_0,a], rhs=[]}

  val clean_rule1 =
    {name = "clean_rule1", lhs=[input_0], rhs=[]}
  val clean_rule2 =
    {name = "clean_rule2", lhs=[input_1], rhs=[]}

  val phase_read =
    {name = "read",
     body = [read_rule1, read_rule2]}

  val phase_process =
    {name = "process",
     body = [process_rule1, process_rule2]}

  val phase_clean =
    {name = "clean",
     body = [clean_rule1, clean_rule2]}

  val read01_links =
    [ {name="l1", pre_phase="read", lhs=[], post_phase="process", rhs=[]},
      {name="l2", pre_phase="process", lhs=[], post_phase="clean",rhs=[]},
      {name="l3", pre_phase="clean", lhs=[], post_phase="read", rhs=[tok]}
    ]

  val init_read = [tok]

  val prog_read01 =
    {phases = [phase_read, phase_process, phase_clean],
     links = read01_links,
     init_phase = "read",
     init_state = [tok]
    }
end
