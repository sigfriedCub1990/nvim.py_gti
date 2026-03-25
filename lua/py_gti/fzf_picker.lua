-- lua/py_gti/fzf_picker.lua
-- Displays implementations in an fzf-lua picker with live preview.

local M = {}

---Show implementations in fzf-lua. Falls back to quickfix if fzf-lua is absent.
---@param items table[]  List of { filename, lnum, col, text }
---@param class_name string
---@param method_name string
function M.show(items, class_name, method_name)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[py_gti] fzf-lua not available, falling back to quickfix", vim.log.levels.WARN)
    require("py_gti.quickfix").populate(items, class_name, method_name)
    return
  end

  local entries = {}
  for _, item in ipairs(items) do
    -- Standard grep-style format fzf-lua recognises for file jumping
    table.insert(entries, string.format("%s:%d:%d: %s", item.filename, item.lnum, item.col, item.text))
  end

  fzf.fzf_exec(entries, {
    prompt    = string.format("PyGTI %s.%s> ", class_name, method_name),
    previewer = "builtin",
    actions   = fzf.defaults.actions.files,
  })
end

return M
