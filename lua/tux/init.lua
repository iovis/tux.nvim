local u = require("tux.utils")

-- TODO:
-- - Split files
-- - Use `vim.validate()` (See :h vim.validate())
local tux = {}

---@alias TuxPaneOrientation "horizontal"|"vertical"
---@alias TuxPopupBorder "single"|"rounded"|"double"|"heavy"|"simple"|"padded"|"none"
---@alias TuxPopupCloseOnExit "on"|"off"|"success" Close the popup when the command exits
---@alias TuxStrategy "pane"|"window"|"popup"

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
  ---@class TuxPopupOpts
  popup = {
    ---@type TuxPopupCloseOnExit
    auto_close = "off",
    width = "50%",
    height = "50%",
    border = "rounded",
    ---@type string?
    title = nil,
  },
  ---@class TuxWindowOpts
  window = {
    detached = false,
    name = nil,
    ---@type boolean If window with name exists, select instead
    select = false,
  },
}

---Setup Tux
---@param opts TuxOpts
tux.setup = function(opts)
  opts = opts or {}
  tux.config = vim.tbl_deep_extend("force", tux.default_config, opts)

  vim.api.nvim_create_user_command("Tux", function(ctx)
    tux.run(ctx.args)
  end, { nargs = "*" }) -- complete = "shellcmd"

  vim.api.nvim_create_user_command("Tuxpane", function(ctx)
    tux.pane(ctx.args)
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("Tuxwindow", function(ctx)
    tux.window(ctx.args)
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("Tuxpopup", function(ctx)
    tux.popup(ctx.args)
  end, { nargs = "*" })
end

---Run command in Tmux using the default strategy
---@param command string
tux.run = function(command)
  local strategy = tux.config.default_strategy
  tux[strategy](command)
end

---Run command in a Tmux window
---@param command string
---@param opts? TuxWindowOpts
tux.window = function(command, opts)
  opts = vim.tbl_deep_extend("force", tux.config.window, opts or {})

  local tmux_command = "tmux new-window"

  if opts.detached then
    tmux_command = ("%s -d"):format(tmux_command)
  end

  if opts.name then
    local name = vim.fn.shellescape(opts.name)
    tmux_command = ("%s -n %s"):format(tmux_command, name)
  end

  if opts.select then
    assert(opts.name and not opts.detached, "`select` requires a `name` and it can't be detached")

    tmux_command = ("%s -S"):format(tmux_command)
  end

  if command ~= "" then
    tmux_command = tmux_command .. " $SHELL -i -c " .. vim.fn.shellescape(command)
  end

  u.execute(tmux_command)
end

---Run command in a Tmux popup
---@param command string
---@param opts? TuxPopupOpts
tux.popup = function(command, opts)
  opts = vim.tbl_deep_extend("force", tux.config.popup, opts or {})

  local tmux_command = ("tmux display-popup -b %s -w %s -h %s"):format(
    opts.border,
    vim.fn.escape(opts.width, "%"),
    vim.fn.escape(opts.height, "%")
  )

  if opts.auto_close == "on" then
    tmux_command = tmux_command .. " -E"
  elseif opts.auto_close == "success" then
    tmux_command = tmux_command .. " -EE"
  end

  if opts.title then
    tmux_command = ("%s -T %s"):format(tmux_command, opts.title)
  end

  if command ~= "" then
    tmux_command = tmux_command .. " $SHELL -i -c " .. vim.fn.shellescape(command)
  end

  u.execute(tmux_command)
end

---Run command in a Tmux pane
---@param command string
---@param opts? TuxPaneOpts
tux.pane = function(command, opts)
  opts = vim.tbl_deep_extend("force", tux.config.pane, opts or {})

  if tux.number_of_panes() == 1 then
    tux.create_pane(opts)
    tux.last_pane()
  else
    tux.exit_copy_mode(opts.target)
  end

  if command ~= "" then
    tux.send_keys(command, opts.target)
  else
    tux.last_pane()
  end
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

---Navigate to last pane
tux.last_pane = function()
  vim.fn.system("tmux last-pane")
end

---Number of panes in current window
---@return number
tux.number_of_panes = function()
  local command = "tmux list-panes | wc -l"
  return tonumber(vim.fn.system(command)) --[[@as number]]
end

---Send keys to target
---@private
---@param command string
---@param target string
tux.send_keys = function(command, target)
  local tmux_command = ("tmux send -t %s %s Enter"):format(target, vim.fn.shellescape(command))
  u.execute(tmux_command)
end

return tux
