structure NondetEager:> NONDET = 
struct
   datatype 'a m = N | L of 'a | M of 'a m list

   (* Utilities *)
   fun N @ t = t
     | t @ N = t
     | t @ s = M [ t, s ]

   fun many (ts: 'a m list) = 
      case ts of 
         [] => N
       | [ t ] => t
       | _ => M ts  

   (* Interface *)
   val fail: 'a m = N

   fun return (x: 'a): 'a m = L x 

   fun bind (t: 'a m) (f: 'a -> 'b m): 'b m  = 
      case t of 
         N => N
       | L x => f x
       | M xs => M (map (fn y => bind y f) xs) 

   fun letOne (x: 'a) (f: 'a -> 'b m): 'b m = f x

   fun letMany (xs: 'a list) (f: 'a -> 'b m): 'b m =
      many (List.mapPartial 
              (fn x => (case f x of N => NONE | t => SOME t)) 
              (xs))

   fun combine (ts: 'a m list): 'a m = many ts

   fun flatten (t, acc) = 
      case t of 
         N => acc
       | L x => (x :: acc)
       | M ts => List.foldr flatten acc ts  

   fun list (t: 'a m) = rev (flatten (t, []))
   
   fun stream (t: 'a m) = Stream.fromList (list t) 
    
end
