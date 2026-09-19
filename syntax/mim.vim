" Vim syntax file
" Language:    Mim
" Maintainer:  https://github.com/AnyDSL/vim-mim
" Based on:    docs/langref.md in https://github.com/AnyDSL/mimir

if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn case match

" Keywords {{{1
" Declaration/expression keywords, cf. langref.md#terminals ("Keywords").
syn keyword mimKeyword and anx as axm cn con end extern fn fun import inj
syn keyword mimKeyword lam let match mod norm plugin priv pub
syn keyword mimKeyword rec ret rule use when where with
" secondary spelling of the "λ" expression keyword
syn keyword mimKeyword lm
syn match   mimKeyword "λ"

" Builtin types / kinds, cf. langref.md#terminals ("Keywords").
syn keyword mimType Bool Cn Fn I1 I8 I16 I32 I64 Idx Nat Rule Type Univ
" "*" abbreviates "Type (0:Univ)", "□" abbreviates "Type (1:Univ)"; "★" is an
" alternative spelling of "*"
syn match   mimType "[*□]"
syn match   mimType "★"

" Predefined boolean aliases: tt = 1₂, ff = 0₂
syn keyword mimBoolean tt ff

" Predefined Nat aliases for the "iN" keywords, and the ⊥/⊤ literals
syn keyword mimConstant i1 i8 i16 i32 i64
syn keyword mimConstant bot top
syn match   mimConstant "⊥"
syn match   mimConstant "⊤"

" "return" is an ordinary identifier, not a keyword, cf. langref.md#decl -
" but it is the conventional name for the implicit return continuation of a
" "fun"/"cn" declaration, e.g. "fun f(x: Nat): Nat = return x;".
syn keyword mimSpecial return

" Literals {{{1
" Every pattern below is anchored with `\%(\w\)\@1<!`: a leading digit only
" starts a fresh literal if it does not continue a preceding identifier, e.g.
" the "3" in "arg3" or the "85" in "v_85" must stay part of that identifier
" instead of turning into a number.
" A literal token never carries a sign: the "-" of "-23" is the signed literal
" *expression*, and everywhere else "+"/"-" are infix operators - "x-1" is a
" subtraction. So the sign is left to mimOperator; cf. langref.md#lit.

" L ::= dec+
syn match mimNumber "\%(\w\)\@1<!\d\+"
" L ::= "0" ["bB"] bin+
syn match mimNumber "\%(\w\)\@1<!0[bB][01]\+"
" L ::= "0" ["oO"] oct+
syn match mimNumber "\%(\w\)\@1<!0[oO][0-7]\+"
" L ::= "0" ["xX"] hex+
syn match mimNumber "\%(\w\)\@1<!0[xX]\x\+"

" L ::= dec+ eE sign? dec+
"    |  dec+ "." dec* (eE sign? dec+)?
"    |  dec* "." dec+ (eE sign? dec+)?
syn match mimFloat "\%(\w\)\@1<!\d\+[eE][+-]\=\d\+"
syn match mimFloat "\%(\w\)\@1<!\d\+\.\d*\([eE][+-]\=\d\+\)\="
syn match mimFloat "\%(\w\)\@1<!\d*\.\d\+\([eE][+-]\=\d\+\)\="

" L ::= "0" ["xX"] hex+ pP sign? dec+
"    |  "0" ["xX"] hex+ "." hex* pP sign? dec+
"    |  "0" ["xX"] hex* "." hex+ pP sign? dec+
syn match mimFloat "\%(\w\)\@1<!0[xX]\x\+[pP][+-]\=\d\+"
syn match mimFloat "\%(\w\)\@1<!0[xX]\x\+\.\x*[pP][+-]\=\d\+"
syn match mimFloat "\%(\w\)\@1<!0[xX]\x*\.\x\+[pP][+-]\=\d\+"

" X_n ::= dec+ sub+ | dec+ "_" dec+ | dec+ ["iI"] dec+
" An index literal of type "Idx n"; the third form spells a bit width instead
" of "n" itself, so "23I32" is "23:I32".  The hex/oct/bin spellings are not in
" the grammar, but the printer/normalizer emits them, e.g. "0x1Fi16".
syn match mimIndex "\%(\w\)\@1<!\d\+[₀-₉]\+"
syn match mimIndex "\%(\w\)\@1<!\d\+_\d\+"
syn match mimIndex "\%(\w\)\@1<!\%(0[bB][01]\+\|0[oO][0-7]\+\|0[xX]\x\+\|\d\+\)[iI]\d\+"

