structure CommutativeMonoid = struct

  (* equality *)
  fun eq [] [] = true
    | eq (x::xs) ys = 
      (case Util.deleteFirstIfMember x ys of
            NONE => false
          | SOME ys => eq xs ys)
    | eq _ _ = false 

  (* difference *)
  fun diff C []        = SOME C
    | diff [] (c::C)   = NONE
    | diff C1 (c2::C2) =
        (case Util.deleteFirstIfMember c2 C1 of
              NONE     => NONE
            | SOME C1' => diff C1' C2)

  (* intersection *)
  fun intersect [] _ accum = accum
    | intersect _ [] accum = accum
    | intersect (c1::C1) C2 accum =
      (case Util.deleteFirstIfMember c1 C2 of
           NONE => intersect C1 C2 accum
         | SOME C2' => intersect C1 C2' (c1::accum)
      )

  (* complement intersect. C1 \ (C1 /\ C2) *)
  fun xnor C1 [] = C1
    | xnor [] C2 = []
    | xnor (c1::C1) C2 =
      (case Util.deleteFirstIfMember c1 C2 of
            NONE     => c1::(xnor C1 C2)
          | SOME C2' => xnor C1 C2')

end
