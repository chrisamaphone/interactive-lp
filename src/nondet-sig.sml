signature NONDET = 
sig
   type 'a m
   
   val fail: 'a m
   val return: 'a -> 'a m
   val bind: 'a m -> ('a -> 'b m) -> 'b m
   val letOne: 'a -> ('a -> 'b m) -> 'b m

   val combine: 'a m list -> 'a m
   val letMany: 'a list -> ('a -> 'b m) -> 'b m

   val list: 'a m -> 'a list
   val stream: 'a m -> 'a Stream.stream
end
