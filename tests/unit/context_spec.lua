-- tests/unit/context_spec.lua
-- Unit tests for lua/py_gti/context.lua

local context = require("py_gti.context")

--- Helper: create a scratch buffer with given lines, set cursor, return bufnr.
local function make_buf(lines, row, col)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "python")
  -- Set this buffer as current in a floating window so win_get_cursor works
  local win = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = 80,
    height = 30,
    row = 0,
    col = 0,
    style = "minimal",
  })
  vim.api.nvim_win_set_cursor(win, { row, col })
  return bufnr, win
end

local function cleanup(bufnr, win)
  pcall(vim.api.nvim_win_close, win, true)
  pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
end

describe("context.get_abstract_method", function()
  it("detects bare @abstractmethod", function()
    local lines = {
      "from abc import ABC, abstractmethod",
      "",
      "class MyABC(ABC):",
      "    @abstractmethod",
      "    def my_method(self):",
      "        pass",
    }
    -- Place cursor on the def line (row 5, col 4)
    local bufnr, win = make_buf(lines, 5, 4)

    local method, class = context.get_abstract_method()

    cleanup(bufnr, win)

    assert.equals("my_method", method)
    assert.equals("MyABC", class)
  end)

  it("detects @abc.abstractmethod (dotted form)", function()
    local lines = {
      "import abc",
      "",
      "class MyABC(ABC):",
      "    @abc.abstractmethod",
      "    def dotted_method(self):",
      "        pass",
    }
    local bufnr, win = make_buf(lines, 5, 4)

    local method, class = context.get_abstract_method()

    cleanup(bufnr, win)

    assert.equals("dotted_method", method)
    assert.equals("MyABC", class)
  end)

  it("returns nil when cursor is on a non-abstract method", function()
    local lines = {
      "from abc import ABC, abstractmethod",
      "",
      "class MyABC(ABC):",
      "    def regular(self):",
      "        pass",
    }
    local bufnr, win = make_buf(lines, 4, 4)

    local method, err = context.get_abstract_method()

    cleanup(bufnr, win)

    assert.is_nil(method)
    assert.is_not_nil(err)
  end)

  it("returns nil when class does not inherit from ABC", function()
    local lines = {
      "from abc import abstractmethod",
      "",
      "class NotABC:",
      "    @abstractmethod",
      "    def my_method(self):",
      "        pass",
    }
    local bufnr, win = make_buf(lines, 5, 4)

    local method, err = context.get_abstract_method()

    cleanup(bufnr, win)

    assert.is_nil(method)
    assert.is_not_nil(err)
  end)
end)
