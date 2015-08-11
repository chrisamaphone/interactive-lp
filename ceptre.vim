syn clear

" Just about anything in Twelf is a keyword character
set iskeyword+=\",~,@,!,#-',*-45,47-57,59-90,94-122,\|,^:


" hacked to make it work for me -wjl
"if &background == "dark"
  colors default
  " now, fix the defaults:
  hi linenr cterm=NONE
  hi Normal guifg=wheat guibg=grey10
  hi StatusLine guibg=grey40 guifg=lavender gui=none
  hi StatusLineNC guibg=grey25 guifg=black gui=none
  " tabs shown by `set list'
  hi SpecialKey guifg=grey27
  " ~ at the end of the file
  hi NonText gui=none guifg=plum
  "hi NonText gui=none guifg=salmon
  "hi NonText gui=none guifg=hotpink
  "hi NonText gui=none guifg=royalblue
  "hi NonText gui=none guifg=deepskyblue
  hi IncSearch guibg=grey50 gui=none
  hi Search guibg=cornflowerblue guifg=darkblue ctermfg=black ctermbg=3
"else
  hi twelfPercentKeyFace term=NONE cterm=bold ctermfg=6 ctermbg=NONE gui=NONE guifg=#Aa88Ff guibg=NONE
  hi twelfTypeFace term=NONE cterm=NONE ctermfg=3 ctermbg=NONE gui=NONE guifg=#DdBbDd guibg=NONE
  hi twelfCommentFace term=NONE cterm=NONE ctermfg=6 ctermbg=NONE gui=NONE guifg=Grey50 guibg=NONE
  hi twelfSymbolFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=#DdBbDd guibg=NONE
  hi visual guifg=NONE guibg=seagreen gui=none
"  hi twelfPunctuationFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=Blue guibg=NONE
  "hi twelfPunctuationFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=dodgerBlue guibg=NONE
  hi twelfPunctuationFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=#Dd77Dd guibg=NONE
  hi twelfDeclarationFace term=NONE cterm=bold ctermfg=7 ctermbg=NONE gui=NONE guifg=#DDF5AA guibg=NONE
  hi twelfFreeVariableFace term=NONE cterm=NONE ctermfg=5 ctermbg=NONE gui=NONE guifg=#99BbDd guibg=NONE
  hi twelfCurlyFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=#Dd6699 guibg=NONE
  hi twelfSquareFace term=NONE cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=#Dd9966 guibg=NONE
"endif

syn keyword twelfPercentKey #mode #interactive #trace #builtin

syn keyword twelfType type pred bwd stage context
syn match twelfPunct ":\|\.\|="
syn match twelfFVar "\<[A-Z_]\k*\>"  
syn keyword twelfSymbol -> <- -o o- *
syn match twelfDecl "^\s*[^()A-Z_]\k*\s*:" contains=twelfPunct


syn match twelfCurly "{\|}" contained
syn match twelfSquare "\[\|\]" contained
syn match twelfBindDecl "[^A-Z_{\[]\k*\s*:" contains=twelfPunct contained
syn region twelfPiBind start="{" end="}" keepend transparent contains=twelfCurly,twelfPunct,twelfFVar,twelfSymbol,twelfType,twelfBindDecl
syn region twelfLamBind start="\[" end="\]" keepend transparent contains=twelfSquare,twelfPunct,twelfFVar,twelfSymbol,twelfType,twelfBindDecl

"syn region twelfCommand start="^" end="\." keepend transparent contains=ALL

syn match twelfParen "(\|)" contained
syn region twelfParens start="(" end=")" transparent contains=ALL


" Comments hilighting 
"  single line, empty line comments
syn match twelfComment  "% .*\|%%.*\|%$"
"  delimited comments, needs to contain itself to properly hilight nested
"  comments 
syn region twelfDelimitedComment  start="%{" end="}%" contains=twelfDelimitedComment 

" Assign coloration
hi link twelfType              twelfTypeFace
hi link twelfPercentKey        twelfPercentKeyFace
hi link twelfComment           twelfCommentFace
hi link twelfDelimitedComment  twelfCommentFace
hi link twelfSymbol            twelfSymbolFace
hi link twelfPunct             twelfPunctuationFace
hi link twelfParen             twelfSymbolFace
hi link twelfDecl              twelfDeclarationFace
hi link twelfBindDecl          twelfDeclarationFace
hi link twelfFVar              twelfFreeVariableFace
hi link twelfCurly             twelfCurlyFace
hi link twelfSquare            twelfSquareFace

" Indentation

" Folds
"syn region myFold start="%{" end="}%" transparent fold 
"syn sync fromstart

set foldmethod=syntax
set foldminlines=3
" Set the current syntax name
let b:current_syntax = "twelf"
