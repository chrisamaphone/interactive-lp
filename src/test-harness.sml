structure Test =
struct
  open Ceptre

  fun test0 () = Top.run "../examples/small.cep" 0
  val ans0 =
    SOME [(Lin,"qui",[]),(Lin,"green",[]),(Lin,"green",[]),(Lin,"green",[]),
         (Lin,"green",[]),(Lin,"stage",[Fn ("blue_green",[])])]

  fun test1 () = Top.run "../examples/small.cep" 1
  val ans1 =
    SOME [(Lin, "qui", []), (Lin,"min",[Fn ("r",[])]),
          (Lin,"stage",[Fn ("getmin",[])])]


  val all = [(test1,ans1), (test0,ans0)]

  fun runAll () =
    map (fn (test,ans) => if test () = ans then "PASS" else "FAIL") all

end
