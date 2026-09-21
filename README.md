# vim-mim

Vim and Neovim support for [Mim](https://mimir.github.io/langref.html), the front-end language of
MimIR:

- filetype detection for `*.mim`;
- an ftplugin with comment settings and abbreviations for the Unicode terminals;
- a regex syntax file - the highlighting in plain Vim, and the fallback in Neovim;
- on Neovim, registration of the [tree-sitter grammar](https://github.com/mimir/tree-sitter-mim)
  with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).

## Install

No setup call and nothing to configure: as soon as the plugin is on the 'runtimepath', `*.mim`
files are detected, highlighted, and get the abbreviations.

### lazy.nvim

```lua
{ "mimir/vim-mim" }
```

Load it eagerly - it is one `ftdetect` file plus two autocmds. With `ft = "mim"` the parser
registration only happens once a `*.mim` buffer is open, so `:TSInstall mim` from elsewhere would
not find the grammar.

### vim.pack (Neovim >= 0.12)

```lua
vim.pack.add({ "https://github.com/mimir/vim-mim" })
```

`:h vim.pack.update()` upgrades it later.

### mini.deps

```lua
MiniDeps.add("mimir/vim-mim")
```

### vim-plug

```vim
Plug 'mimir/vim-mim'
```

### Vundle

```vim
Plugin 'mimir/vim-mim'
```

### packer.nvim (unmaintained)

```lua
use "mimir/vim-mim"
```

### No plugin manager

Vim and Neovim load packages from the 'packpath' by themselves (`:h packages`), so a clone is all it
takes:

```sh
# Neovim
git clone https://github.com/mimir/vim-mim ~/.local/share/nvim/site/pack/mim/start/vim-mim
# Vim
git clone https://github.com/mimir/vim-mim ~/.vim/pack/mim/start/vim-mim
```

With pathogen, clone into `~/.vim/bundle` instead.

## Tree-sitter highlighting (Neovim)

Neovim does not ship a `mim` parser, so this plugin registers the grammar with `nvim-treesitter`.
One command installs it:

```vim
:TSInstall mim
```

That downloads [mimir/tree-sitter-mim](https://github.com/mimir/tree-sitter-mim), compiles the
parser, and installs its queries - after which `*.mim` buffers are highlighted from the parse tree,
`///` doc comments are highlighted as Markdown, and folding works. `:TSUpdate mim` picks up a newer
grammar later on.

Requirements: Neovim >= 0.11, `nvim-treesitter` on branch `main`, and a C compiler. The tree-sitter
CLI is _not_ needed - the generated parser is committed to the grammar repository.

Highlighting starts by itself; there is no `vim.treesitter.start()` to write. While it runs, Neovim
empties `'syntax'` for the buffer, so the two highlighters never fight: the syntax file below takes
over whenever the parser is missing, and `:lua vim.treesitter.stop()` brings it back by hand. Plain
Vim ignores all of this and uses the syntax file.

If you work on the grammar itself, register a local clone instead - your own registration always
wins, so nothing here has to be disabled for it, and `queries/` is then symlinked into Neovim's
parser directory so that editing a query takes effect right away:

```lua
vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    callback = function()
        require("nvim-treesitter.parsers").mim = {
            install_info = {
                path = vim.fn.expand("~/treesitter/tree-sitter-mim"),
                queries = "queries",
                generate = false,
                generate_from_json = false,
            },
        }
    end,
})
```

`vim.g.mim_treesitter = false` (`let g:mim_treesitter = v:false` in Vimscript) opts out of the
tree-sitter support altogether: no registration, no highlighter.

`:InspectTree` shows the parse tree of the current buffer, `:Inspect` the highlight groups under the
cursor, and `:checkhealth nvim-treesitter` whether the parser is installed.

## Typing the Unicode terminals

Mim spells several terminals with characters that are awkward to type, so the ftplugin defines
insert-mode abbreviations for them. Type the left column followed by a space or any non-keyword
character:

| Type          | Get   | Used for              |
| ------------- | ----- | --------------------- |
| `\to`, `->`   | `→`   | function type         |
| `\gets`, `<-` | `←`   | insert                |
| `\lm`         | `λ`   | lambda                |
| `\bot`        | `⊥`   | bottom                |
| `\top`        | `⊤`   | top                   |
| `\box`        | `□`   | `Type (1:Univ)`       |
| `\cup`        | `∪`   | union                 |
| `\<`, `\>`    | `‹ ›` | pack, singleton intro |
| `\ll`, `\gg`  | `« »` | array, singleton type |

`→ ← λ ⊥ ⊤` have ASCII spellings of their own (`-> <- lm bot top`) that Mim accepts just as well;
`∪ □ ‹ › « »` do not, so for those the abbreviations - or `:h digraphs` - are the way in.

`->` and `<-` consist entirely of non-keyword characters, which Vim only expands at the start of a
line or after whitespace (`:h abbreviations`); `x-> y` stays as typed. The `\...` spellings have no
such restriction.

The ftplugin adds `\` to `'iskeyword'` for the buffer so that `\to` and friends are recognised as
one word, and undoes that (along with everything else it sets) via `b:undo_ftplugin`.

## See also

- [mimir/tree-sitter-mim](https://github.com/mimir/tree-sitter-mim) - the tree-sitter grammar, which
  also documents the Helix and VS Code integrations.
- [Mim language reference](https://mimir.github.io/langref.html) - the surface syntax this plugin
  follows.

## License

MIT, see [LICENSE](LICENSE).
