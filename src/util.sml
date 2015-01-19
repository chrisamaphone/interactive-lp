(* type-agnostic utility functions *)
structure Util = struct

  fun filter_nones [] = []
    | filter_nones (NONE::L) = filter_nones L
    | filter_nones ((SOME x)::L) = x::(filter_nones L)

  fun mapi' i f [] = []
    | mapi' i f (x::xs) = (f(i,x))::(mapi' (i+1) f xs)

  fun mapi f l = mapi' 0 f l

  fun member x = List.exists (fn x' => x = x')

  fun deleteAll x = List.filter (fn x' => x <> x')

  fun deleteFirst x [] = []
    | deleteFirst x (y::ys) = if x = y then ys else y::(deleteFirst x ys)

  fun deleteFirstIfMember x [] = NONE
    | deleteFirstIfMember x (y::ys) = if x = y then SOME ys else
      (case deleteFirstIfMember x ys of
            NONE => NONE
          | SOME ys' => SOME (y::ys'))

  fun concatMap f ls = List.concat (map f ls)

end
