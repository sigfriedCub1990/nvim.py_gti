-- lua/py_gti/init.lua
-- Public API: setup() and goto_implementations() orchestration.

local M = {}

local _config = nil

---Configure the plugin. Call this from your Neovim config.
---@param opts table|nil
function M.setup(opts)
  _config = require("py_gti.config").resolve(opts)

  if _config.default_keymap and _config.default_keymap ~= "" then
    vim.keymap.set("n", _config.default_keymap, function()
      M.goto_implementations()
    end, { desc = "PyGTI: find abstract method implementations", silent = true })
  end
end

---Main entry point: detect abstract method at cursor, scan project, populate quickfix.
function M.goto_implementations()
  local cfg = _config or require("py_gti.config").resolve()
  local util = require("py_gti.util")
  local context = require("py_gti.context")
  local finder = require("py_gti.finder")
  local parser = require("py_gti.parser")
  local quickfix = require("py_gti.quickfix")

  -- 1. Detect abstract method at cursor
  local method_name, class_name_or_err = context.get_abstract_method()
  if not method_name then
    util.notify(class_name_or_err or "not on an abstract method", vim.log.levels.WARN)
    return
  end
  local class_name = class_name_or_err

  -- 2. Find project root and enumerate Python files
  local buf_path = vim.api.nvim_buf_get_name(0)
  if buf_path == "" then
    buf_path = vim.fn.getcwd()
  end
  local root = finder.find_root(buf_path)

  local files = finder.get_python_files(root, cfg)
  if #files == 0 then
    util.notify("no Python files found under " .. root, vim.log.levels.WARN)
    return
  end

  -- 3. Search each file for implementations
  local all_results = {}
  for _, filepath in ipairs(files) do
    local results = parser.find_implementations(filepath, class_name, method_name, cfg.max_filesize)
    for _, r in ipairs(results) do
      table.insert(all_results, r)
    end
  end

  -- 4. Report results
  if #all_results == 0 then
    util.notify(
      string.format("no implementations of %s.%s found", class_name, method_name),
      vim.log.levels.INFO
    )
    return
  end

  quickfix.populate(all_results, class_name, method_name)
end

return M
