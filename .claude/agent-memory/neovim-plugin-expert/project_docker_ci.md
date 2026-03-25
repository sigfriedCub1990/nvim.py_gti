---
name: Docker CI setup
description: Key design decisions for the Docker-based test environment (Dockerfile, Makefile, workflow)
type: project
---

The project has a Docker-based test environment where the plugin source is bind-mounted at `/plugin` at runtime, not COPYed. The image bakes in: Neovim stable (tarball from GitHub releases), plenary.nvim and nvim-treesitter pre-cloned at `/tmp/nvim-test-deps/`, and the Python tree-sitter parser pre-compiled via `TSInstall! python` during `docker build`.

**Why:** Parser compilation requires gcc and network at build time; pre-compiling it into the image means test runs are fully offline and deterministic.

**How to apply:** If `minimal_init.lua` or the `Dockerfile` changes, the image must be rebuilt (the COPY of minimal_init.lua into the image at `/opt/nvim-build/tests/minimal_init.lua` is the layer that triggers TSInstall). The CI cache key is `hashFiles('Dockerfile', 'tests/minimal_init.lua')`.

The compiled parser lands at `/tmp/nvim-test-deps/nvim-treesitter/parser/python.so` — already on the rtp that minimal_init.lua sets up — so at test time `has_parser` is true and `TSInstall!` is a no-op.

CI caches the entire image as a tar via `docker save`/`docker load` + `actions/cache@v4`, avoiding BuildKit/buildx complexity.
