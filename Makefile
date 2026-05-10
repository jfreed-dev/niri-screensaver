# niri-screensaver - Local CI/CD orchestration
#
# Mirrors the GitHub Actions workflow in .github/workflows/ci.yml so the
# same gates can be run locally before pushing. There's no compile step
# (bash + QML, file-copy install) so this is a thin Makefile rather than
# a Rust-style justfile.
#
# Run `make help` for available targets.

SHELL := /bin/bash

# Bash scripts subject to shellcheck
BASH_SCRIPTS := bin/niri-screensaver bin/niri-screensaver-launch bin/niri-screensaver-ctl install.sh

# Install prefix (override with: make install INSTALL_PREFIX=/usr/local)
INSTALL_PREFIX ?= $(HOME)/.local

.PHONY: help default check lint shellcheck json-validate doc-links \
        health health-quick pre-commit install uninstall test effects \
        plugin-link plugin-unlink

default: help

help:
	@echo "niri-screensaver — local CI/CD targets"
	@echo ""
	@echo "  Quality gates (match CI):"
	@echo "    make check          shellcheck + json-validate + doc-links (== CI)"
	@echo "    make lint           alias for 'check'"
	@echo "    make shellcheck     just the bash linter"
	@echo "    make json-validate  validate every *.json in the tree"
	@echo "    make doc-links      check relative paths in markdown resolve in-tree"
	@echo ""
	@echo "  Health checks:"
	@echo "    make health-quick   build/code-quality checks only (no runtime)"
	@echo "    make health         full health check (adds runtime/integration)"
	@echo ""
	@echo "  Workflow:"
	@echo "    make pre-commit     run before committing (same as 'check')"
	@echo ""
	@echo "  Install:"
	@echo "    make install        install to \$$INSTALL_PREFIX (default: ~/.local)"
	@echo "    make uninstall      remove installed files"
	@echo "    make plugin-link    symlink noctalia-plugin/ for hot-reload dev"
	@echo "    make plugin-unlink  remove the dev symlink"
	@echo ""
	@echo "  Smoke tests:"
	@echo "    make test           run a single TTE effect inline (random)"
	@echo "    make effects        list available TTE effects"

# ---------- CI parity ----------

check: shellcheck json-validate doc-links
	@echo "All checks passed."

lint: check

shellcheck:
	@echo "[shellcheck] $(BASH_SCRIPTS)"
	@shellcheck -x $(BASH_SCRIPTS)

json-validate:
	@echo "[json-validate] all *.json"
	@for f in $$(find . -name '*.json' -not -path './.git/*'); do \
		python3 -c "import json,sys; json.load(open('$$f'))" || { echo "invalid: $$f"; exit 1; }; \
	done

doc-links:
	@echo "[doc-links] README.md CHANGELOG.md CONTRIBUTING.md"
	@bash scripts/check-doc-links.sh

# ---------- Health ----------

health-quick:
	@bash scripts/health-check.sh --quick

health:
	@bash scripts/health-check.sh

# ---------- Workflow ----------

pre-commit: check
	@echo "Pre-commit checks passed."

# ---------- Install ----------

install:
	@INSTALL_PREFIX=$(INSTALL_PREFIX) ./install.sh

uninstall:
	@bash scripts/uninstall.sh $(INSTALL_PREFIX)

plugin-link:
	@dest="$$HOME/.config/noctalia/plugins/niri-screensaver"; \
	if [[ -e "$$dest" ]]; then echo "Already exists: $$dest"; exit 1; fi; \
	mkdir -p "$$(dirname $$dest)"; \
	ln -s "$(CURDIR)/noctalia-plugin" "$$dest"; \
	echo "Symlinked $$dest -> $(CURDIR)/noctalia-plugin"

plugin-unlink:
	@dest="$$HOME/.config/noctalia/plugins/niri-screensaver"; \
	if [[ -L "$$dest" ]]; then rm "$$dest"; echo "Removed symlink: $$dest"; \
	else echo "Not a symlink (or missing): $$dest"; fi

# ---------- Smoke tests ----------

test:
	@niri-screensaver-ctl test

effects:
	@niri-screensaver-ctl effects
