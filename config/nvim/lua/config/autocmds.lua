-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- ---------------------------------------------------------------------------
-- Buffer-local markdown note-taking maps (tasks, list toggles, headings).
-- Companion to the render-markdown / obsidian setup; documented in the vault's
-- "Neovim Keybindings" note (Part 1 -> Markdown note-taking).
--
-- Completing a task stamps `✅ YYYY-MM-DD` to round-trip with the Obsidian Tasks
-- plugin. NOTE: the bare `tb`/`tc`/`tn`/`tl` maps intentionally shadow the
-- built-in `t{char}` motion inside markdown buffers.
-- ---------------------------------------------------------------------------

local function today()
  return os.date("%Y-%m-%d")
end

local function get_line(lnum)
  return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""
end

local function set_line(lnum, text)
  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { text })
end

-- Remove a trailing " ✅ YYYY-MM-DD" completion stamp.
local function strip_stamp(s)
  return (s:gsub("%s*✅%s*%d%d%d%d%-%d%d%-%d%d%s*$", ""))
end

-- Join a list prefix + body without leaving a trailing space on empty bodies.
local function join(prefix, body)
  body = vim.trim(body)
  if body == "" then
    return (prefix:gsub("%s+$", ""))
  end
  return prefix .. body
end

-- Toggle a single line's task state, stamping / unstamping the completion date.
-- Non-task bullets gain a checkbox; plain lines become a task.
local function toggle_task(line)
  local indent, marker, state, rest = line:match("^(%s*)([%-%*%+]%s+)%[([ xX])%]%s?(.*)$")
  if state then
    if state == " " then
      return string.format("%s%s[x] %s ✅ %s", indent, marker, vim.trim(strip_stamp(rest)), today())
    end
    return join(string.format("%s%s[ ] ", indent, marker), strip_stamp(rest))
  end
  local bindent, bmarker, brest = line:match("^(%s*)([%-%*%+]%s+)(.*)$")
  if bmarker then
    return join(string.format("%s%s[ ] ", bindent, bmarker), brest)
  end
  local pindent, prest = line:match("^(%s*)(.*)$")
  return join(string.format("%s- [ ] ", pindent), prest)
end

-- Mark every task in the buffer done (stamp) or undone (unstamp).
local function set_all_tasks(done)
  for l = 1, vim.api.nvim_buf_line_count(0) do
    local line = get_line(l)
    local indent, marker, state, rest = line:match("^(%s*)([%-%*%+]%s+)%[([ xX])%]%s?(.*)$")
    if state then
      if done and state == " " then
        set_line(l, string.format("%s%s[x] %s ✅ %s", indent, marker, vim.trim(strip_stamp(rest)), today()))
      elseif not done and state ~= " " then
        set_line(l, join(string.format("%s%s[ ] ", indent, marker), strip_stamp(rest)))
      end
    end
  end
end

-- List-type helpers ---------------------------------------------------------

local function list_kind(line)
  local rest = line:match("^%s*(.*)$")
  if rest:match("^[%-%*%+]%s+%[[ xX]%]") then
    return "check"
  elseif rest:match("^[%-%*%+]%s+") then
    return "bullet"
  elseif rest:match("^%d+[%.%)]%s+") then
    return "number"
  end
  return "plain"
end

local function strip_marker(line)
  local indent = line:match("^(%s*)")
  local rest = line:sub(#indent + 1)
  rest = rest:gsub("^[%-%*%+]%s+%[[ xX]%]%s*", "")
  rest = rest:gsub("^[%-%*%+]%s+", "")
  rest = rest:gsub("^%d+[%.%)]%s+", "")
  return indent, rest
end

local function set_kind(line, kind)
  local indent, rest = strip_marker(line)
  if kind == "bullet" then
    return join(indent .. "- ", rest)
  elseif kind == "check" then
    return join(indent .. "- [ ] ", rest)
  elseif kind == "number" then
    return join(indent .. "1. ", rest)
  end
  return join(indent, rest) -- plain
end

local next_kind = { plain = "bullet", bullet = "check", check = "number", number = "plain" }

-- Apply a line transform to the current line (normal) or selection (visual).
local function transform(fn)
  local mode = vim.fn.mode()
  local s, e
  if mode == "v" or mode == "V" or mode == "\22" then
    s, e = vim.fn.line("v"), vim.fn.line(".")
    if s > e then
      s, e = e, s
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  else
    s = vim.fn.line(".")
    e = s
  end
  for l = s, e do
    set_line(l, fn(get_line(l)))
  end
end

local function toggle_heading(level)
  local lnum = vim.fn.line(".")
  local indent, hashes, rest = get_line(lnum):match("^(%s*)(#*)%s*(.*)$")
  local target = string.rep("#", level)
  if hashes == target then
    set_line(lnum, join(indent, rest)) -- already this level -> remove heading
  else
    set_line(lnum, indent .. target .. " " .. rest)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("bigb_markdown_maps", { clear = true }),
  pattern = "markdown",
  callback = function(ev)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
    end

    -- Tasks  (<leader>t = tasks)
    map({ "n", "x" }, "<leader>tt", function()
      transform(toggle_task)
    end, "Toggle task + ✅ date")
    map("n", "<leader>ta", function()
      local lnum = vim.fn.line(".")
      local indent = get_line(lnum):match("^(%s*)")
      local text = indent .. "- [ ] "
      vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { text })
      vim.api.nvim_win_set_cursor(0, { lnum + 1, #text })
      vim.cmd("startinsert!")
    end, "Add task below")
    map("n", "<leader>tc", function()
      set_all_tasks(true)
    end, "Mark all tasks done")
    map("n", "<leader>tu", function()
      set_all_tasks(false)
    end, "Mark all tasks undone")
    map("i", "<C-t>", function()
      vim.api.nvim_put({ "- [ ] " }, "c", false, true)
    end, "Insert checkbox")

    -- List toggles  (bare t prefix; shadows the t{char} motion in markdown)
    map({ "n", "x" }, "tb", function()
      transform(function(l)
        return set_kind(l, list_kind(l) == "bullet" and "plain" or "bullet")
      end)
    end, "Toggle bullet list")
    map({ "n", "x" }, "tc", function()
      transform(function(l)
        return set_kind(l, list_kind(l) == "check" and "plain" or "check")
      end)
    end, "Toggle checkbox list")
    map({ "n", "x" }, "tn", function()
      transform(function(l)
        return set_kind(l, list_kind(l) == "number" and "plain" or "number")
      end)
    end, "Toggle numbered list")
    map({ "n", "x" }, "tl", function()
      transform(function(l)
        return set_kind(l, next_kind[list_kind(l)])
      end)
    end, "Cycle list type")

    -- Headings  (<leader>h = headings)
    for i = 1, 6 do
      map("n", "<leader>h" .. i, function()
        toggle_heading(i)
      end, "Toggle H" .. i)
    end

    -- Buffer-local which-key group labels.
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<leader>t", group = "tasks", buffer = ev.buf },
        { "<leader>h", group = "headings", buffer = ev.buf },
      })
    end
  end,
})
