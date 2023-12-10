local tux = require("tux")
local assert = require("luassert")

describe("tux.send_keys", function()
  it("generates the right command", function()
    assert.are.same(tux.send_keys("ls", "{last}"), [[silent !tmux send -t {last} 'ls' Enter]])

    assert.are.same(tux.send_keys("ls"), [[silent !tmux send 'ls' Enter]])
  end)
end)

describe("tux.window_command", function()
  it("generates the right command", function()
    assert.are.same(
      tux.window_command("cargo watch -x run", { detached = false, select = false, name = nil }),
      [[silent !tmux new-window 'cargo watch -x run']]
    )

    assert.are.same(
      tux.window_command("cargo watch -x run", { detached = true, select = false, name = nil }),
      [[silent !tmux new-window -d 'cargo watch -x run']]
    )

    assert.are.same(
      tux.window_command("htop", { detached = false, select = false, name = "htop" }),
      [[silent !tmux new-window -n 'htop' 'htop']]
    )

    assert.are.same(
      tux.window_command("htop", { detached = false, select = true, name = "htop" }),
      [[silent !tmux new-window -n 'htop' -S 'htop']]
    )
  end)
end)
