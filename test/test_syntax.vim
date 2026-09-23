" syntax/mim.vim - the regex syntax file: the highlighting in plain Vim and
" the fallback in Neovim.  Every test states a whole line of Mim and the token
" in it whose syntax items are checked, cf. MimSynOf() in test/run.vim.

function! Test_syntax_is_mim() abort
  call MimBuffer(['let x = 42;'])
  call assert_equal('mim', b:current_syntax)
endfunction

function! Test_syntax_keywords() abort
  call assert_equal(['mimKeyword'], MimSynOf('let f = lam x: Nat;', 'lam'))
  call assert_equal(['mimKeyword'], MimSynOf('axm %core.nat;', 'axm'))
  call assert_equal(['mimKeyword'], MimSynOf('fun f() = ();', 'fun'))
  " "λ" and its ASCII spelling "lm"
  call assert_equal(['mimKeyword'], MimSynOf('let f = λ x: Nat;', 'λ'))
  call assert_equal(['mimKeyword'], MimSynOf('let f = lm x: Nat;', 'lm'))
endfunction

function! Test_syntax_types() abort
  call assert_equal(['mimType'], MimSynOf('let n: Nat = 42;', 'Nat'))
  call assert_equal(['mimType'], MimSynOf('let b: Bool = tt;', 'Bool'))
  " "*" is "Type (0:Univ)", "□" is "Type (1:Univ)", "★" spells "*"
  call assert_equal(['mimType'], MimSynOf('let T: * = Nat;', '*'))
  call assert_equal(['mimType'], MimSynOf('let T: □ = Nat;', '□'))
  call assert_equal(['mimType'], MimSynOf('let T: ★ = Nat;', '★'))
endfunction

function! Test_syntax_constants() abort
  call assert_equal(['mimBoolean'], MimSynOf('let b = tt;', 'tt'))
  call assert_equal(['mimBoolean'], MimSynOf('let b = ff;', 'ff'))
  call assert_equal(['mimConstant'], MimSynOf('let n = i32;', 'i32'))
  call assert_equal(['mimConstant'], MimSynOf('let x = bot;', 'bot'))
  call assert_equal(['mimConstant'], MimSynOf('let x = ⊥;', '⊥'))
  call assert_equal(['mimConstant'], MimSynOf('let x = ⊤;', '⊤'))
  " "return" is an ordinary identifier, but conventionally the implicit return
  " continuation of a "fun"/"cn"
  call assert_equal(['mimSpecial'], MimSynOf('fun f(x: Nat) = return x;', 'return'))
endfunction

function! Test_syntax_integers() abort
  call assert_equal(['mimNumber'], MimSynOf('let x = 42;', '42'))
  call assert_equal(['mimNumber'], MimSynOf('let x = 0b1011;', '0b1011'))
  call assert_equal(['mimNumber'], MimSynOf('let x = 0o17;', '0o17'))
  call assert_equal(['mimNumber'], MimSynOf('let x = 0xFF;', '0xFF'))
endfunction

" A digit that continues an identifier is part of it, not a literal.
function! Test_syntax_digits_in_identifier() abort
  call assert_equal([''], MimSynOf('let arg3 = 1;', 'arg3'))
  call assert_equal([''], MimSynOf('let v_85 = 1;', 'v_85'))
endfunction

function! Test_syntax_floats() abort
  call assert_equal(['mimFloat'], MimSynOf('let x = 1.5;', '1.5'))
  call assert_equal(['mimFloat'], MimSynOf('let x = .5;', '.5'))
  call assert_equal(['mimFloat'], MimSynOf('let x = 3.;', '3.'))
  call assert_equal(['mimFloat'], MimSynOf('let x = 1e10;', '1e10'))
  call assert_equal(['mimFloat'], MimSynOf('let x = 2.5e-3;', '2.5e-3'))
  call assert_equal(['mimFloat'], MimSynOf('let x = 0x1.8p3;', '0x1.8p3'))
  call assert_equal(['mimFloat'], MimSynOf('let x = 0x1p-3;', '0x1p-3'))
endfunction

" "Idx n" literals: a subscript, an explicit "_n", or a bit width.
function! Test_syntax_index_literals() abort
  call assert_equal(['mimIndex'], MimSynOf('let i = 4₂;', '4₂'))
  call assert_equal(['mimIndex'], MimSynOf('let i = 4_2;', '4_2'))
  call assert_equal(['mimIndex'], MimSynOf('let i = 23I32;', '23I32'))
  " the printer also emits the hex/oct/bin spellings
  call assert_equal(['mimIndex'], MimSynOf('let i = 0x1Fi16;', '0x1Fi16'))
endfunction

" The sign of "-23" is an operator, not part of the literal, so that "x-1"
" stays a subtraction.
function! Test_syntax_sign_is_an_operator() abort
  call assert_equal(['mimOperator'], MimSynOf('let x = -23;', '-'))
  call assert_equal(['mimNumber'], MimSynOf('let x = -23;', '23'))
  call assert_equal(['mimOperator'], MimSynOf('let x = y-1;', '-'))
endfunction

function! Test_syntax_char() abort
  call assert_equal(['mimChar'], MimSynOf('let c = ''a'';', '''a'''))
  call assert_equal(['mimChar', 'mimEscape', 'mimChar'],
        \ MimSynOf('let c = ''\n'';', '''\n'''))
  " "'" itself is a payload character
  call assert_equal(['mimChar'], MimSynOf("let c = ''';", "'''"))
