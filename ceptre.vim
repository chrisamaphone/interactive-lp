syn clear

" Just about anything in Ceptre is a keyword character
setlocal iskeyword+=\",~,@,!,#-',*-45,47-57,59-90,94-122,\|,^:

syn keyword ceptrePercentKey #mode #interactive #trace #builtin
syn keyword ceptreType type pred bwd stage context
syn match ceptrePunct ":\|\.\|="
syn match ceptreFVar "\<[A-Z_]\k*\>"  
syn keyword ceptreSymbol -> <- -o o- *
syn match ceptreDecl "^\s*[^()A-Z_]\k*\s*:" contains=ceptrePunct


syn match ceptreCurly "{\|}" contained
syn match ceptreSquare "\[\|\]" contained
syn match ceptreBindDecl "[^A-Z_{\[]\k*\s*:" contains=ceptrePunct contained
syn region ceptrePiBind start="{" end="}" keepend transparent contains=ceptreCurly,ceptrePunct,ceptreFVar,ceptreSymbol,ceptreType,ceptreBindDecl,ceptreComment
syn region ceptreLamBind start="\[" end="\]" keepend transparent contains=ceptreSquare,ceptrePunct,ceptreFVar,ceptreSymbol,ceptreType,ceptreBindDecl,ceptreComment

syn match ceptreParen "(\|)" contained
syn region ceptreParens start="(" end=")" transparent contains=ALL


" Comments hilighting 
"  single line, empty line comments
syn region ceptreComment  start="%" end="$"
"  delimited comments, needs to contain itself to properly hilight nested
"  comments 
syn region ceptreDelimitedComment  start="%{" end="}%" contains=ceptreDelimitedComment 
setlocal commentstring=\%%s

" Assign coloration
hi link ceptreType              Keyword
hi link ceptrePercentKey        Keyword
hi link ceptreComment           Comment
hi link ceptreDelimitedComment  Comment
hi link ceptreSymbol            Operator
hi link ceptreDecl              Identifier
hi link ceptreBindDecl          ceptreDeclarationFace
hi link ceptreFVar              Identifier

" Indentation
setlocal foldmethod=syntax
setlocal foldminlines=3
" Set the current syntax name
let b:current_syntax = "ceptre"
