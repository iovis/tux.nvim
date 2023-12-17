local M = {}

---Wraps a `command` in a `silent !{command}` and executes it
---This allows things like `%` to be expanded
---@param command string
M.execute = function(command)
  command = ("silent !%s"):format(command)
  vim.cmd(command)
end

---Send keys to target
---@param command string
---@param target string
M.send_keys = function(command, target)
  local tmux_command = ("tmux send -t %s %s Enter"):format(target, vim.fn.shellescape(command))
  M.execute(tmux_command)
end

---Navigate to last pane
M.focus_last_pane = function()
  vim.fn.system("tmux last-pane")
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
  local command = ("tmux send -t %s -X cancel"):format(pane)
  vim.fn.system(command)
end

---Create pane
---@param opts TuxPaneOpts
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

  local command = ("tmux split-window %s -p %d"):format(orientation, opts.size)
  vim.fn.system(command)
end

return M
