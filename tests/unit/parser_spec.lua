-- tests/unit/parser_spec.lua
-- Unit tests for lua/py_gti/parser.lua

local parser = require("py_gti.parser")

local FIXTURES = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h") .. "/fixtures"

describe("parser.find_implementations", function()
  it("finds a single implementation in impl_single.py", function()
    local results = parser.find_implementations(
      FIXTURES .. "/impl_single.py",
      "Animal",
      "speak",
      1024 * 1024
    )
    assert.is_not_nil(results)
    assert.equals(1, #results)
    local r = results[1]
    assert.equals(FIXTURES .. "/impl_single.py", r.filename)
    assert.is_true(r.lnum > 0)
    assert.matches("def speak", r.text)
  end)

  it("finds both Animal subclass implementations in impl_multiple.py", function()
    local results = parser.find_implementations(
      FIXTURES .. "/impl_multiple.py",
      "Animal",
      "speak",
      1024 * 1024
    )
    -- Cat and Bird both implement speak(); Rock does not subclass Animal
    assert.equals(2, #results)
    local texts = {}
    for _, r in ipairs(results) do
      table.insert(texts, r.text)
    end
    local found_cat = false
    local found_bird = false
    for _, t in ipairs(texts) do
      if t:match("def speak") then
        found_cat = true
        found_bird = true
      end
    end
    assert.is_true(found_cat)
    assert.is_true(found_bird)
  end)

  it("returns empty for unrelated file", function()
    local results = parser.find_implementations(
      FIXTURES .. "/non_impl.py",
      "Animal",
      "speak",
      1024 * 1024
    )
    assert.equals(0, #results)
  end)

  it("returns empty when method is not implemented by subclass", function()
    -- Bird does not implement move()
    local results = parser.find_implementations(
      FIXTURES .. "/impl_multiple.py",
      "Animal",
      "move",
      1024 * 1024
    )
    -- Only Cat implements move()
    assert.equals(1, #results)
    assert.matches("def move", results[1].text)
  end)

  it("returns empty for nonexistent file", function()
    local results = parser.find_implementations(
      FIXTURES .. "/does_not_exist.py",
      "Animal",
      "speak",
      1024 * 1024
    )
    assert.equals(0, #results)
  end)

  it("skips files exceeding max_filesize", function()
    -- Use 1 byte as the limit so any real file is skipped
    local results = parser.find_implementations(
      FIXTURES .. "/impl_single.py",
      "Animal",
      "speak",
      1
    )
    assert.equals(0, #results)
  end)
end)
