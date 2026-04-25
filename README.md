# tux.nvim

Run commands from Neovim in tmux.

Tux sends shell commands, current lines, or visual selections to a tmux pane by
default. It can also run commands in a new tmux window or popup when you want a
separate workspace.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "iovis/tux.nvim",
  config = function()
    require("tux").setup({})
  end,
}
```

## Bindings

Most usage is through `:Tux`.

```lua
local tux = require("tux")

vim.keymap.set("n", "c<space>", ":Tux<space>")
vim.keymap.set("n", "s<cr>", "<cmd>Tux just run<cr>")
vim.keymap.set("n", "m<cr>", "<cmd>Tux just build<cr>")

vim.keymap.set("n", "<leader>I", ":.Tux<cr>", {
  desc = "[tux] execute current line",
})

vim.keymap.set("x", "<leader>i", ":Tux<cr>", {
  desc = "[tux] run selected lines",
})

vim.keymap.set("n", "<leader>S", function()
  tux.run("just --choose")
end, {
  desc = "[tux] run a task from the Justfile",
})
```

`:Tux` accepts shell commands, so filetype-local mappings can stay very small:

```lua
vim.keymap.set("n", "s<cr>", "<cmd>Tux cargo run --release<cr>", { buf = 0 })
vim.keymap.set("n", "m<cr>", "<cmd>Tux cargo check --all-targets<cr>", { buf = 0 })
vim.keymap.set("n", "<leader>sw", "<cmd>Tux cargo watch -x check<cr>", { buf = 0 })
```

Vim filename modifiers such as `%`, `%:.`, and `%:t:r` are expanded because Tux
runs through Neovim's shell command path:

```lua
vim.keymap.set("n", "s<cr>", "<cmd>Tux python %<cr>", { buf = 0 })
vim.keymap.set("n", "m<cr>", "<cmd>Tux c23 -o %:.:r %:.<cr>", { buf = 0 })
```

## Commands

```vim
:Tux just test
:Tuxpane just test
:Tuxwindow just test
:Tuxpopup just test
```

- `:Tux` uses the configured default strategy.
- `:Tuxpane` sends the command to a tmux pane.
- `:Tuxwindow` runs the command in a new tmux window.
- `:Tuxpopup` runs the command in a tmux popup.

`:Tux` also accepts a range. With no command arguments, the selected text is
pasted literally into the target tmux pane:

```vim
:.Tux
:'<,'>Tux
```

## API

```lua
local tux = require("tux")

tux.run(command)
tux.run_range(line1, line2, opts)
tux.pane(command, opts)
tux.window(command, opts)
tux.popup(command, opts)
```

Examples:

```lua
tux.pane("just test")

tux.window("evcxr", {
  name = "evcxr",
  select = true,
})

tux.popup("just run", {
  title = "just run",
  auto_close = "success",
})
```

## Configuration

```lua
require("tux").setup({
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
  window = {
    detached = false,
    name = nil,
    select = false,
  },
})
```

Pane options:

- `orientation`: `"horizontal"` or `"vertical"`.
- `size`: pane size as a percentage.
- `target`: tmux target pane. The default targets the last pane in the current
  window.

Popup options:

- `auto_close`: `"off"`, `"on"`, or `"success"`.
- `width` / `height`: tmux popup dimensions.
- `border`: tmux popup border style.
- `title`: optional popup title.

Window options:

- `detached`: create the window without selecting it.
- `name`: window name.
- `select`: if a window with `name` exists, select it instead of creating a new
  one.

## vim-test

Tux works well as a [vim-test](https://github.com/vim-test/vim-test) strategy:

```vim
function! TuxStrategy(cmd)
  execute 'Tux ' . a:cmd
endfunction

let g:test#custom_strategies = {
      \ 'tux': function('TuxStrategy'),
      \}

let g:test#strategy = 'tux'
```

## Requirements

- Neovim 0.10 or newer
- tmux

Tux only runs inside a tmux session. If `$TMUX` is not set, commands will warn
and return without running.
