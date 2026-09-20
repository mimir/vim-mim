-- Neovim: register the tree-sitter grammar for Mim
-- Maintainer:  https://github.com/mimir/vim-mim
--
-- nvim-treesitter (branch `main`) does not ship a `mim` parser yet, so point it at
-- https://github.com/mimir/tree-sitter-mim and let `:TSInstall mim` build it.  nvim-treesitter
-- `main` does not enable highlighting by itself either, so this also starts it per buffer.
-- `vim.treesitter.start()` sets 'syntax' to the empty string for the buffer, so the regex syntax
-- file in this plugin becomes the fallback for plain Vim and for a missing parser.
--
-- Set `vim.g.mim_treesitter = false` to skip all of this, e.g. to drive the grammar yourself.

if vim.g.loaded_mim_treesitter ~= nil or vim.g.mim_treesitter == false then
  return
end
vim.g.loaded_mim_treesitter = 1

-- nvim-treesitter `main` requires Neovim 0.11
if vim.fn.has("nvim-0.11") == 0 then
  return
end

vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  group = vim.api.nvim_create_augroup("mim_treesitter", { clear = true }),
  desc = "register the Mim parser with nvim-treesitter",
  callback = function()
    local ok, parsers = pcall(require, "nvim-treesitter.parsers")
    -- a registration from the user's own config always wins - e.g. a local checkout of the grammar
    if not ok or parsers.mim ~= nil then
      return
    end

    parsers.mim = {
      install_info = {
        url = "https://github.com/mimir/tree-sitter-mim",
        queries = "queries",
      },
    }
  end,
})

-- A number literal is highlighted in pieces: `0x`/`0b`/`0o`, the `i32`/`_2`/`₂` size of an `Idx`
-- literal and the `e10`/`p-3` exponent of a float each get a capture of their own, so that
-- `0x23I32` does not read as one undifferentiated run of characters.  Each group sets *no*
-- foreground: Neovim combines an extmark that leaves a colour unset with the one below it, so the
-- marker keeps the colour of the surrounding literal and only gains the attribute - which is what
-- keeps the literal looking like a single token.  `:hi @number.suffix guifg=... ` in your own
-- config overrides this; `:colorscheme` wipes it, hence the autocmd.
local emphasis = {
  ["@number.prefix"] = { bold = true },
  ["@number.suffix"] = { bold = true },
  ["@number.float.prefix"] = { bold = true },
  ["@number.float.exponent"] = { bold = true },
}

local function set_number_emphasis()
  for group, attrs in pairs(emphasis) do
    vim.api.nvim_set_hl(0, group, vim.tbl_extend("error", attrs, { default = true }))
  end
end

set_number_emphasis()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = "mim_treesitter",
  desc = "re-apply the Mim number-literal emphasis, which `:hi clear` drops",
  callback = set_number_emphasis,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "mim",
  group = "mim_treesitter",
  desc = "start tree-sitter highlighting for Mim",
  callback = function(ev)
    -- After the 'syntax' option has been set for the buffer: the highlighter clears it, and doing
    -- that first would leave the regex syntax running on top of the tree-sitter highlights.
    -- Fails harmlessly while the parser is not installed, and starting twice is a no-op, so a
    -- distribution that starts the highlighter itself is not disturbed.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        pcall(vim.treesitter.start, ev.buf)
      end
    end)
  end,
})
