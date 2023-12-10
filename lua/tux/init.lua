local tux = {}

-- TODO:
-- pane, window, popup
-- remain on exit
-- Tux command
-- tests

---@class TuxOpts
tux.default_config = {
  pane = {
    size = 30,
  },
}

---Setup Tux
---@param opts TuxOpts
tux.setup = function(opts)
  opts = opts or {}
  tux.config = vim.tbl_deep_extend("force", tux.default_config, opts)
end

---Run command in Tmux
---@param command string
---@param opts? TuxOpts
tux.run = function(command, opts)
  -- Exit copy mode if pane exists
  vim.fn.system("tmux send -t {last} -X cancel")

  local tmux_command = tux.parse(command, opts)
  vim.fn.system(tmux_command)
end

---Generate Tmux command
---@private
---@param command string
---@param opts? TuxOpts
---@return string Command to run
tux.parse = function(command, opts)
  command = vim.fn.shellescape(command)

  return ("tmux send -t {last} %s Enter"):format(command)
end

return tux
