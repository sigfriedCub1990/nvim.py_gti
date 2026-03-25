-- lua/py_gti/config.lua
-- Default configuration and merge logic.

local M = {}

M.defaults = {
  default_keymap = "<leader>gi",
  respect_gitignore = true,
  max_filesize = 1024 * 1024, -- 1 MB
  picker = "quickfix",        -- "quickfix" | "fzf-lua"
}

---@param opts table|nil User-supplied options
---@return table Merged configuration
function M.resolve(opts)
  return vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
