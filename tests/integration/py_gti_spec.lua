-- tests/integration/py_gti_spec.lua
-- Full pipeline integration test: context → finder → parser → quickfix

local FIXTURES = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h") .. "/fixtures"

--- Load abc_simple.py into a real buffer, place cursor on abstract method.
local function open_fixture(filename, row, col)
  local path = FIXTURES .. "/" .. filename
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_cursor(0, { row, col })
  return bufnr
end

describe("PyGTI integration", function()
  after_each(function()
    -- Clean up quickfix and buffers between tests
    vim.fn.setqflist({}, "r", { title = "", items = {} })
    vim.cmd("cclose")
    vim.cmd("silent! %bwipeout!")
  end)

  it("populates quickfix for speak() in abc_simple.py", function()
    open_fixture("abc_simple.py", 7, 4) -- cursor on "def speak"

    -- Run the full pipeline directly (not via :PyGTI to avoid keymap side-effects)
    local py_gti = require("py_gti")
    py_gti.goto_implementations()

    local qf = vim.fn.getqflist({ title = true, items = true })

    -- Title should mention Animal.speak
    assert.matches("Animal%.speak", qf.title)

    -- Should find at least impl_single.py (Dog.speak) and impl_multiple.py (Cat, Bird)
    assert.is_true(#qf.items >= 3, "expected >=3 implementations, got " .. #qf.items)

    -- None of the results should come from non_impl.py
    for _, item in ipairs(qf.items) do
      local fname = vim.fn.bufname(item.bufnr)
      assert.is_false(fname:match("non_impl%.py") ~= nil, "non_impl.py must not appear")
    end
  end)

  it("populates quickfix for find() in impl_multi_base.py (Generic + abc.ABC, multi-line def)", function()
    open_fixture("impl_multi_base.py", 10, 4) -- cursor on "def find("

    local py_gti = require("py_gti")
    py_gti.goto_implementations()

    local qf = vim.fn.getqflist({ title = true, items = true })

    -- Title should mention BusinessOfferRepository.find
    assert.matches("BusinessOfferRepository%.find", qf.title)

    -- Should find at least SqlBusinessOfferRepository and CachedBusinessOfferRepository
    -- (other fixtures in the project may contribute additional results)
    assert.is_true(#qf.items >= 2, "expected >=2 implementations, got " .. #qf.items)

    -- At least one result must come from impl_multi_base.py
    local found_fixture = false
    for _, item in ipairs(qf.items) do
      if vim.fn.bufname(item.bufnr):match("impl_multi_base%.py") then
        found_fixture = true
        break
      end
    end
    assert.is_true(found_fixture, "expected a result from impl_multi_base.py")
  end)

  it("shows a warning on a non-abstract method", function()
    open_fixture("abc_simple.py", 16, 4) -- cursor on "def breathe" (not abstract)

    local notified = false
    local orig = vim.notify
    vim.notify = function(msg, level)
      if level == vim.log.levels.WARN then
        notified = true
      end
      orig(msg, level)
    end

    require("py_gti").goto_implementations()

    vim.notify = orig

    assert.is_true(notified, "expected a WARN notification for non-abstract method")
  end)

  it("jumps directly when there is exactly one implementation", function()
    open_fixture("abc_unique.py", 7, 4) -- cursor on "def unique_method"

    require("py_gti").goto_implementations()

    -- Should have jumped directly: current buffer is impl_unique.py
    local bufname = vim.api.nvim_buf_get_name(0)
    assert.matches("impl_unique%.py", bufname)

    -- Quickfix should NOT have been populated
    local qf = vim.fn.getqflist({ items = true })
    assert.is_true(#qf.items == 0, "quickfix should be empty for single-result direct jump")

    -- Cursor must land on 'd' of 'def' (0-based col 4 for 4-space indent)
    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.equals(4, cursor[2], "cursor column should be 0-based 4 (first char of 'def')")
  end)

  it(":PyGTI command is registered", function()
    local cmds = vim.api.nvim_get_commands({})
    assert.is_not_nil(cmds["PyGTI"])
  end)
end)
