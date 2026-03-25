-- lua/py_gti/context.lua
-- Detects the abstract method under the cursor using tree-sitter.

local util = require("py_gti.util")

local M = {}

-- Query: find decorated function definitions with @abstractmethod
-- Captures the decorator and the function name.
local ABSTRACT_QUERY_SRC = [[
(decorated_definition
  (decorator
    (identifier) @dec)
  (function_definition
    name: (identifier) @method_name)) @abs_fn

(decorated_definition
  (decorator
    (attribute
      object: (identifier) @mod
      attribute: (identifier) @attr))
  (function_definition
    name: (identifier) @method_name2)) @abs_fn2
]]

-- Query: find class definitions that inherit from ABC or ABCMeta (bare or dotted abc.ABC)
local CLASS_QUERY_SRC = [[
(class_definition
  name: (identifier) @class_name
  superclasses: (argument_list
    (identifier) @base)) @cls

(class_definition
  name: (identifier) @class_name2
  superclasses: (argument_list
    (attribute
      object: (identifier) @mod
      attribute: (identifier) @base_attr))) @cls2
]]

---Return the source string for the current buffer.
---@return string
local function buf_source()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

---Find the smallest node range that fully contains (row, col).
---@param node TSNode
---@param row integer 0-based
---@param col integer 0-based
---@return boolean
local function node_contains(node, row, col)
  local sr, sc, er, ec = node:range()
  if row < sr or row > er then
    return false
  end
  if row == sr and col < sc then
    return false
  end
  if row == er and col > ec then
    return false
  end
  return true
end

---Get the abstract method name and its enclosing ABC class name at the cursor.
---@return string|nil method_name
---@return string|nil class_name_or_error  class name on success, error message on failure
function M.get_abstract_method()
  local bufnr = vim.api.nvim_get_current_buf()
  local lang = "python"

  local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok_parser or not parser then
    return nil, "no tree-sitter parser available for Python"
  end

  local tree = parser:parse()[1]
  if not tree then
    return nil, "failed to parse buffer"
  end

  local root = tree:root()
  local source = buf_source()
  local cursor = vim.api.nvim_win_get_cursor(0) -- 1-based {row, col}
  local cur_row = cursor[1] - 1 -- 0-based
  local cur_col = cursor[2]

  -- Step 1: find abstract method node under cursor
  local ok_aq, abs_query = pcall(vim.treesitter.query.parse, lang, ABSTRACT_QUERY_SRC)
  if not ok_aq then
    return nil, "failed to parse abstract method query: " .. tostring(abs_query)
  end

  local method_name = nil
  local abs_fn_node = nil

  for pattern, match, _ in abs_query:iter_matches(root, source, 0, -1) do
    -- Determine which pattern matched (1 = bare @dec, 2 = dotted @mod.@attr)
    local captures = abs_query.captures
    local capture_map = {}
    for cap_idx, node in pairs(match) do
      -- iter_matches can return arrays; unwrap single-node arrays
      local n = node
      if type(node) == "table" then
        n = node[1]
      end
      capture_map[captures[cap_idx]] = n
    end

    local abs_node = capture_map["abs_fn"] or capture_map["abs_fn2"]
    if not abs_node then
      goto continue_abs
    end

    -- Check if this decorated_definition contains the cursor
    if not node_contains(abs_node, cur_row, cur_col) then
      goto continue_abs
    end

    -- Pattern 1: bare @abstractmethod
    if capture_map["dec"] then
      local dec_text = util.node_text(capture_map["dec"], source)
      if dec_text == "abstractmethod" and capture_map["method_name"] then
        method_name = util.node_text(capture_map["method_name"], source)
        abs_fn_node = abs_node
        break
      end
    end

    -- Pattern 2: @abc.abstractmethod
    if capture_map["attr"] then
      local attr_text = util.node_text(capture_map["attr"], source)
      if attr_text == "abstractmethod" and capture_map["method_name2"] then
        method_name = util.node_text(capture_map["method_name2"], source)
        abs_fn_node = abs_node
        break
      end
    end

    ::continue_abs::
  end

  if not method_name then
    return nil, "cursor is not on an abstract method"
  end

  -- Step 2: find enclosing ABC/ABCMeta class
  local ok_cq, class_query = pcall(vim.treesitter.query.parse, lang, CLASS_QUERY_SRC)
  if not ok_cq then
    return nil, "failed to parse class query: " .. tostring(class_query)
  end

  local abs_sr, abs_sc, abs_er, abs_ec = abs_fn_node:range()

  for _, match, _ in class_query:iter_matches(root, source, 0, -1) do
    local captures = class_query.captures
    local capture_map = {}
    for cap_idx, node in pairs(match) do
      local n = node
      if type(node) == "table" then
        n = node[1]
      end
      capture_map[captures[cap_idx]] = n
    end

    local cls_node = capture_map["cls"] or capture_map["cls2"]
    local class_name_node = capture_map["class_name"] or capture_map["class_name2"]

    if not cls_node or not class_name_node then
      goto continue_cls
    end

    -- Pattern 1: bare ABC/ABCMeta; Pattern 2: dotted abc.ABC / abc.ABCMeta
    local base_text = capture_map["base"] and util.node_text(capture_map["base"], source)
      or capture_map["base_attr"] and util.node_text(capture_map["base_attr"], source)
    if base_text ~= "ABC" and base_text ~= "ABCMeta" then
      goto continue_cls
    end

    -- Check that the abstract method is inside this class
    local csr, csc, cer, cec = cls_node:range()
    local method_inside = (abs_sr > csr or (abs_sr == csr and abs_sc >= csc))
      and (abs_er < cer or (abs_er == cer and abs_ec <= cec))

    if method_inside then
      return method_name, util.node_text(class_name_node, source)
    end

    ::continue_cls::
  end

  return nil, "method is not inside an ABC/ABCMeta class"
end

return M
