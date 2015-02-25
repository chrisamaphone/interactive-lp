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

  exception Unimp
  exception Impossible

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

  (* quiescent : phase -> state -> bool *)
  fun quiescent {name, body} state =
    List.null (applicable_rules state body)

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


  (* step : program -> phase -> atom list -> (ident * atom list) *)
  fun step prog (phase as {name=phase_name, body=rules}) state =
    (* XXX check for quiescence - if so, add qui, check global rules *)
    (* (might have to do the above many times) *)
    (* check phase's rules *)
        (case applicable_rules state rules of
              nil =>
                let
                  val phase' = phase (* XXX *)
                  val state' = state
                in
                  (phase', state')
                end
            | rs => 
                let
                  val {name, lhs, rhs} = select_random rs
                  val state' = removeAtoms state lhs
                  val state'' = IS.addList state' rhs
                in (phase, state'') 
                end )

  (* run : program -> () *)
  fun run prog = raise Unimp

end
