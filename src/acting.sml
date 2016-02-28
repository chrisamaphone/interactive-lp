structure Acting =
struct
  
  open Ceptre
  exception IllFormed

  type action = Ceptre.context * (Ceptre.term list) -> unit

    (* IF reporting/prompting *)

  fun prompt_with s = (print s; print "\n> ")

  (* action: print a description to the screen followed by prompt. *)
  fun printDescription (_, args) =
    case args of
         [Fn (description, [])] => prompt_with description
       | _ => raise IllFormed

  (* action: same as the above, but without strings in the language yet,
  *  we need a builtin description table. *)
  fun getAndPrintDescription (_, args) =
    let
      val table =
        [("foyer", "You are in a modest foyer."),
         ("cloakroom", "The cloakroom: a room for hanging cloaks."),
         ("bar", "The bar: a tawdry place."),
         ("darkness", "It's dark, and you can't see a thing."),
         ("cloak", "An inky black cloak you picked up at a yard sale."),
         ("hook", "A brass hook fit for hanging things on."),
         ("player", "Dashing as ever."),
         ("trinket", "Nothing especially valuable.")]
    in
    case args of
         [Fn (noun, [])] =>
         (case lookup noun table of
               SOME desc => prompt_with desc
             | _ => prompt_with "You don't see that here.")
        | _ => raise IllFormed
    end

  fun reportFailure (_, args) =
    case args of
         [] => prompt_with "That doesn't make sense here."
       | _ => raise IllFormed

  fun reportDropping (_, args) =
    case args of
         [Fn (noun, [])] => prompt_with (noun^" dropped.")
       | _ => raise IllFormed

  fun reportTaking (_, args) =
    case args of
         [Fn (noun, [])] => prompt_with (noun^" taken.")
       | _ => raise IllFormed

  fun listInventory (ctx,args) =
    case args of
         [] => 
         let
           fun inv (_,"inventory",[Ceptre.Fn(noun,[])]) = SOME noun
             | inv _ = NONE
           val inv = List.mapPartial inv ctx 
           val inv_string = String.concatWith ", " inv
         in
           prompt_with ("You are carrying: "^inv_string)
         end
      | _ => raise IllFormed
                    
  fun listThingsAt (ctx,args) =
    case args of
         [the_place] =>
          let
            fun at (_, "at", [Ceptre.Fn(noun,[]), its_place]) =
                  if its_place = the_place andalso not (noun="player") 
                  then SOME noun else NONE 
              | at _ = NONE
            val things_here = List.mapPartial at ctx
            val here_string = String.concatWith ", " things_here
          in
            case things_here of
                 [] => ()
                | _ => prompt_with ("You see here: " ^ here_string)
          end
       | _ => raise IllFormed

  fun reportFooling (ctx,args) =
    case args of
         [] => prompt_with "You knock some stuff over in the dark."
       | _ => raise IllFormed

  (* mazegen example *)

  (* unary to digit *)
  fun unaryToDecimal n =
    case n of
         Fn ("z", []) => 0
       | Fn ("s", [n']) => 1 + (unaryToDecimal n')
       | _ => raise IllFormed


  fun predToDecimal (_, name, [n]) = name ^ " " ^ (Int.toString (unaryToDecimal n))
    | predToDecimal _ = raise IllFormed

  fun ctxToDecimal ctx =
    map (fn x => predToDecimal x handle IllFormed => atomToString x) ctx

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
    case (Int.compare (x1,x2), Int.compare (y1,y2)) of
      (LESS,_) => LESS
    | (EQUAL,o2) => o2
    | (GREATER,_) => GREATER

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

  fun filter_ctx c =
    List.filter 
      (fn (Lin, "wall",_) => true 
        | (Lin,"cell",_) => true
        | _ => false)
      c


  (* render_maze : action
  *
  * takes a context of (Lin, "cell", [x,y])
  * and (Lin, "wall", [x,y]) preds
  * and prints out the corresponding maze. *)
  fun render_maze ctx =
  let
    val relevant_ctx = filter_ctx ctx
    val (cells, walls) = ctxToCellsWalls relevant_ctx [] []
    val cwMap = cellsWallsToMap cells walls
    val sorted = sort cwMap
  in
    render_table sorted
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

  val action_table =
    [ ("describe", getAndPrintDescription),
      (* ("report", report), (* XXX *) *)
      ("report_fail", reportFailure),
      ("report_dropping", reportDropping),
      ("report_taking", reportTaking),
      (* ("list", listThings), (* XXX *) *)
      ("list_inventory", listInventory),
      ("list_things_at", listThingsAt),
      ("report_fooling", reportFooling)
    ]

  fun run ((action_id,args), ctx) =
    case lookup action_id action_table of
         SOME f => f (ctx, args) 
       | NONE => raise IllFormed (* XXX print error? *)

  (*
  fun lookup_pred (_,pred,args) =>
    case lookup pred action_table of
         SOME f => SOME (f,args)
       | NONE => NONE
       *)

  fun maybe_run ((_,pred,args), ctx) =
    case lookup pred action_table of
         SOME f => f (ctx, args)
       | NONE => ()

end
