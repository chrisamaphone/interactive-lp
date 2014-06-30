Initial prototype for automatic generative invariant checking. Most
documentation is in the types and comments in the GENSIGS signature in
gensig-checking.sml.

The idea is to give a generative invariant (grammar of contexts given in
linear logic) + a linear logic program, and ask whether the given logic
program satisfies the invariant.

Currently the central mechanism involved is "inversion," i.e. given a rule

A -o {B}

in the linear logic program, and a seed atom "gen" in the generative
invariant, we want to split the trace

gen --> A, X

(where X is a parametric variable standing for the rest of the context)

into as many pieces as possible, then check that the signature *extended*
with those pieces extracted from inversion can generate the context "B, X".



Usage:

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

Or use SML/NJ's builtin settings to print deeper data structure, e.g.
- Control.Print.printDepth := 100;
