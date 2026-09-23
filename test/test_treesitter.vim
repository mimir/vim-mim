" plugin/mim.lua - the Neovim side: registering the tree-sitter grammar with
" nvim-treesitter, starting the highlighter and the number-literal emphasis.

if !has('nvim')
  " Vim does not read plugin/*.lua at all, so none of this may leak into it.
  function! Test_vim_ignores_the_lua_plugin() abort
    call assert_false(exists('g:loaded_mim_treesitter'))
    call assert_false(exists('#mim_treesitter'))
  endfunction
  finish
endif

let s:minimal = expand('<sfile>:p:h') . '/minimal.vim'

function! Test_treesitter_plugin_loaded() abort
  call assert_equal(1, g:loaded_mim_treesitter)
  call assert_true(exists('#mim_treesitter#User#TSUpdate'))
  call assert_true(exists('#mim_treesitter#FileType#mim'))
  call assert_true(exists('#mim_treesitter#ColorScheme'))
endfunction

" nvim-treesitter asks for third-party parsers on its "TSUpdate" event.
function! Test_treesitter_registers_the_parser() abort
  lua package.loaded['nvim-treesitter.parsers'] = {}
  doautocmd User TSUpdate

  call assert_equal('https://github.com/mimir/tree-sitter-mim',
        \ luaeval('vim.tbl_get(package.loaded["nvim-treesitter.parsers"],'
        \       . ' "mim", "install_info", "url")'))
  call assert_equal('queries',
        \ luaeval('vim.tbl_get(package.loaded["nvim-treesitter.parsers"],'
        \       . ' "mim", "install_info", "queries")'))
endfunction

" A registration from the user's own config - e.g. a local checkout of the
" grammar, as documented in the README - always wins.
function! Test_treesitter_keeps_an_existing_registration() abort
  lua package.loaded['nvim-treesitter.parsers'] =
        \ { mim = { install_info = { path = '/somewhere/tree-sitter-mim' } } }
  doautocmd User TSUpdate

  call assert_equal('/somewhere/tree-sitter-mim',
        \ luaeval('vim.tbl_get(package.loaded["nvim-treesitter.parsers"],'
        \       . ' "mim", "install_info", "path")'))
  call assert_equal(v:null,
        \ luaeval('vim.tbl_get(package.loaded["nvim-treesitter.parsers"],'
        \       . ' "mim", "install_info", "url")'))
endfunction

" Without nvim-treesitter the event must pass without an error.
function! Test_treesitter_without_nvim_treesitter() abort
  lua package.loaded['nvim-treesitter.parsers'] = nil
  doautocmd User TSUpdate
  call assert_equal(v:null, luaeval('package.loaded["nvim-treesitter.parsers"]'))
endfunction

" Opening a Mim buffer must not fail while the parser is missing - then the
" regex syntax file keeps highlighting it - and must hand over to tree-sitter
" once it is there.  Which of the two happens depends on the machine: CI has
" no parser, a Mim developer's Neovim has.
function! Test_treesitter_start() abort
  call MimBuffer(['let x = 42;'])
  " the highlighter is started from vim.schedule()
  sleep 50m

  if luaeval('vim.b.ts_highlight == true')
    " the highlighter empties 'syntax' for the buffer, so that the two never
    " fight over it
    call assert_equal('', &syntax)
  else
    call assert_equal('mim', b:current_syntax)
    call assert_equal('mim', &syntax)
    call assert_equal('mimNumber', synIDattr(synID(1, 9, 1), 'name'))
  endif
endfunction

" The pieces of a number literal are marked with an attribute only: no
" foreground, so the marker keeps the colour of the literal around it.
function! Test_treesitter_number_emphasis() abort
  for l:group in ['@number.prefix', '@number.suffix',
        \ '@number.float.prefix', '@number.float.exponent']
    call assert_equal(v:true, luaeval('vim.api.nvim_get_hl(0, {name = _A}).bold',
          \ l:group), l:group)
    call assert_equal(v:null, luaeval('vim.api.nvim_get_hl(0, {name = _A}).fg',
          \ l:group), l:group)
  endfor
endfunction

" ":colorscheme" clears the groups, hence the ColorScheme autocmd.
function! Test_treesitter_number_emphasis_survives_a_colorscheme() abort
  highlight clear @number.prefix
  call assert_equal(v:null,
        \ luaeval('vim.api.nvim_get_hl(0, {name = "@number.prefix"}).bold'))

  doautocmd ColorScheme
  call assert_equal(v:true,
        \ luaeval('vim.api.nvim_get_hl(0, {name = "@number.prefix"}).bold'))
endfunction

" The groups are defaults ("hi default"), so the user's own definition wins
" and is not overwritten when the groups are re-applied.
function! Test_treesitter_user_highlight_wins() abort
  highlight @number.suffix guifg=#ff0000
  doautocmd ColorScheme
  call assert_equal(0xff0000,
        \ luaeval('vim.api.nvim_get_hl(0, {name = "@number.suffix"}).fg'))

  highlight clear @number.suffix
  doautocmd ColorScheme
endfunction

" vim.g.mim_treesitter = false opts out of all of it.  Checked in a child
" Neovim, because the plugin is loaded once per session.
function! Test_treesitter_opt_out() abort
  let l:result = tempname()
  let l:report = printf('call writefile([exists("g:loaded_mim_treesitter") . ":"'
        \ . ' . exists("#mim_treesitter")], %s)', string(l:result))

  call system([v:progpath, '--headless', '-n', '--clean',
        \ '--cmd', 'let g:mim_treesitter = v:false',
        \ '-u', s:minimal, '-c', l:report, '-c', 'qall!'])

  call assert_equal(0, v:shell_error)
  call assert_equal(['0:0'], readfile(l:result))
  call delete(l:result)
endfunction
