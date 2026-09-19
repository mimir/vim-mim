# vim-mim

Vim/Neovim support for [Mim](https://mimir.github.io/langref.html), the front-end language of
MimIR:

* filetype detection for `*.mim`;
* an ftplugin with the comment settings and digraph-style abbreviations for the Unicode terminals
  that have no ASCII spelling (`\to` → `→`, `\lm` → `λ`, `\<<` → `«`, ...);
* a regex syntax file.

On Neovim it additionally registers the [tree-sitter grammar](https://github.com/mimir/tree-sitter-mim)
with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (branch `main`), which does
not know about Mim yet.  Run `:TSInstall mim` once and you get tree-sitter highlighting, Markdown
injected into `///` doc comments, and folding.  Neovim empties `'syntax'` for a buffer while a
tree-sitter highlighter is running, so the syntax file above stays the fallback for a missing parser -
and plain Vim is unaffected either way.

Set `let g:mim_treesitter = v:false` (`vim.g.mim_treesitter = false` in Lua) to skip that
registration, e.g. to point nvim-treesitter at a local clone of the grammar yourself.

## Install

### vim-plug

```vim
Plug 'mimir/vim-mim'
```

### lazy.nvim

```lua
{ "mimir/vim-mim" }
```
