" Startup file for the test suite: puts *this* checkout on the 'runtimepath'
" and nothing else, so that a plugin installed in the user's own configuration
" cannot influence the result.  Used by test/run.sh for both Vim and Neovim.

set nocompatible
set noswapfile nobackup nowritebackup
set noshowcmd noruler
set encoding=utf-8

let s:root = expand('<sfile>:p:h:h')
execute 'set runtimepath^=' . fnameescape(s:root)

filetype plugin on
syntax enable
