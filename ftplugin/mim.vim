" Vim filetype plugin
" Language:    Mim
" Maintainer:  https://github.com/mimir/vim-mim

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Allow "\" inside keywords so the digraph-style abbreviations below (\to,
" \lm, ...) are entered and undone as a single unit.
setlocal iskeyword+=\\

" '//' and '///' line comments, '/* ... */' block comments; cf. langref.md.
setlocal comments=s1:/*,mb:*,ex:*/,:///,://
setlocal commentstring=//\ %s

" Mim source is full of mathematical/Unicode symbols; spell-checking it
" produces mostly noise.
setlocal nospell

" Digraph-style input for tokens that only exist as Unicode primary
" terminals in the surface syntax, cf. langref.md#terminals.
"
" Neovim expands these itself (see lua/mim/abbrev.lua) - ":iabbrev" cannot
" express "\<" and "\>" properly - and says so by setting
" g:loaded_mim_abbrev.  What follows is the plain-Vim path, and the fallback
" for an older Neovim or one where "vim.g.mim_abbrev = false" turned the Lua
" expansion off.
let b:undo_ftplugin = "setlocal iskeyword< comments< commentstring< spell<"

if !exists("g:loaded_mim_abbrev")
  iabbrev <buffer> \to    →
  iabbrev <buffer> \gets  ←
  iabbrev <buffer> \top   ⊤
  iabbrev <buffer> \bot   ⊥
  iabbrev <buffer> \box   □
  iabbrev <buffer> \cup   ∪
  iabbrev <buffer> ->     →
  iabbrev <buffer> <-     ←
  iabbrev <buffer> \lm    λ
  iabbrev <buffer> \<     ‹
  iabbrev <buffer> \>     ›
  iabbrev <buffer> \ll    «
  iabbrev <buffer> \gg    »

  let b:undo_ftplugin .= "| iunabbrev <buffer> \\to"
        \ . "| iunabbrev <buffer> \\gets"
        \ . "| iunabbrev <buffer> \\top"
        \ . "| iunabbrev <buffer> \\bot"
        \ . "| iunabbrev <buffer> \\box"
        \ . "| iunabbrev <buffer> \\cup"
        \ . "| iunabbrev <buffer> ->"
        \ . "| iunabbrev <buffer> <-"
        \ . "| iunabbrev <buffer> \\lm"
        \ . "| iunabbrev <buffer> \\<"
        \ . "| iunabbrev <buffer> \\>"
        \ . "| iunabbrev <buffer> \\ll"
        \ . "| iunabbrev <buffer> \\gg"
endif

let &cpo = s:cpo_save
unlet s:cpo_save
