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

  it("detects @abc.abstractmethod in class(abc.ABC) — dotted superclass + dotted decorator", function()
    local lines = {
      "import abc",
      "",
      "class FlagRepo(abc.ABC):",
      "    @abc.abstractmethod",
      "    def is_active(self, flag_name) -> bool: ...",
    }
    local bufnr, win = make_buf(lines, 5, 4)

    local method, class = context.get_abstract_method()

    cleanup(bufnr, win)

    assert.equals("is_active", method)
    assert.equals("FlagRepo", class)
  end)

  it("detects bare @abstractmethod in class(abc.ABC) — dotted superclass, bare decorator", function()
    local lines = {
      "import abc",
      "from abc import abstractmethod",
      "",
      "class FlagRepo(abc.ABC):",
      "    @abstractmethod",
      "    def get_flags(self) -> list: ...",
    }
    local bufnr, win = make_buf(lines, 6, 4)

    local method, class = context.get_abstract_method()

    cleanup(bufnr, win)

    assert.equals("get_flags", method)
    assert.equals("FlagRepo", class)
  end)

  it("detects method in class with multiple bases including abc.ABC", function()
    local lines = {
      "import abc",
      "from typing import Generic, TypeVar",
      "OfferType = TypeVar('OfferType')",
      "",
      "class BusinessOfferRepository(Generic[OfferType], abc.ABC):",
      "    @abc.abstractmethod",
      "    def find(self, center_code: str) -> OfferType: ...",
    }
    local bufnr, win = make_buf(lines, 7, 4)

    local method, class = context.get_abstract_method()

    cleanup(bufnr, win)

    assert.equals("find", method)
    assert.equals("BusinessOfferRepository", class)
  end)

  it("detects multi-line abstract method, cursor on def line", function()
    local lines = {
      "import abc",
      "from typing import Generic, TypeVar",
      "OfferType = TypeVar('OfferType')",
      "",
      "class BusinessOfferRepository(Generic[OfferType], abc.ABC):",
      "    @abc.abstractmethod",
      "    def find(",
      "        self,",
      "        center_code: str,",
      "        service_date: str,",
      "    ) -> OfferType: ...",
    }
    local bufnr, win = make_buf(lines, 7, 4)

    local method, class = context.get_abstract_method()

    cleanup(bufnr, win)

    assert.equals("find", method)
    assert.equals("BusinessOfferRepository", class)
  end)

  it("detects multi-line abstract method, cursor on a parameter line", function()
    local lines = {
      "import abc",
      "from typing import Generic, TypeVar",
      "OfferType = TypeVar('OfferType')",
      "",
      "class BusinessOfferRepository(Generic[OfferType], abc.ABC):",
      "    @abc.abstractmethod",
      "    def find(",
      "        self,",
      "        center_code: str,",
      "        service_date: str,",
      "    ) -> OfferType: ...",
    }
    -- Cursor on the "center_code" parameter line
    local bufnr, win = make_buf(lines, 9, 8)

    local method, class = context.get_abstract_method()

    cleanup(bufnr, win)

    assert.equals("find", method)
    assert.equals("BusinessOfferRepository", class)
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
