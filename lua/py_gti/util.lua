-- lua/py_gti/util.lua
-- Shared helpers used across the plugin.

local M = {}

---Extract the text of a tree-sitter node from the source string.
---@param node TSNode
---@param source string  Raw file/buffer source
---@return string
function M.node_text(node, source)
  local start_row, start_col, end_row, end_col = node:range()
  if start_row == end_row then
    local line = vim.split(source, "\n", { plain = true })[start_row + 1] or ""
    return line:sub(start_col + 1, end_col)
  end
  local lines = vim.split(source, "\n", { plain = true })
  local result = {}
  for i = start_row + 1, end_row + 1 do
    local line = lines[i] or ""
    if i == start_row + 1 then
      table.insert(result, line:sub(start_col + 1))
    elseif i == end_row + 1 then
      table.insert(result, line:sub(1, end_col))
    else
      table.insert(result, line)
    end
  end
  return table.concat(result, "\n")
end

---Read a file from disk, returning its contents or nil on failure.
---@param path string
---@return string|nil
function M.safe_read(path)
  local ok, data = pcall(vim.fn.readfile, path)
  if not ok or type(data) ~= "table" then
    return nil
  end
  return table.concat(data, "\n")
end

---Show a notification using vim.notify.
---@param msg string
---@param level integer  vim.log.levels.* constant (default INFO)
function M.notify(msg, level)
  vim.notify("[py_gti] " .. msg, level or vim.log.levels.INFO)
end

return M
