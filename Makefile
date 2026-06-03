# niri-screensaver - Local CI/CD orchestration
#
# Mirrors the GitHub Actions workflow in .github/workflows/ci.yml so the
# same gates can be run locally before pushing. There's no compile step
# (bash + QML, file-copy install) so this is a thin Makefile rather than
# a Rust-style justfile.
#
# Run `make help` for available targets.

SHELL := /bin/bash

# Bash scripts subject to shellcheck (mirrors .github/workflows/ci.yml)
BASH_SCRIPTS := bin/niri-screensaver bin/niri-screensaver-launch bin/niri-screensaver-ctl install.sh scripts/check-doc-links.sh scripts/json-validate.sh

# Install prefix (override with: make install INSTALL_PREFIX=/usr/local)
INSTALL_PREFIX ?= $(HOME)/.local

.PHONY: help default check lint shellcheck json-validate doc-links \
        typos markdownlint actionlint unit coverage \
        health health-quick pre-commit install uninstall test effects \
        plugin-link plugin-unlink

default: help

help:
	@echo "niri-screensaver — local CI/CD targets"
	@echo ""
	@echo "  Quality gates (match CI):"
	@echo "    make check          run every gate (skips ones whose tool is missing)"
	@echo "    make lint           alias for 'check'"
	@echo "    make shellcheck     just the bash linter"
	@echo "    make json-validate  validate every *.json in the tree"
	@echo "    make doc-links      check relative paths in markdown resolve in-tree"
	@echo "    make typos          spell-check (cargo install typos-cli)"
	@echo "    make markdownlint   markdown hygiene (npm i -g markdownlint-cli2)"
	@echo "    make actionlint     workflow hygiene (go install github.com/rhysd/actionlint/cmd/actionlint@latest)"
	@echo "    make unit           bats unit tests (pacman -S bats / apt install bats)"
	@echo "    make coverage       bats under kcov, writes coverage/ (needs bats + kcov)"
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

check: shellcheck json-validate doc-links typos markdownlint actionlint unit
	@echo "All checks passed."

lint: check

shellcheck:
	@echo "[shellcheck] $(BASH_SCRIPTS)"
	@shellcheck -x $(BASH_SCRIPTS)

json-validate:
	@echo "[json-validate] all *.json"
	@bash scripts/json-validate.sh

doc-links:
	@echo "[doc-links] README.md CHANGELOG.md CONTRIBUTING.md"
	@bash scripts/check-doc-links.sh

# typos / markdownlint / actionlint skip with a hint when their tool isn't
# installed locally — keeps `make check` runnable on a fresh clone without
# forcing every contributor to install three extra linters. CI installs all
# three via pinned actions, so the gates still bind on PRs.
typos:
	@if command -v typos >/dev/null 2>&1; then \
		echo "[typos] running"; typos; \
	else \
		echo "[typos] SKIP — install: cargo install typos-cli (or download from https://github.com/crate-ci/typos/releases)"; \
	fi

markdownlint:
	@if command -v markdownlint-cli2 >/dev/null 2>&1; then \
		echo "[markdownlint] running"; markdownlint-cli2 '**/*.md' '#node_modules'; \
	else \
		echo "[markdownlint] SKIP — install: npm i -g markdownlint-cli2"; \
	fi

actionlint:
	@if command -v actionlint >/dev/null 2>&1; then \
		echo "[actionlint] running"; actionlint; \
	else \
		echo "[actionlint] SKIP — install: see https://github.com/rhysd/actionlint#installation"; \
	fi

# bats skips with a hint when missing, same as the linters above. CI runs it
# (under kcov) in the coverage job, so the gate still binds on PRs.
unit:
	@if command -v bats >/dev/null 2>&1; then \
		echo "[unit] bats test/"; bats test/; \
	else \
		echo "[unit] SKIP — install: pacman -S bats (or apt install bats)"; \
	fi

# Line coverage of the bash via kcov instrumenting the bats run. Mirrors the
# coverage job in CI; output lands in coverage/ (open coverage/index.html).
coverage:
	@if command -v kcov >/dev/null 2>&1 && command -v bats >/dev/null 2>&1; then \
		echo "[coverage] kcov + bats"; \
		mkdir -p coverage; \
		kcov --clean --include-path="$(CURDIR)/bin,$(CURDIR)/scripts" "$(CURDIR)/coverage" bats test/; \
		echo "Coverage written to coverage/ (open coverage/index.html)"; \
	else \
		echo "[coverage] SKIP — needs both bats and kcov installed"; \
	fi

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
