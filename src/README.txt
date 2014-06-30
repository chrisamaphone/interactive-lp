Run
$ sml
Standard ML of New Jersey v110.76 [built: Mon Aug 19 10:38:12 2013]
- CM.make "sources.cm";
[...]

To run rest methods:
- open Test;
[...] 

e.g.
- invs_test ();
val it =
  Node
    [(([#],[#,#]),([#],[#,#,#]),Node [#,#]),
     (([#],[#,#]),([#,#],[#,#,#]),Node [#,#])] : invTree

then to see the tree use
- showTree it;
val it =
  [([0],[~1,0]),([~1],[3,3,3]),([~1],[~2,0]),([~2,2],[3,3]),([~2,2],[~3,0]),
   ([~3,2],[3]),([~3,2],[~4,0]),([~4,2],[]),([~3,2],[~4,5]),([~4,5],[]),
   ([~2,2],[~3,5]),([~3,5],[3]),...] : trace list
