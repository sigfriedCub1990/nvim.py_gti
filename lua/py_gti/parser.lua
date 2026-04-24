-- lua/py_gti/parser.lua
-- Parses arbitrary .py files (via get_string_parser) to find concrete implementations.

local util = require("py_gti.util")

local M = {}

-- Find subclasses of a given base class name.
-- Two patterns: plain identifier base and subscript (generic) base e.g. Repo[Type].
local SUBCLASS_QUERY_SRC = [[
(class_definition
  name: (identifier) @subclass_name
  superclasses: (argument_list
    (identifier) @base_name)) @subclass

(class_definition
  name: (identifier) @subclass_name2
  superclasses: (argument_list
    (subscript
      value: (identifier) @base_name2))) @subclass2
]]

-- Find method definitions by name within a subtree
local METHOD_QUERY_SRC = [[
(function_definition
  name: (identifier) @fn_name) @fn_def
]]

---Find all concrete implementations of `method_name` in subclasses of `class_name`
---within a single Python source file.
---@param filepath string  Absolute path to the .py file
---@param class_name string  The ABC class name to look for as a base
---@param method_name string  The abstract method name to find implementations of
---@param max_filesize integer  Skip files larger than this (bytes)
---@return table[]  List of { filename, lnum, col, text }
function M.find_implementations(filepath, class_name, method_name, max_filesize)
  max_filesize = max_filesize or (1024 * 1024)

  -- Size guard
  local stat = (vim.uv or vim.loop).fs_stat(filepath)
  if stat and stat.size > max_filesize then
    return {}
  end

  local source = util.safe_read(filepath)
  if not source or source == "" then
    return {}
  end

  local ok_parser, parser = pcall(vim.treesitter.get_string_parser, source, "python")
  if not ok_parser or not parser then
    return {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}
  end

  local root = tree:root()

  local ok_sq, subclass_query = pcall(vim.treesitter.query.parse, "python", SUBCLASS_QUERY_SRC)
  if not ok_sq then
    return {}
  end

  local ok_mq, method_query = pcall(vim.treesitter.query.parse, "python", METHOD_QUERY_SRC)
  if not ok_mq then
    return {}
  end

  local source_lines = vim.split(source, "\n", { plain = true })
  local results = {}

  -- Find all subclasses of class_name
  for _, match, _ in subclass_query:iter_matches(root, source, 0, -1) do
    local captures = subclass_query.captures
    local capture_map = {}
    for cap_idx, node in pairs(match) do
      local n = node
      if type(node) == "table" then
        n = node[1]
      end
      capture_map[captures[cap_idx]] = n
    end

    local subclass_node = capture_map["subclass"] or capture_map["subclass2"]
    local base_node = capture_map["base_name"] or capture_map["base_name2"]
    local subclass_name_node = capture_map["subclass_name"] or capture_map["subclass_name2"]

    if not subclass_node or not base_node or not subclass_name_node then
      goto continue_subclass
    end

    local base_text = util.node_text(base_node, source)
    if base_text ~= class_name then
      goto continue_subclass
    end

    -- Search for method_name within this subclass node
    for _, m_match, _ in method_query:iter_matches(subclass_node, source, 0, -1) do
      local m_captures = method_query.captures
      local m_capture_map = {}
      for cap_idx, node in pairs(m_match) do
        local n = node
        if type(node) == "table" then
          n = node[1]
        end
        m_capture_map[m_captures[cap_idx]] = n
      end

      local fn_name_node = m_capture_map["fn_name"]
      local fn_def_node = m_capture_map["fn_def"]

      if not fn_name_node or not fn_def_node then
        goto continue_method
      end

      local fn_text = util.node_text(fn_name_node, source)
      if fn_text ~= method_name then
        goto continue_method
      end

      -- Build quickfix entry
      local fn_row, fn_col = fn_def_node:range()
      local lnum = fn_row + 1 -- 1-based
      local line_text = source_lines[lnum] or ""

      table.insert(results, {
        filename = filepath,
        lnum = lnum,
        col = fn_col + 1, -- 1-based
        text = line_text,
      })

      ::continue_method::
    end

    ::continue_subclass::
  end

  return results
end

return M
