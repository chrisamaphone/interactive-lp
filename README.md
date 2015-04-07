interactive-lp
==============

Project materials related to logic programming for interactive/reactive systems.

Ad-hoc instructions for anyone who wants to play while Ceptre is in
development:

- Get SML/NJ and rlwrap.
- Clone the repo, and get cmlib into the lib/cmlib directory:

    <code>git submodule update --init --recursive</code>

- From the /src directory, run

    <code>rlwrap sml</code>
- From the SML/NJ REPL, do

    <code>CM.make "sources.cm";</code>,
  
  Then
  
    <code>open Top;</code>
- Run one of the shown functions on the path to a file.
<code>runFirst</code> runs the first program given. Examples live in
<code>../examples/</code> and the relevant ones to Ceptre are those that
end in <code>.cep</code>.
  
  So you might try
  
    <code>runFirst "../examples/small.cep";</code>

  Which will run the first <code>#trace</code> command given in that file. 
