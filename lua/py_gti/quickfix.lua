-- lua/py_gti/quickfix.lua
-- Populates and opens the quickfix list with implementation results.

local M = {}

---Populate the quickfix list and open it.
---@param items table[]  List of { filename, lnum, col, text }
---@param class_name string
---@param method_name string
function M.populate(items, class_name, method_name)
  local title = string.format("PyGTI: %s.%s (%d)", class_name, method_name, #items)

  vim.fn.setqflist({}, "r", {
    title = title,
    items = items,
  })

  vim.cmd("copen")
end

return M
