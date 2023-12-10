local tux = {}

-- TODO:
-- pane, window, popup
-- remain on exit
-- Tux command
-- tests

---@class TuxOpts
tux.default_config = {
  pane = {
    ---@type number pane split size
    size = 30,
    ---@type string tmux target
    target = "{last}",
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
  opts = vim.tbl_deep_extend("force", tux.config, opts or {})

  -- Exit copy mode if pane exists
  tux.exit_copy_mode(opts.pane.target)

  local tmux_command = tux.parse(command, opts)
  vim.fn.system(tmux_command)
end

---Exit copy mode from the given pane
---@param pane string Tmux target pane
tux.exit_copy_mode = function(pane)
  local command = ("tmux send -t %s -X cancel"):format(pane)
  vim.fn.system(command)
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
