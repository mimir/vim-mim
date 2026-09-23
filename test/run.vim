" Test runner.  Sources every test/test_*.vim file, calls the Test_* functions
" they define and reports one line per test; exits non-zero if any of them
" failed.  Runs in Vim (`vim -es`) as well as in Neovim (`nvim --headless`),
" see test/run.sh.
"
" A test reports failures through Vim's own assert_*() functions, which append
" to v:errors instead of aborting - so one test can report several problems.

" Report a line of output.  Vim's silent ex mode (-es), the only way to run it
" without a terminal, swallows :echo, so write to standard output directly;
" Neovim's --headless prints :echo just fine.
let s:stdout = has('unix') ? '/dev/stdout' : ''

function! s:Say(msg) abort
  if empty(s:stdout)
    echo a:msg
  else
    call writefile([a:msg], s:stdout, 'a')
  endif
endfunction

let s:dir = expand('<sfile>:p:h')

" Helpers for the test files {{{1

" Replace the current buffer by a scratch Mim buffer holding `lines`.
function! MimBuffer(lines) abort
  enew!
  setlocal buftype=nofile
  call setline(1, a:lines)
  set filetype=mim
endfunction

" The syntax items covering `text` in `line`, in the order in which they
" appear and without repetitions - so a token highlighted as a whole yields a
" single-item list, and one built from several items yields all of them:
"
"   MimSynOf('let x = 42;', '42')     == ['mimNumber']
"   MimSynOf('let c = ''\n'';', '''\n''') == ['mimChar', 'mimEscape', 'mimChar']
"
" An unhighlighted token yields [''].
function! MimSynOf(line, text) abort
  call MimBuffer([a:line])
  let l:byte = stridx(a:line, a:text)
  if l:byte < 0
    call assert_report(printf('%s does not occur in %s', a:text, a:line))
    return []
  endif
  let l:groups = []
  for l:col in range(l:byte + 1, l:byte + strlen(a:text))
    let l:name = synIDattr(synID(1, l:col, 1), 'name')
    if empty(l:groups) || l:groups[-1] !=# l:name
      call add(l:groups, l:name)
    endif
  endfor
  return l:groups
endfunction

" The group a syntax item is linked to, e.g. 'Keyword' for mimKeyword.  Read
" from ":highlight", the one spelling Vim and Neovim agree on.
function! MimSynLink(group) abort
  return matchstr(execute('highlight ' . a:group), 'links to \zs\w\+')
endfunction

" Type `keys` into a fresh Mim buffer in insert mode and return the result.
" The keys are fed as if typed, so insert-mode abbreviations expand.
function! MimType(keys) abort
  call MimBuffer([''])
  call feedkeys('i' . a:keys, 'xt')
  return join(getline(1, '$'), "\n")
endfunction

" Runner {{{1

for s:file in sort(glob(s:dir . '/test_*.vim', 0, 1))
  execute 'source' fnameescape(s:file)
endfor

redir => s:listing
silent function /^Test_
redir END

let s:tests = filter(map(split(s:listing, "\n"),
      \ 'matchstr(v:val, ''^function \zs\w\+'')'), '!empty(v:val)')
call sort(s:tests)

let s:failed = 0
for s:test in s:tests
  let v:errors = []
  try
    execute 'call' s:test . '()'
  catch
    call add(v:errors, printf('%s at %s', v:exception, v:throwpoint))
  endtry

  if empty(v:errors)
    call s:Say('ok   ' . s:test)
  else
    let s:failed += 1
    call s:Say('FAIL ' . s:test)
    for s:error in v:errors
      call s:Say('       ' . s:error)
    endfor
  endif
endfor

call s:Say(printf('%s: %d tests, %d failed',
      \ has('nvim') ? 'neovim ' . matchstr(execute('version'), 'NVIM v\zs[^ \n]*')
      \             : 'vim ' . string(v:version / 100) . '.' . (v:version % 100),
      \ len(s:tests), s:failed))

if s:failed > 0
  cquit 1
endif
qall!

" vim: fdm=marker
