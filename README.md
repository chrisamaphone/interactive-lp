interactive-lp
==============

Project materials related to logic programming for interactive/reactive systems.

Ad-hoc instructions for anyone who wants to play while Ceptre is in
development:

- Get SML/NJ and rlwrap.
- From the /src directory, run
    rlwrap sml
- From the SML/NJ REPL, do
    CM.make "sources.cm"
  Then
    open Top;
- Run one of the shown functions on the path to a file. "runFirst" runs the
first program given. Examples live in available in
    ../examples/
  So you might try
    runFirst "../examples/small.cep";

    
