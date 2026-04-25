local M = {}

---Wraps a `command` in a `silent !{command}` and executes it
---This allows things like `%` to be expanded
---@param command string
M.execute = function(command)
  command = ("silent !%s"):format(command)
  vim.cmd(command)
end

---Expand Vim command-line filename modifiers, send the command to target, and press Enter
---@param command string
---@param target string
M.send_command = function(command, target)
  command = vim.fn.expandcmd(command)
  M.send_text(command, target)
  M.send_enter(target)
end

---Send literal text to target
---@param text string
---@param target string
M.send_text = function(text, target)
  vim.system({ "tmux", "send-keys", "-t", target, "-l", "--", text }, { text = true }):wait()
end

---Send enter to target
---@param target string
M.send_enter = function(target)
  vim.system({ "tmux", "send-keys", "-t", target, "Enter" }, { text = true }):wait()
end

---Paste literal text into target pane using a temporary tmux buffer
---@param text string
---@param target string
M.paste_text = function(text, target)
  local buffer_name = ("tux.nvim.%d"):format(vim.fn.getpid())

  vim.system({ "tmux", "set-buffer", "-b", buffer_name, "--", text }, { text = true }):wait()
  vim.system({ "tmux", "paste-buffer", "-t", target, "-b", buffer_name, "-d" }, { text = true }):wait()
  vim.system({ "tmux", "send-keys", "-t", target, "Enter" }, { text = true }):wait()
end

---Navigate to last pane
M.focus_last_pane = function()
  vim.fn.system("tmux last-pane")
end

---Navigate to target pane
---@param target string
M.focus_pane = function(target)
  if target == "{last}" or target == ":.{last}" then
    M.focus_last_pane()
    return
  end

  vim.system({ "tmux", "select-pane", "-t", target }, { text = true }):wait()
end

---Number of panes in current window
---@return number
M.number_of_panes = function()
  local number_of_panes = vim.fn.system("tmux list-panes | wc -l")
  return tonumber(number_of_panes) --[[@as number]]
end

---Exit copy mode from the given pane
---@param pane string Tmux target pane
M.exit_copy_mode = function(pane)
  vim.system({ "tmux", "send-keys", "-t", pane, "-X", "cancel" }, { text = true }):wait()
end

---Create pane
---@param opts tux.pane.Config
M.create_pane = function(opts)
  assert(
    opts.orientation == "horizontal" or opts.orientation == "vertical",
    'pane.orientation should be "horizontal"|"vertical". Given: ',
    opts.orientation
  )

  local orientation
  if opts.orientation == "horizontal" then
    orientation = "-v"
  elseif opts.orientation == "vertical" then
    orientation = "-h"
  end

  local command = ("tmux split-window %s -l '%d%%'"):format(orientation, opts.size)
  vim.fn.system(command)
end

return M
