# ---------------------------------------------------------------------------
# Dockerfile — reproducible test environment for nvim.py_gti
#
# Build:   docker build -t nvim-py-gti-test .
# Test:    docker run --rm -v $(pwd):/plugin -w /plugin nvim-py-gti-test make test
#
# The plugin source is mounted at runtime (/plugin), not copied in, so the
# image only needs to be rebuilt when Neovim, the deps, or this file changes.
# ---------------------------------------------------------------------------

FROM ubuntu:24.04

# ---------------------------------------------------------------------------
# 1. System packages
#    - curl/ca-certificates: download the Neovim tarball
#    - git:                  minimal_init.lua clones deps if absent; also needed
#                            by nvim-treesitter's install machinery
#    - gcc / libstdc++:      nvim-treesitter compiles parsers via the C path;
#                            libstdc++ is needed at runtime by the compiled .so
#    - make:                 Makefile targets are the test entrypoint
# ---------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      git \
      gcc \
      libc6-dev \
      libstdc++6 \
      make \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# 2. Install Neovim and the tree-sitter CLI.
#    Both tags are resolved at build time so the layer is stable and cacheable.
#    Override via: --build-arg NVIM_TAG=v0.10.4  or  --build-arg TS_TAG=v0.25.3
#    nvim-treesitter calls the tree-sitter CLI internally when compiling parsers.
# ---------------------------------------------------------------------------
ARG NVIM_TAG=v0.12.2
ARG TS_TAG=v0.25.3

RUN ARCH=$(uname -m) \
    && case "$ARCH" in \
         aarch64|arm64) NVIM_ARCH="arm64"; TS_ARCH="arm64" ;; \
         *) NVIM_ARCH="x86_64"; TS_ARCH="x64" ;; \
       esac \
    && curl -sSfL \
         "https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/nvim-linux-${NVIM_ARCH}.tar.gz" \
         -o /tmp/nvim.tar.gz \
    && tar -C /usr/local --strip-components=1 -xzf /tmp/nvim.tar.gz \
    && rm /tmp/nvim.tar.gz \
    && nvim --version \
    && curl -sSfL \
         "https://github.com/tree-sitter/tree-sitter/releases/download/${TS_TAG}/tree-sitter-linux-${TS_ARCH}.gz" \
         -o /tmp/tree-sitter.gz \
    && gunzip /tmp/tree-sitter.gz \
    && mv /tmp/tree-sitter /usr/local/bin/tree-sitter \
    && chmod +x /usr/local/bin/tree-sitter \
    && tree-sitter --version

# ---------------------------------------------------------------------------
# 3. Pre-clone plugin dependencies into /tmp/nvim-test-deps/
#    This matches the DEPS_DIR constant in tests/minimal_init.lua, so the
#    clone check inside minimal_init skips the network at test time.
# ---------------------------------------------------------------------------
ENV DEPS_DIR=/tmp/nvim-test-deps

RUN mkdir -p "${DEPS_DIR}" \
    && git clone --depth 1 --single-branch \
         https://github.com/nvim-lua/plenary.nvim.git \
         "${DEPS_DIR}/plenary.nvim" \
    && git clone --depth 1 --single-branch \
         https://github.com/nvim-treesitter/nvim-treesitter.git \
         "${DEPS_DIR}/nvim-treesitter"

# ---------------------------------------------------------------------------
# 3b. Pre-compile the Python tree-sitter parser.
#    Clone tree-sitter-python at the exact revision nvim-treesitter expects,
#    build parser.so with the tree-sitter CLI, and place it directly in the
#    nvim-treesitter parser directory that minimal_init.lua adds to rtp.
#    This avoids the TSInstall async issue (install completes before +qa).
# ---------------------------------------------------------------------------
ARG PYTHON_TS_REV=v0.25.0
RUN mkdir -p "${DEPS_DIR}/nvim-treesitter/parser" \
    && git clone --depth 1 --branch "${PYTHON_TS_REV}" \
         https://github.com/tree-sitter/tree-sitter-python \
         /tmp/tree-sitter-python \
    && tree-sitter build \
         -o "${DEPS_DIR}/nvim-treesitter/parser/python.so" \
         /tmp/tree-sitter-python \
    && rm -rf /tmp/tree-sitter-python

# ---------------------------------------------------------------------------
# 4. Default command: run the full test suite.
#    Override with e.g. `docker run ... make test-unit`.
# ---------------------------------------------------------------------------
CMD ["make", "test"]
