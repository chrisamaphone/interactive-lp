structure Traces =
struct

type step = {rule: Ceptre.ident, 
             (* consts: Ceptre.term list, *)
             input: CoreEngine.value,
             outputs: CoreEngine.ctx_var list}

type trace = step list
  (* XXX also initial and final? *)
              

fun transitionToStep T outputs =
  let
    val {rule, arg} = CoreEngine.transitionProof T
  in
    {rule=rule, input=arg, outputs=outputs}
  end

fun stepToString {rule,input,outputs} =
  let
    (* XXX this should gensym new varnames *)
    val outputStrings = map CoreEngine.varToString outputs
    val outputsString = String.concatWith ", " outputStrings
    val patternString = "["^outputsString^"]"
    val inputString = rule^" "^(CoreEngine.valueToString input)
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
  Dot.Node (name, [("shape","box"),("label","\""^label^"\"")])

fun makeVarNode x =
  Dot.Node (CoreEngine.varToString x, [])

fun makeEdgeTo   n2 n1 = Dot.Edge (n1,n2)
fun makeEdgeFrom n1 n2 = Dot.Edge (n1,n2)

(* convert [step] to list of [Dot.line]s *)
fun stepToLines {rule,input,outputs} =
let
  val nodeName : string = gensym ()
  val transitionNode : Dot.line = makeTransitionNode nodeName rule
  val outputNodes : Dot.line list = map makeVarNode outputs
  val inputVars : CoreEngine.ctx_var list = CoreEngine.valueDeps input
  val inputVarNames : string list = map CoreEngine.varToString inputVars
  val outputVarNames : string list = map CoreEngine.varToString outputs
  val inEdges : Dot.line list = map (makeEdgeTo nodeName) inputVarNames 
  val outEdges : Dot.line list = map (makeEdgeFrom nodeName) outputVarNames
in
  transitionNode::(outputNodes@inEdges@outEdges)
end

(* convert trace to dot graph *)
fun traceToGraph trace =
let
  val lines = map stepToLines trace
  val lines = List.concat lines
in
  Dot.Digraph lines
end

end
