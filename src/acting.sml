structure Acting =
struct
  
  open Ceptre
  exception IllFormed

  type action = Ceptre.context * (Ceptre.term list) -> unit

  (* unary to digit *)
  fun unaryToDecimal n =
    case n of
         Fn ("z", []) => 0
       | Fn ("s", [n']) => 1 + (unaryToDecimal n')
       | _ => raise IllFormed

  fun ctxToCellsWalls ctx cells walls =
    case ctx of
         (Lin, "cell", [x,y])::ctx =>
         let
           val xn = unaryToDecimal x
           val yn = unaryToDecimal y
         in
           ctxToCellsWalls ctx ((xn,yn)::cells) walls
         end
       | (Lin, "wall", [x,y,Fn(dir,[])])::ctx =>
           let
             val xn = unaryToDecimal x
             val yn = unaryToDecimal y
           in
             ctxToCellsWalls ctx cells (((xn,yn),dir)::walls)
           end
       | [] => (cells, walls)
       | (other::rest) => ctxToCellsWalls rest cells walls

  fun stringToWall "east" (_,s) = (true,s)
    | stringToWall "south" (e,_) = (e,true)
    | stringToWall _ _ = raise IllFormed

  fun oneWall wall = stringToWall wall (false,false)

  fun cellsWallsToMap cells walls =
  let
    val init_map = map (fn x => (x,(false,false))) cells
    fun update m cell wall =
      case lookupSplit cell m of
           NONE => (cell, oneWall wall)::m
         | SOME (walls, m') => (cell, stringToWall wall walls)::m'
  in
    foldl (fn ((cell,dir),m) => update m cell dir) init_map walls
  end

  fun compare ((x1,y1), (x2,y2)) =
    if y1 < y2 then LESS
    else if x1 < x2 then LESS
    else if x1 = x2 andalso y1 = y2 then EQUAL
    else GREATER

  fun compare_entries ((c1,w1),(c2,w2)) = compare (c1,c2)

  fun render_wall (ewall, swall) =
    (if swall then "_" else " ")
    ^ (if ewall then "|" else " ")

  fun render_cell ((x,y), walls) =
  (if y = 0 andalso x > 0 then "\n" else "")
    ^
    (render_wall walls)

  fun sort m = Mergesort.sort compare_entries m

  fun render_table cwMap =
  (String.concat (map render_cell (sort cwMap)))
  ^ "\n"


  (* render_maze : action
  *
  * takes a context of (Lin, "cell", [x,y])
  * and (Lin, "wall", [x,y]) preds
  * and prints out the corresponding maze. *)
  fun render_maze ctx =
  let
    val (cells, walls) = ctxToCellsWalls ctx [] []
    val cwMap = cellsWallsToMap cells walls
  in
    render_table cwMap
  end

 (* for testing *)
  val allWalls = 
  [((0,0),(true,true)),((0,1),(true,true)),((0,2),(true,true)),
   ((0,3),(true,true)),((0,4),(true,true)),((0,5),(true,true)),
   ((0,6),(true,true)),((0,7),(true,true)),((0,8),(true,true)),
   ((0,9),(true,true)),((1,0),(true,true)),((1,1),(true,true)),
   ((1,2),(true,true)),((1,3),(true,true)),((1,4),(true,true)),
   ((1,5),(true,true)),((1,6),(true,true)),((1,7),(true,true)),
   ((1,8),(true,true)),((1,9),(true,true)),((2,0),(true,true)),
   ((2,1),(true,true)),((2,2),(true,true)),((2,3),(true,true)),
   ((2,4),(true,true)),((2,5),(true,true)),((2,6),(true,true)),
   ((2,7),(true,true)),((2,8),(true,true)),((2,9),(true,true)),
   ((3,0),(true,true)),((3,1),(true,true)),((3,2),(true,true)),
   ((3,3),(true,true)),((3,4),(true,true)),((3,5),(true,true)),
   ((3,6),(true,true)),((3,7),(true,true)),((3,8),(true,true)),
   ((3,9),(true,true)),((4,0),(true,true)),((4,1),(true,true)),
   ((4,2),(true,true)),((4,3),(true,true)),((4,4),(true,true)),
   ((4,5),(true,true)),((4,6),(true,true)),((4,7),(true,true)),
   ((4,8),(true,true)),((4,9),(true,true)),((5,0),(true,true)),
   ((5,1),(true,true)),((5,2),(true,true)),((5,3),(true,true)),
   ((5,4),(true,true)),((5,5),(true,true)),((5,6),(true,true)),
   ((5,7),(true,true)),((5,8),(true,true)),((5,9),(true,true)),
   ((6,0),(true,true)),((6,1),(true,true)),((6,2),(true,true)),
   ((6,3),(true,true)),((6,4),(true,true)),((6,5),(true,true)),
   ((6,6),(true,true)),((6,7),(true,true)),((6,8),(true,true)),
   ((6,9),(true,true)),((7,0),(true,true)),((7,1),(true,true)),
   ((7,2),(true,true)),((7,3),(true,true)),((7,4),(true,true)),
   ((7,5),(true,true)),((7,6),(true,true)),((7,7),(true,true)),
   ((7,8),(true,true)),((7,9),(true,true)),((8,0),(true,true)),
   ((8,1),(true,true)),((8,2),(true,true)),((8,3),(true,true)),
   ((8,4),(true,true)),((8,5),(true,true)),((8,6),(true,true)),
   ((8,7),(true,true)),((8,8),(true,true)),((8,9),(true,true)),
   ((9,0),(true,true)),((9,1),(true,true)),((9,2),(true,true)),
   ((9,3),(true,true)),((9,4),(true,true)),((9,5),(true,true)),
   ((9,6),(true,true)),((9,7),(true,true)),((9,8),(true,true)),
   ((9,9),(true,true))]

end
