local tux = {}

---@alias TuxPaneOrientation "horizontal"|"vertical"
---@alias TuxStrategy "pane"|"window"|"float"

-- TODO:
-- pane, window, popup
-- remain on exit
-- focus
-- Tux command
-- tests

---@class TuxOpts
tux.default_config = {
  ---@type TuxStrategy
  default_strategy = "pane",
  ---@class TuxPaneOpts
  pane = {
    ---@type TuxPaneOrientation
    orientation = "horizontal",
    ---@type number Size as percentage
    size = 30,
    target = ":.{last}",
  },
}

---Setup Tux
---@param opts TuxOpts
tux.setup = function(opts)
  opts = opts or {}
  tux.config = vim.tbl_deep_extend("force", tux.default_config, opts)

  vim.api.nvim_create_user_command("Tux", function(ctx)
    tux.run(ctx.args)
  end, { nargs = "+" })

  vim.api.nvim_create_user_command("TuxPane", function(ctx)
    tux.pane(ctx.args)
  end, { nargs = "+" }) -- complete = "shellcmd"
end

---Run command in Tmux using the default strategy
---@param command string
tux.run = function(command)
  local strategy = tux.config.default_strategy

  tux[strategy](command)
end

---Run command in a Tmux pane
---@param command string
---@param opts? TuxPaneOpts
tux.pane = function(command, opts)
  local tmux_command

  opts = vim.tbl_deep_extend("force", tux.config.pane, opts or {})

  if tux.number_of_panes() == 1 then
    tux.create_pane(opts)
    tmux_command = tux.parse(command)
  else
    tux.exit_copy_mode(opts.target)
    tmux_command = tux.parse(command, opts.target)
  end

  vim.fn.system(tmux_command)
end

---Create pane
---@param opts TuxPaneOpts
tux.create_pane = function(opts)
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

---Exit copy mode from the given pane
---@param pane string Tmux target pane
tux.exit_copy_mode = function(pane)
  local command = ("tmux send -t %s -X cancel"):format(pane)
  vim.fn.system(command)
end

---Number of panes in current window
---@return number
tux.number_of_panes = function()
  local command = "tmux list-panes | wc -l"
  return tonumber(vim.fn.system(command)) --[[@as number]]
end

---Generate Tmux command
---@private
---@param command string
---@param target? string
---@return string
tux.parse = function(command, target)
  local tmux_command = "tmux send"

  if target then
    tmux_command = ("%s -t %s"):format(tmux_command, target)
  end

  command = vim.fn.shellescape(command)
  return ("%s %s Enter"):format(tmux_command, command)
end

return tux
