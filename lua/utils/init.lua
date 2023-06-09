local M = {}

local api = vim.api

M.set_keymaps = function(maps)
  for mode, _maps in pairs(maps) do
    for key, values in pairs(_maps) do
      vim.keymap.set(mode, key, values[1], values[2])
    end
  end
end

M.get_selection = function()
  local selectionStart = vim.fn.line "v"
  local selectionEnd = vim.fn.line "."

  if selectionStart > selectionEnd then
    local temp = selectionStart
    selectionStart = selectionEnd
    selectionEnd = temp
  end

  local lines = api.nvim_buf_get_lines(0, selectionStart - 1, selectionEnd, true)

  return { lines, selectionStart, selectionEnd }
end

M.escape = function()
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
end

M.find_bin_location = function(cmd)
  local currentDirectoryPwd = os.getenv "PWD"

  local function search(path)
    local commandAndPath = "fd -tx " .. cmd .. " " .. path
    local yarnCommand = commandAndPath .. "/.yarn/unplugged 2>/dev/null"
    local nodeModulesCommand = commandAndPath .. "/node_modules 2>/dev/null"

    local command = io.popen(nodeModulesCommand)

    local filenames = {}

    if not command then
      return nil
    end

    for filename in command:lines() do
      table.insert(filenames, filename)
    end

    if vim.tbl_isempty(filenames) then
      command = io.popen(yarnCommand)

      if not command then
        return nil
      end
    end

    for filename in command:lines() do
      table.insert(filenames, filename)
    end

    if vim.tbl_isempty(filenames) then
      return nil
    end

    return filenames
  end

  local result = search(currentDirectoryPwd)

  if not result then
    return nil
  end

  return result[1]
end

M.moveCursor = function(key)
  api.nvim_feedkeys(api.nvim_replace_termcodes(key, true, false, true), "n", false)
end

M.format = function()
  vim.lsp.buf.formatting_sync()
end

M.tbl_get_index = function(_table, value)
  for i, v in ipairs(_table) do
    if v == value then
      return i
    end
  end

  return nil
end

M.next_color_scheme = function()
  local themes = require "themes"
  local value = M.tbl_get_index(themes, vim.g.colors_name)
  vim.cmd("colorscheme " .. themes[value + 1])
end

M.SPACERS = {
  left = "",
  mid = "▊",
  right = "",
}

M.spacer = function(props)
  props = vim.tbl_deep_extend("force", {
    fg = "NONE",
    bg = "NONE",
    length = 1,
    spacer = M.SPACERS.mid,
    enabled = true,
    style = "NONE",
  }, props or {})

  local separator = string.rep(props.spacer, props.length)

  return {
    provider = separator,
    hl = {
      fg = props.fg,
      bg = props.bg,
      style = props.style,
    },
    enabled = props.enabled,
  }
end

local function _hl_by_name(name)
  return vim.api.nvim_get_hl_by_name(name, true)
end

M.hl_by_name = function(name, prop)
  return string.format("#%06x", _hl_by_name(name)[prop])
end

---@param ssh_url string
M.git_ssh_to_url = function(ssh_url)
  local url = string.gsub(ssh_url:match ":.*/.*$", ":", "")

  return "https://github.com/" .. url
end

M.replace = function()
  local input = vim.fn.input "Word to replace: "
  local wordUnderCursor = vim.fn.expand "<cword>"

  local cmd = string.format("s/%s/%s/g", wordUnderCursor, input)
  vim.cmd(cmd)
  vim.cmd "noh"
  M.escape()
end

return M
