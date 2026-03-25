-- plugin/py_gti.lua
-- Registers the :PyGTI user command. Lazy-requires the plugin core on first use.

if vim.g.loaded_py_gti then
  return
end
vim.g.loaded_py_gti = true

vim.api.nvim_create_user_command("PyGTI", function()
  require("py_gti").goto_implementations()
end, { desc = "Find implementations of the abstract method under cursor" })
