# nvim.py_gti

Jump to every concrete implementation of a Python abstract method — straight from your cursor.

Place your cursor on any `@abstractmethod` inside an ABC class and run `:PyGTI`. The plugin scans your project, finds all classes that implement that method, and sends them to the quickfix list (or an fzf-lua picker) so you can navigate there instantly.

---

## Features

- Detects abstract methods decorated with `@abstractmethod` or `@abc.abstractmethod`
- Handles all common ABC inheritance styles:
  - `class Foo(ABC):`
  - `class Foo(abc.ABC):`
  - `class Foo(Generic[T], abc.ABC):` — multiple bases, generics included
- Finds concrete implementations even when they inherit with a type parameter filled in: `class SqlRepo(Repo[ConcreteType]):`
- Works with multi-line method signatures — cursor can be on the `def` line or any parameter line
- Respects `.gitignore` when scanning for Python files
- Two display modes: native quickfix list or **fzf-lua** (with live file preview)

---

## Requirements

- Neovim ≥ 0.10
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) with the Python parser installed
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- _(optional)_ [fzf-lua](https://github.com/ibhagwan/fzf-lua) for the fuzzy-picker display mode

---

## Installation

### lazy.nvim

```lua
{
    "sigfriedCub1990/nvim.py_gti",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-lua/plenary.nvim",
    },
    opts = {},
}
```

With fzf-lua as the picker:

```lua
{
    "sigfriedCub1990/nvim.py_gti",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-lua/plenary.nvim",
        "ibhagwan/fzf-lua",
    },
    opts = {
        picker = "fzf-lua",
    },
}
```

---

## Usage

1. Open a Python file and place your cursor on an abstract method:

```python
class BusinessOfferRepository(Generic[OfferType], abc.ABC):

    @abc.abstractmethod
    def find(self, center_code: str) -> OfferType: ...
#   ^ cursor anywhere here
```

2. Run `:PyGTI` or press `<leader>gi` (default keymap).

3. Every class in your project that implements `find` opens in the quickfix list (or fzf-lua picker). Press `<CR>` to jump.

---

## Configuration

Pass options to `setup()` (or via `opts` in lazy.nvim):

```lua
require("py_gti").setup({
    -- Keymap to trigger :PyGTI. Set to "" to disable.
    default_keymap = "<leader>gi",

    -- Skip files listed in .gitignore when scanning the project.
    respect_gitignore = true,

    -- Skip files larger than this size (bytes).
    max_filesize = 1024 * 1024, -- 1 MB

    -- Display mode: "quickfix" (default) or "fzf-lua".
    picker = "quickfix",
})
```

### Picker: fzf-lua

When `picker = "fzf-lua"`, results open in an fzf-lua window with:

- Syntax-highlighted file preview
- `<CR>` to open, `<C-s>` to open in a horizontal split, `<C-v>` for vertical split

If fzf-lua is not installed the plugin falls back to quickfix automatically.

---

## How it works

1. **Context detection** — tree-sitter parses the current buffer and identifies the abstract method and its enclosing ABC class under the cursor.
2. **File discovery** — walks upward from the current file to find the project root (`.git`, `pyproject.toml`, or `setup.py`), then enumerates all `.py` files.
3. **Implementation search** — each file is parsed in-memory with tree-sitter (no buffers opened) to find classes that inherit from the ABC and define the method.
4. **Display** — results are sent to the quickfix list or fzf-lua picker.

---

## Running the tests

```bash
make docker-test
```

Requires Docker. The image bundles the correct Neovim version, nvim-treesitter, and plenary so tests run the same way everywhere.