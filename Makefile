.PHONY: test test-unit test-integration deps clean lint \
        docker-build docker-test docker-test-unit docker-test-integration

NVIM      ?= nvim
MIN_INIT   = tests/minimal_init.lua
DEPS_DIR   = /tmp/nvim-test-deps

PLENARY_URL     = https://github.com/nvim-lua/plenary.nvim.git
TREESITTER_URL  = https://github.com/nvim-treesitter/nvim-treesitter.git

# Docker image name; override with: make docker-build IMAGE=my-tag
IMAGE ?= nvim-py-gti-test

# ---------------------------------------------------------------------------
# deps — pre-clone dependencies (safe to run repeatedly; skips if present).
# Run this in a dedicated CI step so it can be cached independently of tests.
# ---------------------------------------------------------------------------
deps:
	@mkdir -p $(DEPS_DIR)
	@if [ ! -d $(DEPS_DIR)/plenary.nvim ]; then \
		echo "[deps] cloning plenary.nvim ..."; \
		git clone --depth 1 --single-branch $(PLENARY_URL) $(DEPS_DIR)/plenary.nvim; \
	else \
		echo "[deps] plenary.nvim already present, skipping"; \
	fi
	@if [ ! -d $(DEPS_DIR)/nvim-treesitter ]; then \
		echo "[deps] cloning nvim-treesitter ..."; \
		git clone --depth 1 --single-branch $(TREESITTER_URL) $(DEPS_DIR)/nvim-treesitter; \
	else \
		echo "[deps] nvim-treesitter already present, skipping"; \
	fi

# ---------------------------------------------------------------------------
# test targets (host — no Docker)
# ---------------------------------------------------------------------------

# Run the full test suite (unit + integration).
test:
	$(NVIM) --headless --noplugin -u $(MIN_INIT) \
		+"PlenaryBustedDirectory tests/ {minimal_init = '$(MIN_INIT)'}" \
		+qa

# Run only unit tests.
test-unit:
	$(NVIM) --headless --noplugin -u $(MIN_INIT) \
		+"PlenaryBustedDirectory tests/unit/ {minimal_init = '$(MIN_INIT)'}" \
		+qa

# Run only integration tests.
test-integration:
	$(NVIM) --headless --noplugin -u $(MIN_INIT) \
		+"PlenaryBustedDirectory tests/integration/ {minimal_init = '$(MIN_INIT)'}" \
		+qa

# ---------------------------------------------------------------------------
# Docker targets
# ---------------------------------------------------------------------------

# Build the test image.  Re-run whenever the Dockerfile or minimal_init.lua
# changes (the COPY of minimal_init.lua invalidates the layer automatically).
docker-build:
	docker build -t $(IMAGE) .

# Run the full test suite inside the container.
# The plugin source is bind-mounted so the image does not need to be rebuilt
# when Lua sources change.
docker-test:
	docker run --rm \
		-v "$(PWD):/plugin" \
		-w /plugin \
		$(IMAGE) make test

# Run only unit tests inside the container.
docker-test-unit:
	docker run --rm \
		-v "$(PWD):/plugin" \
		-w /plugin \
		$(IMAGE) make test-unit

# Run only integration tests inside the container.
docker-test-integration:
	docker run --rm \
		-v "$(PWD):/plugin" \
		-w /plugin \
		$(IMAGE) make test-integration

# ---------------------------------------------------------------------------
# lint — optional, skips gracefully when luacheck is absent.
# ---------------------------------------------------------------------------
lint:
	@command -v luacheck >/dev/null 2>&1 && \
		luacheck lua/ plugin/ tests/ --globals vim || \
		echo "luacheck not found, skipping lint"

# ---------------------------------------------------------------------------
# clean — remove cloned deps so the next run re-fetches them.
# ---------------------------------------------------------------------------
clean:
	rm -rf $(DEPS_DIR)
