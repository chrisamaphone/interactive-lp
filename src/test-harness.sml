structure Test =
struct
  open Ceptre

  fun test1 () = Top.runFirst "../examples/small.cep"
  val ans1 =
    SOME [(Lin, "qui", []), (Lin,"min",[Fn ("r",[])]),
          (Lin,"stage",[Fn ("getmin",[])])]


  val all = [(test1,ans1)]

  fun runAll () =
    map (fn (test,ans) => if test () = ans then "PASS" else "FAIL") all

end
