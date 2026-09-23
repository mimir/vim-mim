" The abbreviations for the Unicode terminals.  Two implementations: ":iabbrev"
" from ftplugin/mim.vim in Vim, and lua/mim/abbrev.lua in Neovim, which can do
" what Vim's abbreviations cannot.  What both have to do comes first.

let s:minimal = expand('<sfile>:p:h') . '/minimal.vim'

" The abbreviations that consist of keyword characters only expand the same
" way in both editors: type them, then anything that is not a keyword
" character.
function! Test_abbrev_expands_on_a_space() abort
  for [l:keys, l:want] in items({
        \ '\to ': '→ ', '\gets ': '← ', '\lm ': 'λ ', '\bot ': '⊥ ',
        \ '\top ': '⊤ ', '\box ': '□ ', '\cup ': '∪ ', '\ll ': '« ',
        \ '\gg ': '» '})
    call assert_equal(l:want, MimType(l:keys), 'typing ' . l:keys)
  endfor
endfunction

function! Test_abbrev_leaves_unknown_ones_alone() abort
  call assert_equal('\foo ', MimType('\foo '))
  call assert_equal('\ ', MimType('\ '))
endfunction

if has('nvim')

  " Neovim: lua/mim/abbrev.lua ------------------------------------------------

  function! Test_abbrev_nvim_is_in_charge() abort
    call MimBuffer([''])
    call assert_equal(1, g:loaded_mim_abbrev)
    call assert_true(exists('#mim_abbrev#FileType#mim'))
    " ... and the ftplugin left its own abbreviations alone
    call assert_equal('', maparg('\to', 'i', 1))
    call assert_equal('', maparg('->', 'i', 1))
  endfunction

  " Nothing has to be typed behind an abbreviation that can only mean one
  " thing: no other one starts with "\lm".
  function! Test_abbrev_nvim_expands_when_unambiguous() abort
    call assert_equal('λ', MimType('\lm'))
    call assert_equal('⊥', MimType('\bot'))
    call assert_equal('∪', MimType('\cup'))
  endfunction

  " "\to", on the other hand, could still become "\top", so it waits - were it
  " replaced as soon as it matched, "\top " would come out as "→p ".
  function! Test_abbrev_nvim_waits_while_ambiguous() abort
    call assert_equal('⊤ ', MimType('\top '))
    call assert_equal('→ ', MimType('\to '))
    call assert_equal('→;', MimType('\to;'))
  endfunction

  " Any character that cannot continue the abbreviation replaces it, and is
  " kept - which is what ":iabbrev" cannot do for "\<" and "\>".
  function! Test_abbrev_nvim_expands_on_any_other_character() abort
    call assert_equal('‹3', MimType('\<3'))
    call assert_equal('›;', MimType('\>;'))
    call assert_equal('»]', MimType('\gg]'))
    call assert_equal('→ x', MimType('\to x'))
  endfunction

  function! Test_abbrev_nvim_expands_on_leaving_insert_mode() abort
    call assert_equal('→', MimType("\\to\<Esc>"))
    call assert_equal('‹', MimType("\\<\<Esc>"))
  endfunction

  function! Test_abbrev_nvim_expands_when_the_cursor_leaves() abort
    call assert_equal("→\n", MimType("\\to\<CR>"))
    call assert_equal('→', MimType("\\to\<Left>"))
  endfunction

  " A second leader ends the abbreviation and opens the next one.
  function! Test_abbrev_nvim_expands_one_after_another() abort
    call assert_equal('→← ', MimType('\to\gets '))
    call assert_equal('λ‹', MimType("\\lm\\<\<Esc>"))
  endfunction

  " Typing the leader twice inserts it, and does not open an abbreviation.
  function! Test_abbrev_nvim_escaped_leader() abort
    call assert_equal('\', MimType('\\'))
    call assert_equal('\to ', MimType('\\to '))
  endfunction

  " Unlike Vim's abbreviations, the leader works anywhere in a line.
  function! Test_abbrev_nvim_works_inside_a_word() abort
    call assert_equal('xλ ', MimType('x\lm '))
    call assert_equal('f(‹3', MimType('f(\<3'))
  endfunction

  " What an abbreviation becomes, and where it leaves the cursor: the pairs are
  " typed around it.  Checked on expand() itself - feedkeys() cannot type on
  " after an expansion the way a typist does.
  function! s:Expand(text) abort
    return luaeval('{ require("mim.abbrev").expand(_A) }', a:text)
  endfunction

  function! Test_abbrev_nvim_pairs_wrap_the_cursor() abort
    " the byte after "‹" and after "«", i.e. between the brackets
    call assert_equal(['‹›', 3], s:Expand('\<>'))
    call assert_equal(['«»', 2], s:Expand('\llgg'))
    " the others leave the cursor where the typing left it
    call assert_equal(['λ'], s:Expand('\lm'))
    call assert_equal(['→← '], s:Expand('\to\gets '))
    call assert_equal(['\foo '], s:Expand('\foo '))
  endfunction

  " vim.g.mim_abbrev may also hold abbreviations of the user's own.
  function! Test_abbrev_nvim_extra_abbreviations() abort
    let g:mim_abbrev = {'qed': '∎'}
    try
      call assert_equal('∎ ', MimType('\qed '))
      call assert_equal('λ', MimType('\lm'))
    finally
      unlet g:mim_abbrev
    endtry
  endfunction

  " Once the buffer is no longer Mim, nothing is expanded in it any more.
  function! Test_abbrev_nvim_stops_with_the_filetype() abort
    call MimBuffer([''])
    set filetype=text
    call feedkeys('i\lm ', 'xt')
    call assert_equal('\lm ', getline(1))
  endfunction

  " The abbreviation is underlined while it is being typed.
  function! Test_abbrev_nvim_highlight() abort
    call assert_equal(v:true,
          \ luaeval('vim.api.nvim_get_hl(0, {name = "MimAbbrev"}).underline'))
  endfunction

  " vim.g.mim_abbrev = false hands the job back to Vim's abbreviations.
  " Checked in a child Neovim, because the plugin is loaded once per session.
  function! Test_abbrev_nvim_opt_out() abort
    let l:result = tempname()
    let l:report = 'call writefile([exists("g:loaded_mim_abbrev") . ":"'
          \ . ' . exists("#mim_abbrev") . ":" . maparg(''\to'', "i", 1)], '
          \ . string(l:result) . ')'

    call system([v:progpath, '--headless', '-n', '--clean',
          \ '--cmd', 'let g:mim_abbrev = v:false',
          \ '-u', s:minimal, '-c', 'new | set filetype=mim',
          \ '-c', l:report, '-c', 'qall!'])

    call assert_equal(0, v:shell_error)
    call assert_equal(['0:0:→'], readfile(l:result))
    call delete(l:result)
  endfunction

else

  " Vim: ":iabbrev" in ftplugin/mim.vim --------------------------------------

  function! Test_abbrev_vim_is_in_charge() abort
    call MimBuffer([''])
    call assert_false(exists('g:loaded_mim_abbrev'))
    for [l:lhs, l:rhs] in items({
          \ '\to': '→', '\gets': '←', '\lm': 'λ', '\bot': '⊥', '\top': '⊤',
          \ '\box': '□', '\cup': '∪', '\<': '‹', '\>': '›', '\ll': '«',
          \ '\gg': '»', '->': '→', '<-': '←'})
      call assert_equal(l:rhs, maparg(l:lhs, 'i', 1), 'abbreviation ' . l:lhs)
    endfor
  endfunction

  " They are buffer-local, and undone with the filetype.
  function! Test_abbrev_vim_are_local_to_the_buffer() abort
    call MimBuffer([''])
    new
    setlocal buftype=nofile
    call assert_equal('', maparg('\to', 'i', 1))
    call feedkeys("i\\to \<Esc>", 'xt')
    call assert_equal('\to ', getline(1))
    bwipeout!
  endfunction

  function! Test_abbrev_vim_are_undone_with_the_filetype() abort
    call MimBuffer([''])
    set filetype=text
    call assert_equal('', maparg('\to', 'i', 1))
    call assert_equal('', maparg('\gg', 'i', 1))
    call assert_equal('', maparg('->', 'i', 1))
  endfunction

  " "\lm" is a word, so it is only recognised as one.
  function! Test_abbrev_vim_not_inside_a_word() abort
    call assert_equal('x\lm ', MimType('x\lm '))
  endfunction

  " "\<", "\>", "->" and "<-" end in a non-keyword character ("non-id"
  " abbreviations, :h abbreviations).  Vim never expands those on the space
  " that ends them ...
  function! Test_abbrev_vim_non_id_not_on_a_space() abort
    call assert_equal('\< ', MimType('\< '))
    call assert_equal('\> ', MimType('\> '))
    call assert_equal('-> ', MimType('-> '))
    call assert_equal('<- ', MimType('<- '))
  endfunction

  " ... and which of <C-]>, <CR> and <Esc> does expand them differs between Vim
  " versions.  So do not pin down a version: insist that at least one of the
  " three works, and that no trigger produces anything but the character or
  " what was typed.
  function! Test_abbrev_vim_non_id_expands() abort
    for [l:lhs, l:rhs] in items({'\<': '‹', '\>': '›', '->': '→', '<-': '←'})
      let l:results = map(["\<C-]>", "\<CR>", "\<Esc>"],
            \ {_, trigger -> MimType(l:lhs . trigger)})

      for l:result in l:results
        call assert_true(l:result =~# '^' . l:rhs || l:result ==# l:lhs,
              \ printf('%s came out as %s', l:lhs, l:result))
      endfor
      call assert_notequal([], filter(copy(l:results), 'v:val =~# "^" . l:rhs'),
            \ l:lhs . ' expands on none of <C-]>, <CR>, <Esc>')
    endfor
  endfunction

  " Vim only expands them at the start of the line or after white space.
  function! Test_abbrev_vim_non_id_needs_white_space_in_front() abort
    call assert_equal('x->', MimType("x->\<C-]>"))
    call assert_equal('x\<', MimType("x\\<\<C-]>"))
  endfunction

endif
