# CLAUDE.md

## Project: nvim.py_gti

A Neovim plugin that finds all concrete implementations of an abstract Python method (ABC) and populates the quickfix list.

## Structure

```
plugin/py_gti.lua       -- registers :PyGTI command
lua/py_gti/
  init.lua              -- setup(opts), goto_implementations() orchestration
  config.lua            -- default opts + tbl_deep_extend merge
  context.lua           -- tree-sitter: detect abstract method at cursor
  finder.lua            -- enumerate .py files (plenary.scandir / vim.fs.find)
  parser.lua            -- parse .py files via get_string_parser, find implementations
  quickfix.lua          -- populate + open quickfix list
  util.lua              -- node_text, safe_read, notify helpers
tests/
  minimal_init.lua      -- bootstrap rtp for headless test runner
  fixtures/             -- Python fixture files
  unit/                 -- unit specs per module
  integration/          -- full pipeline spec
```

## Dependencies

- **nvim-treesitter** — Python parser (required for `get_string_parser`)
- **plenary.nvim** — `plenary.scandir` for file enumeration (falls back to `vim.fs.find`)

## Running Tests

```bash
nvim --headless -u tests/minimal_init.lua \
  +"PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}" +qa
```

## Workflow

- **Test before fix**: always write the failing test(s) first, confirm they fail, then implement the fix.

## Key Design Notes

- **No buffer overhead**: arbitrary `.py` files are parsed via `vim.treesitter.get_string_parser(source, "python")`.
- **Dynamic filtering in Lua**: class/method name matching happens after `iter_matches`, not via `#eq?` predicates.
- **Project root detection**: walks upward from current buffer for `.git`, `pyproject.toml`, or `setup.py`.
