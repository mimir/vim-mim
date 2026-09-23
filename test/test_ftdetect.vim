" ftdetect/mim.vim - "*.mim" is detected as the "mim" filetype.

function! s:Filetype(name) abort
  let l:file = fnamemodify(tempname(), ':h') . '/' . a:name
  execute 'edit!' fnameescape(l:file)
  let l:ft = &filetype
  bwipeout!
  return l:ft
endfunction

function! Test_ftdetect_new_file() abort
  call assert_equal('mim', s:Filetype('scratch.mim'))
endfunction

function! Test_ftdetect_existing_file() abort
  let l:file = tempname() . '.mim'
  call writefile(['let x = 42;'], l:file)
  execute 'edit!' fnameescape(l:file)
  call assert_equal('mim', &filetype)
  call assert_equal('mim', b:current_syntax)
  bwipeout!
  call delete(l:file)
endfunction

" The pattern is anchored at the end, so a longer extension is not Mim.  A
" "*.mim.orig" backup file on the other hand is: Vim strips the suffixes in
" g:ft_ignore_pat before it detects the filetype.
function! Test_ftdetect_other_extension() abort
  call assert_notequal('mim', s:Filetype('scratch.mimir'))
  call assert_notequal('mim', s:Filetype('scratch.mimsyn'))
endfunction