" esc ::= \' \\ \" \0 \a \b \f \n \r \t \v
syn match mimEscape "\\['\"0abfnrtv\\]" contained

" C ::= "'" (ascii_char | esc) "'"
" "ascii_char" is any ASCII character except "\", so "'" is a payload character
" too; a non-ASCII payload character is an error and is left unmatched.
syn match mimChar "'\%(\\['\"0abfnrtv\\]\|[\x20-\x5b\x5d-\x7e]\)'" contains=mimEscape

" S ::= '"' (ascii_string_char | esc)* '"'
syn region mimString start=+"+ skip=+\\.+ end=+"+ contains=mimEscape oneline

" Comments {{{1
" "/* ... */" comments are not nested.
syn region  mimComment    start="/\*" end="\*/" contains=mimTodo
syn match   mimComment    "//.*$" contains=mimTodo
syn keyword mimTodo TODO FIXME XXX NOTE contained

" "/// ..." comments are forwarded to the generated Markdown output, so
" highlight their payload as Markdown; cf. langref.md#comments. This is a
" line-by-line approximation - Markdown block constructs spanning multiple
" "///" lines (fenced code, multi-line lists, ...) will not be recognized as
" such, only their per-line inline markup will.
syn include @mimMarkdown syntax/markdown.vim
unlet! b:current_syntax

syn match   mimCommentDocMark "///" contained
syn region  mimCommentDoc start="///" end="$" keepend
      \ contains=mimCommentDocMark,mimTodo,@mimMarkdown

" Punctuation {{{1
" ( ) [ ] { } ⦃ ⦄ ‹ › « »; cf. langref.md#terminals.
" Note that neither "<" ">" "<<" ">>" nor "⟨" "⟩" "⟪" "⟫" are spellings of
" "‹" "›" "«" "»" (any more): the former are the relational and shift infix
" operators below, the latter are not tokens at all.
syn match mimDelimiter "[()\[\]{}]"
syn match mimDelimiter "[⦃⦄‹›«»]"
syn match mimDelimiter "[,;.]"

" The remaining primary terminals, cf. langref.md#terminals:
"   → ← => = @ $ # | : ∪          ("⊥" "⊤" "*" "□" "λ" are handled further above)
"   + - / % == != < <= > >= << >>  (infix operators, cf. langref.md#infix)
" plus the ASCII secondary spellings "->" for "→" and "<-" for "←".
syn match mimOperator "[→←∪=@$#|:+%<>-]"
" Multi-character operators are listed after the single-character ones: items
" matching at the same position are resolved in favour of the one defined last
" (":h :syn-priority"), and Vim's "\|" picks the first matching branch rather
" than the longest, so "==" has to precede "=".
syn match mimOperator "=>\|==\|!=\|<=\|>=\|<<\|>>\|->\|<-"
" "/", but not the "//" of a line comment nor the "/*" of a block comment -
" those are matched by mimComment, which is defined *before* this item.
syn match mimOperator "/[/*]\@!"

" I ::= "`" op   with   op ::= "+" | "-" | "*" | "/" | "%"
"                              |  "==" | "!=" | "<" | "<=" | ">" | ">="
"                              |  "<<" | ">>"
" A backtick escapes an infix operator into an ordinary identifier, e.g. the
" "`+" in "let `+ = core.nat.add;"; cf. langref.md#terminals.
syn match mimOperatorName "`\%(==\|!=\|<[<=]\=\|>[>=]\=\|[-+*/%]\)"

" Highlighting {{{1
let b:current_syntax = "mim"

hi def link mimKeyword        Keyword
hi def link mimType           Type
hi def link mimBoolean        Boolean
hi def link mimConstant       Constant
hi def link mimSpecial        Special
hi def link mimNumber         Number
hi def link mimFloat          Float
hi def link mimIndex          Number
hi def link mimChar           Character
hi def link mimString         String
hi def link mimEscape         SpecialChar
hi def link mimComment        Comment
hi def link mimCommentDoc     SpecialComment
hi def link mimCommentDocMark SpecialComment
hi def link mimTodo           Todo
hi def link mimDelimiter      Delimiter
hi def link mimOperator       Operator
hi def link mimOperatorName   Identifier

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: fdm=marker
