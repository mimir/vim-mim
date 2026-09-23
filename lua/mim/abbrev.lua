--- Insert-mode expansion of the abbreviations for Mim's Unicode terminals.
---
--- Plain Vim gets the same abbreviations from `:iabbrev` in ftplugin/mim.vim, but Vim's
--- abbreviations cannot express all of them: one that ends in a non-keyword character - `\<`, `\>`
--- - expands only at the start of a line or after white space, and then only on <Esc>, <CR> or
--- <C-]>, never on the space that ends the word.  So Neovim tracks what is typed itself, the way
--- Lean's editor integrations do: the leader `\` opens an abbreviation, which is underlined
--- (`MimAbbrev`) until it is replaced.
---
--- An abbreviation is replaced as soon as it is unambiguous, as soon as a character that cannot
--- continue it is typed - a space, a digit, anything - and when insert mode or the abbreviation is
--- left.  Nothing is mapped, so no completion plugin is disturbed.
---
--- `vim.g.mim_abbrev = false` turns all of this off and leaves the `:iabbrev` ones in place;
--- `vim.g.mim_abbrev = { ... }` adds abbreviations of your own.

local M = {}

--- The character that opens an abbreviation.  Typing it twice inserts it literally.
M.leader = '\\'

--- What may follow the leader, and what it becomes.  `$CURSOR` in a replacement is where the
--- cursor is left, which is what makes the pairs useful: `\<>` types `‹›` around the cursor.
local ABBREVIATIONS = {
  to = '→',
  gets = '←',
  lm = 'λ',
  bot = '⊥',
  top = '⊤',
  box = '□',
  cup = '∪',
  ['<'] = '‹',
  ['>'] = '›',
  ll = '«',
  gg = '»',
  ['<>'] = '‹$CURSOR›',
  llgg = '«$CURSOR»',
}

local CURSOR = '$CURSOR'

--- The abbreviations, including the user's own ones from `vim.g.mim_abbrev`.
---@return table<string, string>
local function abbreviations()
  local extra = vim.g.mim_abbrev
  if type(extra) ~= 'table' then
    return ABBREVIATIONS
  end
  return vim.tbl_extend('force', ABBREVIATIONS, extra)
end

--- Can `text` still grow into a (longer) abbreviation?  While it can, the replacement waits: `\to`
--- is `\top` in the making, whereas `\bot` can only ever be `⊥` and is replaced right away.
---@param text string what has been typed after the leader
---@return boolean
local function unfinished(text)
  for key in pairs(abbreviations()) do
    if #key > #text and key:sub(1, #text) == text then
      return true
    end
  end
  return false
end

