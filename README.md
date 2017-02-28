interactive-lp
==============

This is the source repository for Ceptre, a tiny logic programming language
for prototyping rulesets that you can run, interact with, and analyze.

Binaries for OS X/Win/Linux available here:
https://drive.google.com/drive/folders/0B6BJA78gViuAN3A0WlVkdXBjMk0

Ceptre runs on a Unix-based command line (for now), so you will need to
know your way around a shell to use it.

Please see [this tutorial](tutorial.md) to get started!


To compile from source:

- Get MLton (http://mlton.org/).
- Clone the repo, and get cmlib into the lib/cmlib directory:

    <code>git submodule update --init --recursive</code>

- From the top-level directory, run

    <code>make</code>

    then

    <code>./ceptre path/to/filename.cep</code>,
  
- Examples live in
<code>examples/</code> and the relevant ones to Ceptre are those that
end in <code>.cep</code>.
  
  So you might try
  
    <code>./ceptre "examples/small.cep"</code>

  Which will run the first <code>#trace</code> command given in that file. 
