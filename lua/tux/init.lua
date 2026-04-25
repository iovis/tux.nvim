local u = require("tux.utils")

local tux = {}

---@alias tux.pane.orientation "horizontal"|"vertical"
---@alias tux.popup.border "single"|"rounded"|"double"|"heavy"|"simple"|"padded"|"none"
---@alias tux.popup.close_on_exit "on"|"off"|"success" Close the popup when the command exits
---@alias tux.strategy "pane"|"window"|"popup"

---@class tux.pane.Opts
---@field orientation? tux.pane.orientation
---@field size? number Size as percentage
---@field target? string

---@class tux.pane.Config
---@field orientation tux.pane.orientation
---@field size number Size as percentage
---@field target string

---@class tux.popup.Opts
---@field auto_close? tux.popup.close_on_exit
---@field width? string
---@field height? string
---@field border? tux.popup.border
---@field title? string

---@class tux.popup.Config
---@field auto_close tux.popup.close_on_exit
---@field width string
---@field height string
---@field border tux.popup.border
---@field title? string

---@class tux.send.Opts
---@field target? string Defaults to `pane.target`
---@field focus? boolean
---@field enter? boolean

---@class tux.send.Config
---@field target? string Defaults to `pane.target`
---@field focus boolean
---@field enter boolean

---@class tux.file.Opts
---@field prefix? string
---@field modifier? string Vim filename modifier used with `expand()`

---@class tux.file.Config
---@field prefix string
---@field modifier string Vim filename modifier used with `expand()`

---@class tux.location.Opts: tux.file.Opts, tux.send.Opts
---@class tux.location.Config: tux.file.Config, tux.send.Opts

---@class tux.window.Opts
---@field detached? boolean
---@field name? string
---@field select? boolean If window with name exists, select instead

---@class tux.window.Config
---@field detached boolean
---@field name? string
---@field select boolean If window with name exists, select instead

---@class tux.Config
---@field default_strategy tux.strategy
---@field pane tux.pane.Config
---@field popup tux.popup.Config
---@field send tux.send.Config
---@field file tux.file.Config
---@field window tux.window.Config

---@class tux.Opts
---@field default_strategy? tux.strategy
---@field pane? tux.pane.Opts
---@field popup? tux.popup.Opts
---@field send? tux.send.Opts
---@field file? tux.file.Opts
---@field window? tux.window.Opts

---@type tux.Config
tux.default_config = {
  default_strategy = "pane",
  pane = {
    orientation = "horizontal",
    size = 30,
    target = ":.{last}",
  },
  popup = {
    auto_close = "off",
    width = "50%",
    height = "50%",
    border = "rounded",
    title = nil,
  },
  send = {
    target = nil,
    focus = true,
    enter = false,
  },
  file = {
    prefix = "@",
    modifier = "%:.",
  },
  window = {
    detached = false,
    name = nil,
    select = false,
  },
}

---@type tux.Config
tux.config = tux.default_config

local function in_tmux()
  if not vim.env.TMUX then
    vim.notify("Not in tmux session", vim.log.levels.WARN)
    return false
  end

  return true
end

---@param opts tux.pane.Config
local function prepare_pane(opts)
  if u.number_of_panes() == 1 then
    u.create_pane(opts)
    u.select_last_pane()
  else
    u.exit_copy_mode(opts.target)
  end
end

local function range_text(line1, line2)
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  return table.concat(lines, "\n")
end

local function selected_line_range()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil, nil
  end

  local line_start = vim.fn.line("v")
  local line_end = vim.fn.line(".")

  if line_start > line_end then
    line_start, line_end = line_end, line_start
  end

  vim.api.nvim_input("<Esc>")
  return line_start, line_end
end

local function format_location(line_start, line_end)
  if line_start == line_end then
    return tostring(line_start)
  end

  return ("%s-%s"):format(line_start, line_end)
end

---@param opts tux.file.Config
local function file_reference(opts)
  return ("%s%s"):format(opts.prefix, vim.fn.expand(opts.modifier))
end

---@param command string
---@return string
local function shell_command(command)
  local shell = vim.fn.shellescape(vim.env.SHELL or "sh")
  local expanded_command = vim.fn.shellescape(vim.fn.expandcmd(command))

  return ("%s -i -c %s"):format(shell, expanded_command)
end

---Run command in Tmux using the default strategy
---@param command string
tux.run = function(command)
  local strategy = tux.config.default_strategy
  tux[strategy](command)
end

---Send literal text to a tmux pane
---@param text string
---@param opts? tux.send.Opts
tux.send = function(text, opts)
  if not in_tmux() then
    return
  end

  ---@type tux.send.Config
  local send_opts = vim.tbl_deep_extend("force", tux.config.send, opts or {})
  local target = send_opts.target or tux.config.pane.target

  u.exit_copy_mode(target)
  u.send_text(text, target)

  if send_opts.enter then
    u.send_enter(target)
  end

  if send_opts.focus then
    u.select_pane(target)
  end