endfunction

function! Test_syntax_string() abort
  call assert_equal(['mimString'], MimSynOf('let s = "abc";', '"abc"'))
  call assert_equal(['mimString', 'mimEscape', 'mimString'],
        \ MimSynOf('let s = "a\tb";', '"a\tb"'))
endfunction

function! Test_syntax_comments() abort
  call assert_equal(['mimComment'], MimSynOf('let x = 1; // trailing', '// trailing'))
  call assert_equal(['mimComment'], MimSynOf('/* block */ let x = 1;', '/* block */'))
  call assert_equal(['mimTodo'], MimSynOf('// TODO: fix', 'TODO'))
  call assert_equal(['mimTodo'], MimSynOf('/* FIXME */', 'FIXME'))
  " a "/" inside a comment is not the division operator
  call assert_equal(['mimComment'], MimSynOf('// a/b', 'a/b'))
endfunction

function! Test_syntax_block_comment_spans_lines() abort
  call MimBuffer(['/* a', ' * b', ' */ let x = 1;'])
  call assert_equal('mimComment', synIDattr(synID(2, 2, 1), 'name'))
  call assert_equal('mimComment', synIDattr(synID(3, 2, 1), 'name'))
  call assert_equal('mimKeyword', synIDattr(synID(3, 5, 1), 'name'))
endfunction

" "/// ..." is forwarded to the generated Markdown, so its payload is
" highlighted as Markdown.
function! Test_syntax_doc_comment() abort
  call assert_equal(['mimCommentDocMark'], MimSynOf('/// **bold** text', '///'))
  call assert_match('^markdown', MimSynOf('/// **bold** text', '**')[0])
  call assert_equal(['mimTodo'], MimSynOf('/// TODO: document', 'TODO'))
  " the Markdown syntax file must not leave "b:current_syntax" behind
  call MimBuffer(['/// doc'])
  call assert_equal('mim', b:current_syntax)
endfunction

function! Test_syntax_delimiters() abort
  call assert_equal(['mimDelimiter'], MimSynOf('let x = f(y);', '('))
  call assert_equal(['mimDelimiter'], MimSynOf('let x = ‹3; y›;', '‹'))
  call assert_equal(['mimDelimiter'], MimSynOf('let x = «3; Nat»;', '«'))
  call assert_equal(['mimDelimiter'], MimSynOf('let x = 1;', ';'))
  call assert_equal(['mimDelimiter'], MimSynOf('let x = f(a, b);', ','))
  call assert_equal(['mimDelimiter'], MimSynOf('let x = %core.nat.add;', '.'))
  " but the "." of a literal is part of it, not a delimiter
  call assert_equal(['mimFloat'], MimSynOf('let x = .5;', '.5'))
  call assert_equal(['mimFloat'], MimSynOf('let x = 1.5;', '.'))
endfunction

function! Test_syntax_operators() abort
  call assert_equal(['mimOperator'], MimSynOf('let f: Nat → Nat = id;', '→'))
  call assert_equal(['mimOperator'], MimSynOf('let f: Nat -> Nat = id;', '->'))
  call assert_equal(['mimOperator'], MimSynOf('let x = a ← b;', '←'))
  call assert_equal(['mimOperator'], MimSynOf('let x = a <- b;', '<-'))
  call assert_equal(['mimOperator'], MimSynOf('let x = a ∪ b;', '∪'))
  call assert_equal(['mimOperator'], MimSynOf('let x = a / b;', '/'))
  call assert_equal(['mimOperator'], MimSynOf('let x = a % b;', '%'))
endfunction

" Multi-character operators win over their prefixes.
function! Test_syntax_multichar_operators() abort
  for l:op in ['==', '!=', '<=', '>=', '<<', '>>', '=>']
    call assert_equal(['mimOperator'], MimSynOf('let x = a ' . l:op . ' b;', l:op),
          \ 'operator ' . l:op)
  endfor
endfunction

" A backtick turns an infix operator into an ordinary identifier.
function! Test_syntax_operator_name() abort
  call assert_equal(['mimOperatorName'], MimSynOf('let `+ = %core.nat.add;', '`+'))
  call assert_equal(['mimOperatorName'], MimSynOf('let `<= = le;', '`<='))
  call assert_equal(['mimOperatorName'], MimSynOf('let `>> = shr;', '`>>'))
endfunction

" The items are linked to the standard groups a colour scheme defines.
function! Test_syntax_highlight_links() abort
  call MimBuffer(['let x = 42;'])
  for [l:item, l:group] in items({
        \ 'mimKeyword': 'Keyword', 'mimType': 'Type', 'mimBoolean': 'Boolean',
        \ 'mimConstant': 'Constant', 'mimSpecial': 'Special',
        \ 'mimNumber': 'Number', 'mimFloat': 'Float', 'mimIndex': 'Number',
        \ 'mimChar': 'Character', 'mimString': 'String',
        \ 'mimEscape': 'SpecialChar', 'mimComment': 'Comment',
        \ 'mimCommentDoc': 'SpecialComment',
        \ 'mimCommentDocMark': 'SpecialComment', 'mimTodo': 'Todo',
        \ 'mimDelimiter': 'Delimiter', 'mimOperator': 'Operator',
        \ 'mimOperatorName': 'Identifier'})
    call assert_equal(l:group, MimSynLink(l:item), l:item)
  endfor
endfunction
