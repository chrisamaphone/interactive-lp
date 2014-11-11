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

To run test methods:
- open Test;
[...] 

Use SML/NJ's builtin settings to print deeper into a data structure, e.g.
- Control.Print.printDepth := 100;
