-- lua/py_gti/health.lua
-- :checkhealth py_gti

local M = {}

function M.check()
  vim.health.start("py_gti")

  -- Neovim version
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.error("Neovim >= 0.10 is required")
  end

  -- Python tree-sitter parser
  local ok_parser = pcall(vim.treesitter.language.inspect, "python")
  if ok_parser then
    vim.health.ok("Python tree-sitter parser is available")
  else
    vim.health.error(
      "Python tree-sitter parser not found",
      { "Run :TSInstall python" }
    )
  end

  -- plenary.nvim (required for file scanning)
  local ok_plenary = pcall(require, "plenary.scandir")
  if ok_plenary then
    vim.health.ok("plenary.nvim found")
  else
    vim.health.warn(
      "plenary.nvim not found — file scanning will fall back to vim.fs.find",
      { "Install nvim-lua/plenary.nvim" }
    )
  end

  -- fzf-lua (optional)
  local ok_fzf = pcall(require, "fzf-lua")
  if ok_fzf then
    vim.health.ok("fzf-lua found (picker = \"fzf-lua\" available)")
  else
    vim.health.warn(
      "fzf-lua not found — only the quickfix picker is available",
      { "Install ibhagwan/fzf-lua to enable picker = \"fzf-lua\"" }
    )
  end
end

return M