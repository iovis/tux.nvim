local M = {}

---Wraps a `command` in a `silent !{command}` and executes it
---This allows things like `%` to be expanded
---@param command string
M.execute = function(command)
  command = ("silent !%s"):format(command)
  vim.cmd(command)
end

return M
