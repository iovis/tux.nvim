local u = require("tux.utils")

-- TODO:
-- - Use `vim.validate()` (See :h vim.validate())
-- - `Tmux` command?

local tux = {}

---@alias tux.pane.orientation "horizontal"|"vertical"
---@alias tux.popup.border "single"|"rounded"|"double"|"heavy"|"simple"|"padded"|"none"
---@alias tux.popup.close_on_exit "on"|"off"|"success" Close the popup when the command exits
---@alias tux.strategy "pane"|"window"|"popup"

---@class tux.Opts
tux.default_config = {
  ---@type tux.strategy
  default_strategy = "pane",
  ---@class tux.pane.Opts
  pane = {
    ---@type tux.pane.orientation
    orientation = "horizontal",
    ---@type number Size as percentage
    size = 30,
    target = ":.{last}",
  },
  ---@class tux.popup.Opts
  popup = {
    ---@type tux.popup.close_on_exit
    auto_close = "off",
    width = "50%",
    height = "50%",
    border = "rounded",
    ---@type string?
    title = nil,
  },
  ---@class tux.window.Opts
  window = {
    detached = false,
    name = nil,
    ---@type boolean If window with name exists, select instead
    select = false,
  },
}

---Run command in Tmux using the default strategy
---@param command string
tux.run = function(command)
  local strategy = tux.config.default_strategy
  tux[strategy](command)
end

---Run command in a Tmux window
---@param command string
---@param opts? tux.window.Opts
tux.window = function(command, opts)
  if not vim.env.TMUX then
    vim.notify("Not in tmux session", vim.log.levels.WARN)
    return
  end

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
---@param opts? tux.popup.Opts
tux.popup = function(command, opts)
  if not vim.env.TMUX then
    vim.notify("Not in tmux session", vim.log.levels.WARN)
    return
  end

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
---@param opts? tux.pane.Opts
tux.pane = function(command, opts)
  if not vim.env.TMUX then
    vim.notify("Not in tmux session", vim.log.levels.WARN)
    return
  end

  opts = vim.tbl_deep_extend("force", tux.config.pane, opts or {})

  if u.number_of_panes() == 1 then
    u.create_pane(opts)
    u.focus_last_pane()
  else
    u.exit_copy_mode(opts.target)
  end

  if command ~= "" then
    u.send_keys(command, opts.target)
  else
    u.focus_last_pane()
  end
end

local generate_commands = function()
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

---Setup Tux
---@param opts tux.Opts
tux.setup = function(opts)
  opts = opts or {}
  tux.config = vim.tbl_deep_extend("force", tux.default_config, opts)
  generate_commands()
end

return tux
