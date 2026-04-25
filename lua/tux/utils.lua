local M = {}

---Run tmux with argv arguments
---@param args string[]
---@return table
M.tmux = function(args)
  local command = { "tmux" }

  for _, arg in ipairs(args) do
    table.insert(command, arg)
  end

  return vim.system(command, { text = true }):wait()
end

---Expand Vim command-line filename modifiers, send the command or tmux key to target, and press Enter
---@param command string
---@param target string
M.send_command = function(command, target)
  command = vim.fn.expandcmd(command)
  M.tmux({ "send-keys", "-t", target, "--", command, "Enter" })
end

---Send literal text to target
---@param text string
---@param target string
M.send_text = function(text, target)
  M.tmux({ "send-keys", "-t", target, "-l", "--", text })
end

---Send enter to target
---@param target string
M.send_enter = function(target)
  M.tmux({ "send-keys", "-t", target, "Enter" })
end

---Paste literal text into target pane using a temporary tmux buffer
---@param text string
---@param target string
M.paste_text = function(text, target)
  local buffer_name = ("tux.nvim.%d"):format(vim.fn.getpid())

  M.tmux({ "set-buffer", "-b", buffer_name, "--", text })
  M.tmux({ "paste-buffer", "-t", target, "-b", buffer_name, "-d" })
end

---Select the previously active pane
M.select_last_pane = function()
  M.tmux({ "last-pane" })
end

---Select target pane
---@param target string
M.select_pane = function(target)
  if target == "{last}" or target == ":.{last}" then
    M.select_last_pane()
    return
  end

  M.tmux({ "select-pane", "-t", target })
end

---Number of panes in current window
---@return number
M.number_of_panes = function()
  local result = M.tmux({ "display-message", "-p", "#{window_panes}" })
  return tonumber(vim.trim(result.stdout or "")) or 0
end

---Exit copy mode from the given pane
---@param pane string Tmux target pane
M.exit_copy_mode = function(pane)
  M.tmux({ "send-keys", "-t", pane, "-X", "cancel" })
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

  M.tmux({ "split-window", orientation, "-l", ("%d%%"):format(opts.size) })
end

return M
