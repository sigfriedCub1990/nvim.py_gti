-- tests/unit/quickfix_spec.lua
-- Unit tests for lua/py_gti/quickfix.lua

local quickfix = require("py_gti.quickfix")

describe("quickfix.populate", function()
  it("sets quickfix list with correct title and items", function()
    local items = {
      { filename = "/a/b/impl.py", lnum = 10, col = 1, text = "    def speak(self):" },
      { filename = "/a/b/impl2.py", lnum = 20, col = 1, text = "    def speak(self):" },
    }

    quickfix.populate(items, "Animal", "speak")

    local qf = vim.fn.getqflist({ title = true, items = true })
    assert.equals("PyGTI: Animal.speak (2)", qf.title)
    assert.equals(2, #qf.items)

    -- copen opens a window; just verify no error was thrown (already done by pcall above)
    -- Close the quickfix window to leave a clean state
    vim.cmd("cclose")
  end)

  it("works with zero items", function()
    quickfix.populate({}, "Animal", "speak")
    local qf = vim.fn.getqflist({ title = true, items = true })
    assert.equals("PyGTI: Animal.speak (0)", qf.title)
    assert.equals(0, #qf.items)
    vim.cmd("cclose")
  end)
end)
