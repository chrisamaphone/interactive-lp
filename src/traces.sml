structure Traces =
struct

type step = {rule: Ceptre.ident, 
             consts: Ceptre.term list,
             input: CoreEngine.value,
             (* x_1 : A_1 ... x_n : A_n *)
             outputs: (CoreEngine.ctx_var * Ceptre.atom) list}

type trace = step list
  (* XXX also initial and final? *)
              

fun transitionToStep T outputs : step =
  let
    val {rule, arg, tms} = CoreEngine.transitionProof T
  in
    {rule=rule, consts=tms, input=arg, outputs=outputs}
  end

fun stepToString ({rule,consts,input,outputs} : step) =
  let
    val outputStrings = map (CoreEngine.varToString o (#1)) outputs
    val outputsString = String.concatWith ", " outputStrings
    val patternString = "["^outputsString^"]"
    val constStrings : string list = map Ceptre.termToString consts
    val constsString : string = String.concatWith " " constStrings
    val inputString = rule^" "^constsString^" "^(CoreEngine.valueToString input)
  in
    "let "^patternString^" = "^inputString^";"
  end

val name = ref 0
fun gensym () =
let
  val i = !name
  val s = "t"^(Int.toString i)
  val () = name :=  i+1
in
  s
end

fun makeTransitionNode name label =
  Dot.Node (name, [("shape","box"),("style","filled"),("fillcolor","green"),("label","\""^label^"\"")])

fun makeVarNode (x, x_type) =
let
  val name = (* CoreEngine.varToString x *)  Ceptre.atomToString x_type
  val label = name
in
  Dot.Node (CoreEngine.varToString x, [("style","filled"),("fillcolor","skyblue"),("label","\""^label^"\"")])
end

fun makeEdgeTo   n2 n1 = Dot.Edge (n1,n2)
fun makeEdgeFrom n1 n2 = Dot.Edge (n1,n2)

(* convert [step] to list of [Dot.line]s *)
fun stepToLines ({rule,consts,input,outputs} : step) =
let
  val nodeName : string = gensym ()
  val constStrings = map Ceptre.termToString consts
  val label = rule ^ "\\n" ^ (String.concatWith " " constStrings)
  val transitionNode : Dot.line = makeTransitionNode nodeName label
  val outputNodes : Dot.line list = map makeVarNode outputs
  val inputVars : CoreEngine.ctx_var list = CoreEngine.valueDeps input
  val inputVarNames : string list = map CoreEngine.varToString inputVars
  val outputVarNames : string list = map (CoreEngine.varToString o (#1)) outputs
  val inEdges : Dot.line list = map (makeEdgeTo nodeName) inputVarNames 
  val outEdges : Dot.line list = map (makeEdgeFrom nodeName) outputVarNames
in
  transitionNode::(outputNodes@inEdges@outEdges)
end

(* convert trace to dot graph *)
fun traceToGraph (init : CoreEngine.fastctx) trace =
let
  val init_nodes = map makeVarNode (CoreEngine.get_concrete init)
  val lines = map stepToLines trace
  val lines = init_nodes @ (List.concat lines)
in
  Dot.Digraph lines
end

end
