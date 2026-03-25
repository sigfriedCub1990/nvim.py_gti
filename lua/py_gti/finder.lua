-- lua/py_gti/finder.lua
-- Enumerates Python files in the project, rooted at the nearest .git/pyproject.toml/setup.py.

local M = {}

---Walk upward from `start_path` to find the project root.
---@param start_path string  Absolute path to start from (file or directory)
---@return string  Absolute path to the project root (or start_path's dir if none found)
function M.find_root(start_path)
  local dir = vim.fn.fnamemodify(start_path, ":h")
  local markers = { ".git", "pyproject.toml", "setup.py", "setup.cfg" }
  local found = vim.fs.find(markers, { upward = true, path = dir })
  if found and #found > 0 then
    return vim.fn.fnamemodify(found[1], ":h")
  end
  return dir
end

---Return a list of absolute paths to all .py files under `root`.
---Tries plenary.scandir first, falls back to vim.fs.find.
---@param root string
---@param opts table  Plugin config (respect_gitignore, max_filesize)
---@return string[]
function M.get_python_files(root, opts)
  opts = opts or {}

  -- Primary: plenary.scandir
  local ok_plenary, scandir = pcall(require, "plenary.scandir")
  if ok_plenary and scandir then
    local files = scandir.scan_dir(root, {
      search_pattern = "%.py$",
      respect_gitignore = opts.respect_gitignore ~= false,
      silent = true,
      add_dirs = false,
    })
    return files or {}
  end

  -- Fallback: vim.fs.find with predicate (nvim 0.10+)
  local results = {}
  local ok_find, found = pcall(vim.fs.find, function(name, _path)
    return name:match("%.py$") ~= nil
  end, {
    path = root,
    type = "file",
    limit = math.huge,
  })

  if ok_find and type(found) == "table" then
    results = found
  end

  return results
end

return M
