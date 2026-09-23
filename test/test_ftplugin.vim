" ftplugin/mim.vim - buffer-local options and the abbreviations for the
" Unicode terminals.

function! Test_ftplugin_loaded() abort
  call MimBuffer([''])
  call assert_equal(1, b:did_ftplugin)
endfunction

function! Test_ftplugin_comments() abort
  call MimBuffer([''])
  call assert_equal('// %s', &commentstring)
  " "///" must come before "//" so that a doc comment is continued as one
  call assert_equal('s1:/*,mb:*,ex:*/,:///,://', &comments)
  call assert_equal(0, &spell)
endfunction

" The abbreviations below are typed with a leading "\", which only works as
" long as "\" counts as part of the word.
function! Test_ftplugin_iskeyword() abort
  call MimBuffer([''])
  call assert_match('\\', &iskeyword)
endfunction

function! Test_ftplugin_abbreviations_defined() abort
  call MimBuffer([''])
  for [l:lhs, l:rhs] in items({
        \ '\to': '→', '\gets': '←', '\lm': 'λ', '\bot': '⊥', '\top': '⊤',
        \ '\box': '□', '\cup': '∪', '\<': '‹', '\>': '›', '\ll': '«',
        \ '\gg': '»', '->': '→', '<-': '←'})
    call assert_equal(l:rhs, maparg(l:lhs, 'i', 1), 'abbreviation ' . l:lhs)
  endfor
endfunction

" b:undo_ftplugin has to undo *everything* the ftplugin did, or the settings
" leak into the next filetype of the buffer.
function! Test_ftplugin_undo() abort
  call MimBuffer([''])
  set filetype=text

  call assert_notmatch('\\', &iskeyword)
  call assert_notequal('// %s', &commentstring)
  call assert_equal('', maparg('\to', 'i', 1))
  call assert_equal('', maparg('->', 'i', 1))
  call assert_equal('', maparg('\gg', 'i', 1))
endfunction

" The abbreviations are buffer-local: they must not fire in another filetype.
function! Test_ftplugin_abbreviations_are_local() abort
  call MimBuffer([''])
  new
  setlocal buftype=nofile
  call assert_equal('', maparg('\to', 'i', 1))
  call feedkeys("i\\to \<Esc>", 'xt')
  call assert_equal('\to ', getline(1))
  bwipeout!
endfunction

" A "full-id" abbreviation - every character is a keyword character, so it
" expands as soon as a non-keyword character follows.
function! Test_abbrev_backslash_expands_on_space() abort
  for [l:keys, l:want] in items({
        \ '\to ': '→ ', '\gets ': '← ', '\lm ': 'λ ', '\bot ': '⊥ ',
        \ '\top ': '⊤ ', '\box ': '□ ', '\cup ': '∪ ', '\ll ': '« ',
        \ '\gg ': '» '})
    call assert_equal(l:want, MimType(l:keys . "\<Esc>"), 'typing ' . l:keys)
  endfor
endfunction

" ... but not in the middle of a word: "x\lm" is one word, not an abbreviation.
function! Test_abbrev_backslash_not_inside_word() abort
  call assert_equal('x\lm ', MimType("x\\lm \<Esc>"))
endfunction

" "\<", "\>", "->" and "<-" end in a non-keyword character ("non-id"
" abbreviations, :h abbreviations).  Vim expands those only at the start of
" the insertion or after white space, and - unlike the "full-id" ones above -
" not when a non-keyword character is typed behind them, only on <Esc>, <CR>
" or <C-]>.
function! Test_abbrev_non_id_expands_on_esc() abort
  for [l:keys, l:want] in items({'\<': '‹', '\>': '›', '->': '→', '<-': '←'})
    call assert_equal(l:want, MimType(l:keys . "\<Esc>"), 'typing ' . l:keys)
    call assert_equal(l:want, MimType('x ' . l:keys . "\<Esc>")[2:],
          \ 'typing ' . l:keys . ' after a space')
  endfor
endfunction

function! Test_abbrev_non_id_not_after_keyword() abort
  call assert_equal('x->', MimType("x->\<Esc>"))
  call assert_equal('x\<', MimType("x\\<\<Esc>"))
endfunction
