-- tests/unit/fzf_picker_spec.lua
-- Unit tests for lua/py_gti/fzf_picker.lua

local fzf_picker = require("py_gti.fzf_picker")

local ITEMS = {
  { filename = "/project/repo_a.py", lnum = 10, col = 5, text = "    def find(self, center_code):" },
  { filename = "/project/repo_b.py", lnum = 42, col = 5, text = "    def find(self, center_code):" },
}

local function stub_fzf(fzf_exec_fn)
  package.loaded["fzf-lua"] = {
    fzf_exec = fzf_exec_fn,
    defaults = { actions = { files = { default = "edit" } } },
  }
end

local function remove_fzf_stub()
  package.loaded["fzf-lua"] = nil
  -- Force fzf_picker to re-require fzf-lua on next call
  package.loaded["py_gti.fzf_picker"] = nil
end

describe("fzf_picker.show", function()
  after_each(function()
    remove_fzf_stub()
    -- Re-require so subsequent tests get a fresh module
    fzf_picker = require("py_gti.fzf_picker")
  end)

  it("calls fzf_exec with correctly formatted entries", function()
    local received_entries, received_opts

    stub_fzf(function(entries, opts)
      received_entries = entries
      received_opts = opts
    end)

    -- Reload module so it picks up the stub
    package.loaded["py_gti.fzf_picker"] = nil
    fzf_picker = require("py_gti.fzf_picker")

    fzf_picker.show(ITEMS, "BusinessOfferRepository", "find")

    assert.is_not_nil(received_entries)
    assert.equals(2, #received_entries)
    assert.equals("/project/repo_a.py:10:5:     def find(self, center_code):", received_entries[1])
    assert.equals("/project/repo_b.py:42:5:     def find(self, center_code):", received_entries[2])
  end)

  it("passes prompt and previewer options to fzf_exec", function()
    local received_opts

    stub_fzf(function(_, opts)
      received_opts = opts
    end)

    package.loaded["py_gti.fzf_picker"] = nil
    fzf_picker = require("py_gti.fzf_picker")

    fzf_picker.show(ITEMS, "MyRepo", "my_method")

    assert.is_not_nil(received_opts)
    assert.matches("MyRepo%.my_method", received_opts.prompt)
    assert.equals("builtin", received_opts.previewer)
    assert.is_not_nil(received_opts.actions)
  end)

  it("calls fzf_exec with empty table when items is empty", function()
    local received_entries

    stub_fzf(function(entries, _)
      received_entries = entries
    end)

    package.loaded["py_gti.fzf_picker"] = nil
    fzf_picker = require("py_gti.fzf_picker")

    fzf_picker.show({}, "Repo", "method")

    assert.is_not_nil(received_entries)
    assert.equals(0, #received_entries)
  end)

  it("falls back to quickfix and warns when fzf-lua is not installed", function()
    -- Ensure fzf-lua is not available
    package.loaded["fzf-lua"] = nil
    package.loaded["py_gti.fzf_picker"] = nil
    fzf_picker = require("py_gti.fzf_picker")

    local warned = false
    local orig_notify = vim.notify
    vim.notify = function(msg, level)
      if level == vim.log.levels.WARN and msg:match("fzf%-lua") then
        warned = true
      end
      orig_notify(msg, level)
    end

    -- Stub quickfix.populate to capture the call
    local qf = require("py_gti.quickfix")
    local orig_populate = qf.populate
    local qf_called = false
    qf.populate = function(items, cls, meth)
      qf_called = true
      orig_populate(items, cls, meth)
    end

    fzf_picker.show(ITEMS, "Repo", "find")

    vim.notify = orig_notify
    qf.populate = orig_populate

    assert.is_true(warned, "expected a WARN about fzf-lua not being available")
    assert.is_true(qf_called, "expected fallback to quickfix.populate")
  end)
end)
