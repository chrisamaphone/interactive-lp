(* Some simple datatypes for Dot/Graphviz graphs and mechanisms for turning them
* into strings. *)
structure Dot =
struct

  type node = string
  type attr = string
  type attr_val = string

  datatype line = 
    Node of node * ((attr * attr_val) list)
  | Edge of node * node
  
  datatype dotgraph =
    Graph of line list
  | Digraph of line list

  fun attrToString a = a
  fun attr_valToString v = v

  fun attrAndValToString (a, v) =
    a^"="^v

  fun avsToString avs =
  let
    val avstrings = map attrAndValToString avs
    val avstring = String.concatWith "," avstrings
  in
    case avstrings of
         [] => ""
       | _ => " [" ^ avstring ^ "]"
  end

  fun nodeToString (s, attrs) = 
    s ^ (avsToString attrs)

  fun edgeToString (n1, n2) =
    n1 ^ " -- " ^ n2

  fun diEdgeToString (n1, n2) =
    n1 ^ " -> " ^ n2

  fun lineToString e2s line =
    (case line of
         Node n => nodeToString n
       | Edge e => e2s e) ^ ";"

  fun graphToString g =
    case g of
         Graph lines =>
         let
           val linestrings = map (lineToString edgeToString) lines
           val linesString = String.concatWith "\n" linestrings
         in
           "graph {\n"^linesString^"\n}"
         end
       | Digraph lines =>
           let
             val linestrings = map (lineToString diEdgeToString) lines
             val linesString = String.concatWith "\n" linestrings
           in
             "digraph {\n"^linesString^"\n}"
           end

  (* Tests *)
  val n = ("t1", [("shape","box"),("size","big")])

  fun nd x = Node (x,[])

  val g = 
    Digraph 
      [nd "x1", nd "x2", nd "x3", Node("t1",[("shape","box")]),
        Edge ("x1","t1"), Edge ("t1","x2")]

end
