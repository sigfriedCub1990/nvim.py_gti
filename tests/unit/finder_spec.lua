-- tests/unit/finder_spec.lua
-- Unit tests for lua/py_gti/finder.lua

local finder = require("py_gti.finder")

local FIXTURES = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h") .. "/fixtures"
local PLUGIN_ROOT = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")

describe("finder.find_root", function()
  it("returns the plugin root when starting from fixtures dir (has .git)", function()
    local root = finder.find_root(FIXTURES .. "/abc_simple.py")
    -- The plugin repo has a .git or at least the test should find something upward
    assert.is_not_nil(root)
    assert.is_true(type(root) == "string")
    assert.is_true(#root > 0)
  end)
end)

describe("finder.get_python_files", function()
  it("finds all .py fixtures", function()
    local files = finder.get_python_files(FIXTURES, {})
    assert.is_true(#files >= 5, "expected at least 5 fixture files, got " .. #files)

    local names = {}
    for _, f in ipairs(files) do
      names[vim.fn.fnamemodify(f, ":t")] = true
    end

    assert.is_true(names["abc_simple.py"] == true)
    assert.is_true(names["abc_meta.py"] == true)
    assert.is_true(names["impl_single.py"] == true)
    assert.is_true(names["impl_multiple.py"] == true)
    assert.is_true(names["non_impl.py"] == true)
  end)

  it("returns only .py files (no .lua files)", function()
    local files = finder.get_python_files(PLUGIN_ROOT, {})
    for _, f in ipairs(files) do
      assert.matches("%.py$", f)
    end
  end)
end)
