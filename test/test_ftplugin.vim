" ftplugin/mim.vim - the buffer-local options.  The abbreviations it defines
" for Vim are in test/test_abbrev.vim, next to Neovim's own expansion.

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

" Vim's abbreviations are typed with a leading "\", which only works as long
" as "\" counts as part of the word.
function! Test_ftplugin_iskeyword() abort
  call MimBuffer([''])
  call assert_match('\\', &iskeyword)
endfunction

" b:undo_ftplugin has to undo *everything* the ftplugin did, or the settings
" leak into the next filetype of the buffer.
function! Test_ftplugin_undo() abort
  call MimBuffer([''])
  set filetype=text

  call assert_notmatch('\\', &iskeyword)
  call assert_notequal('// %s', &commentstring)
  call assert_notequal('s1:/*,mb:*,ex:*/,:///,://', &comments)
endfunction
