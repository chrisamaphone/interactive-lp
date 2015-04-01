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

  fun render_cell (ewall, swall) =
    (if swall then "_" else " ")
    ^ (if ewall then "|" else " ")


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

       (*
       let
         fun pertinent_wall 
         val walls =
  List.filter (fn (Lin, "wall", [x',y',dir]) => x=x' andalso y=y') 
  *)

  (* render_maze : action
  *
  * takes a context of (Lin, "cell", [x,y])
  * and (Lin, "wall", [x,y]) preds
  * and prints out the corresponding maze. *)

end
