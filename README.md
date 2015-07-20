interactive-lp
==============

Project materials related to logic programming for interactive/reactive systems.

Ad-hoc instructions for anyone who wants to play while Ceptre is in
development:

- Get MLton (http://mlton.org/).
- Clone the repo, and get cmlib into the lib/cmlib directory:

    <code>git submodule update --init --recursive</code>

- From the top-level directory, run

    <code>make</code>

    then

    <code>./ceptre <filename></code>,
  
- Examples live in
<code>examples/</code> and the relevant ones to Ceptre are those that
end in <code>.cep</code>.
  
  So you might try
  
    <code>./ceptre "examples/small.cep"</code>

  Which will run the first <code>#trace</code> command given in that file. 
