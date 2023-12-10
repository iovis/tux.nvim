local tux = require("tux")
local assert = require("luassert")

describe("tux.parse", function()
  it("generates a tmux command", function()
    assert.are.same(tux.parse("ls"), [[tmux send -t {last} 'ls' Enter]])
  end)
end)
