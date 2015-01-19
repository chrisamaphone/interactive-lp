structure Subord  =
struct

    
  fun terminal a [] = true
    | terminal a ((_, _, nt, _, _)::rules)
      = not (a = nt) andalso terminal a rules

  (* fun initial = *)

  fun subordExtract' GI unprocessed_rules accum =
  case unprocessed_rules of
       [] => []
     | ((name, _, nt, _, sucs)::GI') =>
         let
           val ntsucs = List.filter (fn x => not (terminal x GI)) sucs
           val consumers = 
             map (fn n => List.filter (fn (_,_,nt',_,_) => n = nt') GI)
              ntsucs
           val consumers = List.concat consumers
           val names = map (#1) consumers
         in
           subordExtract' GI GI' ((name,names)::accum)
         end

  fun subordExtract GI = subordExtract' GI GI []


end