--- Expand the abbreviations in `text`, which starts with the leader.  The longest abbreviation
--- matching at the leader wins; whatever follows it is kept as typed - so the character which
--- ended the abbreviation survives, and a second leader starts the next one.  Text that matches
--- nothing is returned unchanged, leader and all.  This is the whole of what an abbreviation
--- means, with no buffer in the way, which is also how the test suite checks it.
---@param text string
---@return string expanded, integer? cursor byte offset of `$CURSOR` in the expansion
function M.expand(text)
  local lead = M.leader
  local all = abbreviations()
  local out, cursor = '', nil

  while text:sub(1, #lead) == lead do
    local rest = text:sub(#lead + 1)

    if rest:sub(1, #lead) == lead then -- `\\` is a literal leader
      out, text = out .. lead, rest:sub(#lead + 1)
    else
      local match
      for key in pairs(all) do
        if rest:sub(1, #key) == key and (match == nil or #key > #match) then
          match = key
        end
      end
      if match == nil then
        return out .. text, cursor
      end

      local to = all[match]
      local at = to:find(CURSOR, 1, true)
      if at then
        cursor = cursor or #out + at - 1
        to = to:sub(1, at - 1) .. to:sub(at + #CURSOR)
      end
      out, text = out .. to, rest:sub(#match + 1)
    end
  end

  return out .. text, cursor
end

-- The abbreviation currently being typed in a buffer is an extmark which grows with it: it starts
-- at the leader and ends at the cursor.
local namespace = vim.api.nvim_create_namespace('mim.abbrev')
local pending = {} ---@type table<integer, integer> buffer -> extmark
local attached = {} ---@type table<integer, integer[]> buffer -> autocommands

--- Open an abbreviation which starts `back` bytes before the cursor.
---@param buf integer
---@param back integer 0 while the leader is still on its way in (InsertCharPre), #leader after
local function open(buf, back)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  pending[buf] = vim.api.nvim_buf_set_extmark(buf, namespace, row - 1, col - back, {
    hl_group = 'MimAbbrev',
    end_row = row - 1,
    end_col = col,
    -- so that what is typed at either end of the mark ends up inside it
    right_gravity = false,
    end_right_gravity = true,
  })
end

local function close(buf)
  if pending[buf] then
    vim.api.nvim_buf_del_extmark(buf, namespace, pending[buf])
    pending[buf] = nil
  end
end

--- The abbreviation being typed in `buf` and where it sits, or nil if there is none.  An <CR> in
--- the middle of one stretches the mark onto the next line; only the first line is the
--- abbreviation.
---@param buf integer
---@return string? text, integer? row, integer? col, integer? end_col
local function typed(buf)
  if pending[buf] == nil then
    return nil
  end
  local row, col, details =
    unpack(vim.api.nvim_buf_get_extmark_by_id(buf, namespace, pending[buf], { details = true }))
  if row == nil or details == nil then
    return nil
  end

  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
  local end_col = details.end_row == row and details.end_col or #line
  return line:sub(col + 1, end_col), row, col, end_col
end

--- Is an abbreviation being typed in `buf`?  Used by the test suite.
---@param buf integer
---@return boolean
function M.is_pending(buf)
  return typed(buf ~= 0 and buf or vim.api.nvim_get_current_buf()) ~= nil
end

--- Replace the abbreviation being typed in `buf` by what it stands for.
---@param buf integer
function M.convert(buf)
  local text, row, col, end_col = typed(buf)
  close(buf)
  if text == nil or text == '' then
    return
  end

  local expanded, cursor = M.expand(text)
  if expanded == text then
    return
  end

  local at = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_text(buf, row, col, row, end_col, { expanded })

  -- Only when the cursor is still behind the abbreviation - after an <CR> or a click it has moved
  -- on and must stay where it is.
  if buf == vim.api.nvim_get_current_buf() and at[1] - 1 == row and at[2] >= end_col then
    vim.api.nvim_win_set_cursor(0, { row + 1, col + (cursor or #expanded) })
  end
end

--- InsertCharPre: `vim.v.char` is about to be inserted.  It is inserted before any replacement
--- runs, so it is part of the text convert() sees - which is what keeps the space that ends an
--- abbreviation, and lets the leader that ends one start the next.
---@param buf integer
local function typing(buf)
  local char = vim.v.char
  local text = typed(buf)

  if text == nil then
    if char == M.leader then
      open(buf, 0)
    end
    return
  end

  if char == M.leader then
    local escaped = text == M.leader -- `\\`: a literal leader, and no new abbreviation
    vim.schedule(function()
      M.convert(buf)
      if not escaped and vim.api.nvim_get_current_buf() == buf then
        open(buf, #M.leader)
      end
    end)
  elseif not unfinished(text:sub(#M.leader + 1) .. char) then
    vim.schedule(function()
      M.convert(buf)
    end)
  end
end

--- Stop expanding abbreviations in `buf`.
---@param buf integer
function M.detach(buf)
  close(buf)
  for _, id in ipairs(attached[buf] or {}) do
    pcall(vim.api.nvim_del_autocmd, id)
  end
  attached[buf] = nil
end

--- Expand abbreviations in `buf`, which is a Mim buffer.  Called from plugin/mim.lua for every
--- such buffer; calling it twice is harmless.
---@param buf integer
function M.attach(buf)
  if attached[buf] then
    return
  end

  local group = vim.api.nvim_create_augroup('mim_abbrev', { clear = false })
  local function autocmd(event, desc, callback)
    return vim.api.nvim_create_autocmd(event, {
      group = group,
      buffer = buf,
      desc = desc,
      callback = callback,
    })
  end

  attached[buf] = {
    autocmd('InsertCharPre', 'follow the Mim abbreviation being typed', function()
      typing(buf)
    end),

    -- the cursor sits at the end of the abbreviation while it is typed; anywhere else - after an
    -- <CR>, an arrow key, a click - means the user has moved on
    autocmd('CursorMovedI', 'expand a Mim abbreviation the cursor leaves', function()
      local _, row, _, end_col = typed(buf)
      if row == nil then
        return close(buf)
      end
      local at = vim.api.nvim_win_get_cursor(0)
      if at[1] - 1 ~= row or at[2] ~= end_col then
        M.convert(buf)
      end
    end),

    autocmd({ 'InsertLeave', 'BufLeave' }, 'expand a half-typed Mim abbreviation', function()
      M.convert(buf)
    end),

    autocmd('FileType', 'stop once the buffer is no longer Mim', function()
      if vim.bo[buf].filetype ~= 'mim' then
        M.detach(buf)
      end
    end),

    autocmd('BufWipeout', 'forget the buffer', function()
      M.detach(buf)
    end),
  }
end

return M