end

---Send the current file reference to a tmux pane
---@param opts? tux.location.Opts
tux.send_file = function(opts)
  ---@type tux.location.Config
  local location_opts = vim.tbl_deep_extend("force", tux.config.file, opts or {})
  tux.send(file_reference(location_opts), location_opts)
end

---Send the current file location to a tmux pane
---
---When called from visual mode, the selected line range is sent. Otherwise the
---current cursor line is sent.
---@param opts? tux.location.Opts
tux.send_location = function(opts)
  ---@type tux.location.Config
  local location_opts = vim.tbl_deep_extend("force", tux.config.file, opts or {})

  local line_start, line_end = selected_line_range()
  line_start = line_start or vim.fn.line(".")
  line_end = line_end or line_start

  tux.send(("%s:%s"):format(file_reference(location_opts), format_location(line_start, line_end)), location_opts)
end

---Run selected lines in the target pane as literal text
---@param line1 integer
---@param line2 integer
---@param opts? tux.pane.Opts
tux.run_range = function(line1, line2, opts)
  if not in_tmux() then
    return
  end

  ---@type tux.pane.Config
  local pane_opts = vim.tbl_deep_extend("force", tux.config.pane, opts or {})

  prepare_pane(pane_opts)

  local text = range_text(line1, line2)
  if text ~= "" then
    u.paste_text(text, pane_opts.target)
    u.send_enter(pane_opts.target)
  else
    u.select_last_pane()
  end
end

---Run command in a Tmux window
---@param command string
---@param opts? tux.window.Opts
tux.window = function(command, opts)
  if not in_tmux() then
    return
  end

  ---@type tux.window.Config
  local window_opts = vim.tbl_deep_extend("force", tux.config.window, opts or {})

  local tmux_args = { "new-window" }

  if window_opts.detached then
    table.insert(tmux_args, "-d")
  end

  if window_opts.name then
    table.insert(tmux_args, "-n")
    table.insert(tmux_args, window_opts.name)
  end

  if window_opts.select then
    assert(window_opts.name and not window_opts.detached, "`select` requires a `name` and it can't be detached")

    table.insert(tmux_args, "-S")
  end

  if command ~= "" then
    table.insert(tmux_args, shell_command(command))
  end

  u.tmux(tmux_args)
end

---Run command in a Tmux popup
---@param command string
---@param opts? tux.popup.Opts
tux.popup = function(command, opts)
  if not in_tmux() then
    return
  end

  ---@type tux.popup.Config
  local popup_opts = vim.tbl_deep_extend("force", tux.config.popup, opts or {})

  local tmux_args = {
    "display-popup",
    "-b",
    popup_opts.border,
    "-w",
    popup_opts.width,
    "-h",
    popup_opts.height,
  }

  if popup_opts.auto_close == "on" then
    table.insert(tmux_args, "-E")
  elseif popup_opts.auto_close == "success" then
    table.insert(tmux_args, "-EE")
  end

  if popup_opts.title then
    table.insert(tmux_args, "-T")
    table.insert(tmux_args, popup_opts.title)
  end

  if command ~= "" then
    table.insert(tmux_args, shell_command(command))
  end

  u.tmux(tmux_args)
end

---Run command in a Tmux pane
---@param command string
---@param opts? tux.pane.Opts
tux.pane = function(command, opts)
  if not in_tmux() then
    return
  end

  ---@type tux.pane.Config
  local pane_opts = vim.tbl_deep_extend("force", tux.config.pane, opts or {})

  prepare_pane(pane_opts)

  if command ~= "" then
    u.send_command(command, pane_opts.target)
  else
    u.select_last_pane()
  end
end

local generate_commands = function()
  vim.api.nvim_create_user_command("Tux", function(ctx)
    if ctx.range > 0 then
      if ctx.args ~= "" then
        vim.notify("Tux does not accept both a range and command arguments", vim.log.levels.WARN)
        return
      end

      tux.run_range(ctx.line1, ctx.line2)
      return
    end

    tux.run(ctx.args)
  end, { nargs = "*", range = true, complete = "shellcmd" })

  vim.api.nvim_create_user_command("Tuxpane", function(ctx)
    tux.pane(ctx.args)
  end, { nargs = "*", complete = "shellcmd" })

  vim.api.nvim_create_user_command("Tuxwindow", function(ctx)
    tux.window(ctx.args)
  end, { nargs = "*", complete = "shellcmd" })

  vim.api.nvim_create_user_command("Tuxpopup", function(ctx)
    tux.popup(ctx.args)
  end, { nargs = "*", complete = "shellcmd" })
end

---Setup Tux
---@param opts? tux.Opts
tux.setup = function(opts)
  opts = opts or {}
  ---@type tux.Config
  local config = vim.tbl_deep_extend("force", tux.default_config, opts)
  tux.config = config
  generate_commands()
end

return tux
