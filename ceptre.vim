syn clear

" Just about anything in Ceptre is a keyword character
set iskeyword+=\",~,@,!,#-',*-45,47-57,59-90,94-122,\|,^:


colors default
" now, fix the defaults:
hi linenr cterm=NONE
hi Normal guifg=wheat guibg=grey10
hi StatusLine guibg=grey40 guifg=lavender gui=none
hi StatusLineNC guibg=grey25 guifg=black gui=none
hi SpecialKey guifg=grey27
hi NonText gui=none guifg=plum
hi IncSearch guibg=grey50 gui=none
hi Search guibg=cornflowerblue guifg=darkblue ctermfg=black ctermbg=3
hi ceptrePercentKeyFace term=NONE cterm=bold ctermfg=6 ctermbg=NONE gui=NONE guifg=#Aa88Ff guibg=NONE
hi ceptreTypeFace term=NONE cterm=NONE ctermfg=3 ctermbg=NONE gui=NONE guifg=#DdBbDd guibg=NONE
hi ceptreCommentFace term=NONE cterm=NONE ctermfg=6 ctermbg=NONE gui=NONE guifg=Grey50 guibg=NONE
hi ceptreSymbolFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=#DdBbDd guibg=NONE
hi visual guifg=NONE guibg=seagreen gui=none
hi ceptrePunctuationFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=#Dd77Dd guibg=NONE
hi ceptreDeclarationFace term=NONE cterm=bold ctermfg=7 ctermbg=NONE gui=NONE guifg=#DDF5AA guibg=NONE
hi ceptreFreeVariableFace term=NONE cterm=NONE ctermfg=5 ctermbg=NONE gui=NONE guifg=#99BbDd guibg=NONE
hi ceptreCurlyFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=#Dd6699 guibg=NONE
hi ceptreSquareFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=#Dd9966 guibg=NONE

syn keyword ceptrePercentKey #mode #interactive #trace #builtin

syn keyword ceptreType type pred bwd stage context
syn match ceptrePunct ":\|\.\|="
syn match ceptreFVar "\<[A-Z_]\k*\>"  
syn keyword ceptreSymbol -> <- -o o- *
syn match ceptreDecl "^\s*[^()A-Z_]\k*\s*:" contains=ceptrePunct


syn match ceptreCurly "{\|}" contained
syn match ceptreSquare "\[\|\]" contained
syn match ceptreBindDecl "[^A-Z_{\[]\k*\s*:" contains=ceptrePunct contained
syn region ceptrePiBind start="{" end="}" keepend transparent contains=ceptreCurly,ceptrePunct,ceptreFVar,ceptreSymbol,ceptreType,ceptreBindDecl
syn region ceptreLamBind start="\[" end="\]" keepend transparent contains=ceptreSquare,ceptrePunct,ceptreFVar,ceptreSymbol,ceptreType,ceptreBindDecl

syn match ceptreParen "(\|)" contained
syn region ceptreParens start="(" end=")" transparent contains=ALL


" Comments hilighting 
"  single line, empty line comments
syn match ceptreComment  "% .*\|%%.*\|%$"
"  delimited comments, needs to contain itself to properly hilight nested
"  comments 
syn region ceptreDelimitedComment  start="%{" end="}%" contains=ceptreDelimitedComment 

" Assign coloration
hi link ceptreType              ceptreTypeFace
hi link ceptrePercentKey        ceptrePercentKeyFace
hi link ceptreComment           ceptreCommentFace
hi link ceptreDelimitedComment  ceptreCommentFace
hi link ceptreSymbol            ceptreSymbolFace
hi link ceptrePunct             ceptrePunctuationFace
hi link ceptreParen             ceptreSymbolFace
hi link ceptreDecl              ceptreDeclarationFace
hi link ceptreBindDecl          ceptreDeclarationFace
hi link ceptreFVar              ceptreFreeVariableFace
hi link ceptreCurly             ceptreCurlyFace
hi link ceptreSquare            ceptreSquareFace

" Indentation

set foldmethod=syntax
set foldminlines=3
" Set the current syntax name
let b:current_syntax = "ceptre"
