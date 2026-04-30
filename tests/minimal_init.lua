-- tests/minimal_init.lua
-- Self-contained Neovim init for headless test runs.
-- Clones plenary.nvim and nvim-treesitter into /tmp/nvim-test-deps/ on first
-- run; subsequent runs (and CI cache hits) skip the clone entirely.

local DEPS_DIR = "/tmp/nvim-test-deps"

local DEPS = {
  {
    name = "plenary.nvim",
    url  = "https://github.com/nvim-lua/plenary.nvim.git",
  },
  {
    name = "nvim-treesitter",
    url  = "https://github.com/nvim-treesitter/nvim-treesitter.git",
  },
}

-- Ensure the deps root exists.
if vim.fn.isdirectory(DEPS_DIR) == 0 then
  vim.fn.mkdir(DEPS_DIR, "p")
end

-- Clone a dep if its directory is absent.
local function ensure_dep(dep)
  local dest = DEPS_DIR .. "/" .. dep.name
  if vim.fn.isdirectory(dest) == 1 then
    return
  end
  vim.notify("[minimal_init] cloning " .. dep.name .. " ...", vim.log.levels.INFO)
  local out = vim.fn.system({
    "git", "clone",
    "--depth", "1",
    "--single-branch",
    dep.url,
    dest,
  })
  if vim.v.shell_error ~= 0 then
    error("[minimal_init] failed to clone " .. dep.name .. ":\n" .. out)
  end
end

for _, dep in ipairs(DEPS) do
  ensure_dep(dep)
end

-- Prepend deps and the plugin itself onto rtp.
for _, dep in ipairs(DEPS) do
  vim.opt.rtp:prepend(DEPS_DIR .. "/" .. dep.name)
end

-- Resolve plugin root (parent of this file's directory: tests/../)
local plugin_root = vim.fn.fnamemodify(
  debug.getinfo(1, "S").source:sub(2), ":h:h"
)
vim.opt.rtp:prepend(plugin_root)

-- Source all plugin/*.vim and plugin/*.lua files from every rtp entry.
-- This is required because --noplugin skips them, so commands like
-- PlenaryBustedDirectory and TSInstall would otherwise never be registered.
vim.cmd("runtime! plugin/**/*.vim")
vim.cmd("runtime! plugin/**/*.lua")

-- Verify the Python tree-sitter parser is available (pre-compiled into the
-- nvim-treesitter dep dir by the Dockerfile; errors are surfaced per-test).
local has_parser = pcall(vim.treesitter.language.inspect, "python")
if not has_parser then
  vim.notify(
    "[minimal_init] python tree-sitter parser not found — rebuild the Docker image",
    vim.log.levels.ERROR
  )
end
