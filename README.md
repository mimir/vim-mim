# vim-mim

[![vim](https://img.shields.io/github/actions/workflow/status/mimir/vim-mim/test-vim.yml?branch=main&label=vim&logo=vim&logoColor=white&style=flat-square)](https://github.com/mimir/vim-mim/actions/workflows/test-vim.yml)
[![neovim](https://img.shields.io/github/actions/workflow/status/mimir/vim-mim/test-neovim.yml?branch=main&label=neovim&logo=neovim&logoColor=white&style=flat-square)](https://github.com/mimir/vim-mim/actions/workflows/test-neovim.yml)

Vim and Neovim support for [Mim](https://mimir.github.io/langref.html), the front-end language of
MimIR:

- filetype detection for `*.mim`;
- an ftplugin with comment settings and abbreviations for the Unicode terminals;
- a regex syntax file - the highlighting in plain Vim, and the fallback in Neovim;
- on Neovim, registration of the [tree-sitter grammar](https://github.com/mimir/tree-sitter-mim)
  with [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).

## Vim and Neovim

Both editors are supported, and Neovim additionally gets what it can do better. That part is
written in Lua - `plugin/mim.lua` and `lua/mim/` - which Vim never reads, so neither editor pays
for the other:

|                         | Vim                     | Neovim                                      |
| ----------------------- | ----------------------- | ------------------------------------------- |
| filetype detection      | yes                     | yes                                         |
| comments, `'iskeyword'` | yes                     | yes                                         |
| highlighting            | regex syntax file       | tree-sitter, syntax file until `:TSInstall` |
| `///` doc comments      | Markdown, line by line  | Markdown from the parse tree                |
| folding                 | no                      | from the parse tree                         |
| number literals         | one colour each         | prefix, size and exponent emphasised        |
| abbreviations           | `:iabbrev`, Vim's rules | an input layer of its own                   |

The Neovim half needs 0.11 for the tree-sitter support and 0.10 for the abbreviations. An older
Neovim - or `vim.g.mim_treesitter = false` and `vim.g.mim_abbrev = false` - falls back to the Vim
column, which is the plugin's floor: the syntax file and the abbreviations of the ftplugin always
work, in both editors, with nothing installed and nothing configured.

[Tree-sitter highlighting](#tree-sitter-highlighting-neovim) and [Typing the Unicode
terminals](#typing-the-unicode-terminals) below say what each of the two does.

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

Mim spells several terminals with characters that are awkward to type, so the plugin expands
abbreviations for them while you type:

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

### Neovim

Neovim expands them itself, in `lua/mim/abbrev.lua`, the way Lean's editor integrations do: `\`
opens an abbreviation, which is underlined (`MimAbbrev`) until it is replaced. That happens as soon
as what you have typed can only mean one thing - `\lm` is `λ` with nothing typed behind it - or as
soon as you type a character that cannot continue it, which is then kept: `\<3` gives `‹3`, `\to `
gives `→ `. Leaving insert mode or moving the cursor away expands what is there as well, and
`\to\gets` expands both. Nothing is mapped, so `<Tab>` and `<CR>` keep doing whatever your
completion plugin does with them.

Two things `:iabbrev` cannot do:

- `\<>` and `\llgg` type both halves of a pair around the cursor - `‹|›` and `«|»`;
- `\\` inserts a literal backslash.

`vim.g.mim_abbrev = { qed = "∎" }` adds abbreviations of your own. `vim.g.mim_abbrev = false` turns
the expansion off and leaves Vim's abbreviations below in charge, which is also what an older
Neovim (< 0.10) gets. `->` and `<-` are not abbreviations here; Mim accepts them as they are.

### Vim

The ftplugin defines the same abbreviations with `:iabbrev`, which comes with Vim's own rules for
them (`:h abbreviations`):

- `\to`, `\gets`, `\lm`, `\bot`, `\top`, `\box`, `\cup`, `\ll` and `\gg` are made of keyword
  characters and expand as soon as a space - or any other non-keyword character - follows, but only
  at the start of a word: `x\lm` stays as typed.
- `\<`, `\>`, `->` and `<-` end in a non-keyword character. Vim recognises those only at the start
  of a line or after whitespace, and *not* on the space that follows them: `<C-]>` expands one, as
  do `<CR>` and `<Esc>` in recent Vim versions.

The ftplugin adds `\` to `'iskeyword'` for the buffer so that `\to` and friends are recognised as
one word, and undoes that (along with everything else it sets) via `b:undo_ftplugin`.

## See also

- [mimir/tree-sitter-mim](https://github.com/mimir/tree-sitter-mim) - the tree-sitter grammar, which
  also documents the Helix and VS Code integrations.
- [Mim language reference](https://mimir.github.io/langref.html) - the surface syntax this plugin
  follows.

## Tests

`test/run.sh` runs the test suite - in Vim, in Neovim, or in both if both are installed:

```sh
test/run.sh        # both
test/run.sh nvim   # only Neovim
```

The tests live in `test/test_*.vim`, one file per part of the plugin, and are plain Vim script
using Vim's own `assert_*()` functions, so the same files run in both editors; `test/run.vim` is
the runner and holds the helpers the tests share. GitHub Actions runs all of it against the current
and the nightly Vim and Neovim, plus the oldest supported Neovim.

## License

MIT, see [LICENSE](LICENSE).
