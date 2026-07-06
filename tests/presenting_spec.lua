local MiniTest = _G.MiniTest
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[
        package.loaded["presenting"] = nil
        _G.treesitter_start_calls = {}
        vim.treesitter.start = function(buf, parser)
          table.insert(_G.treesitter_start_calls, { buf = buf, parser = parser })
        end
      ]])
    end,
    post_once = function() child.stop() end,
  },
})

T["syntax_highlighting"] = MiniTest.new_set()

T["syntax_highlighting"]["starts treesitter for slide buffer when enabled"] = function()
  child.lua([[
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "# Slide",
      "",
      "```lua",
      "local answer = 42",
      "```",
    })
    vim.bo.filetype = "markdown"

    require("presenting").setup({
      syntax_highlighting = {
        enabled = true,
        parser = "markdown",
      },
    })

    vim.cmd("Presenting")
  ]])

  MiniTest.expect.equality(child.lua_get("#_G.treesitter_start_calls"), 1)
  MiniTest.expect.equality(child.lua_get("_G.treesitter_start_calls[1].parser"), "markdown")
end

T["syntax_highlighting"]["applies syntax highlighting inside ruby fenced blocks"] = function()
  child.lua([[
    package.loaded["presenting"] = nil

    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "# Slide",
      "",
      "```ruby",
      "plugin :oplog, primary_key: :measure_sid",
      "```",
    })
    vim.bo.filetype = "markdown"

    require("presenting").setup({
      syntax_highlighting = {
        enabled = true,
        parser = "markdown",
      },
    })

    vim.cmd("Presenting")
    vim.cmd("redraw")

    local slide_buf = require("presenting")._state.slide_buf
    local syntax = vim.inspect_pos(slide_buf, 3, 0).syntax
    _G.has_ruby_syntax = vim.iter(syntax):any(function(item)
      return item.hl_group == "PresentingRubyCode"
    end)
  ]])

  MiniTest.expect.equality(child.lua_get("_G.has_ruby_syntax"), true)
end

return T
