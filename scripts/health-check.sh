#!/usr/bin/env bash
# scripts/health-check.sh
#
# niri-screensaver — health check.
#
# Validates the project tree, the local toolchain, and (in full mode)
# runtime integration with niri / Noctalia. Run it after a fresh clone,
# before cutting a release, or when chasing "it works on my machine"
# regressions.
#
# Usage:
#   ./scripts/health-check.sh          # all checks (build + runtime)
#   ./scripts/health-check.sh --quick  # build/lint/structural only
#
# Exit codes:
#   0 — all checks passed (warnings are informational)
#   1 — one or more checks failed
#
# SPDX-License-Identifier: GPL-3.0-only

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

PASS=0; FAIL=0; WARN=0; SKIP=0
pass() { PASS=$((PASS+1));  echo -e "  ${GREEN}PASS${NC} $1"; }
fail() { FAIL=$((FAIL+1));  echo -e "  ${RED}FAIL${NC} $1"; }
warn() { WARN=$((WARN+1));  echo -e "  ${YELLOW}WARN${NC} $1"; }
skip() { SKIP=$((SKIP+1));  echo -e "  ${CYAN}SKIP${NC} $1"; }
section() { echo -e "\n${BOLD}[$1]${NC}"; }

QUICK=false
[[ "${1:-}" == "--quick" ]] && QUICK=true

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo -e "${BOLD}niri-screensaver — health check${NC}"
echo "================================"

BASH_SCRIPTS=(bin/niri-screensaver bin/niri-screensaver-launch bin/niri-screensaver-ctl install.sh)

# =========================================================================
# BUILD ENVIRONMENT
# =========================================================================
section "Toolchain"

for tool in bash shellcheck python3 jq; do
    if command -v "$tool" >/dev/null 2>&1; then
        pass "$tool available"
    else
        # python3 + shellcheck are required by CI; jq is required by the launcher
        if [[ "$tool" == "jq" ]]; then
            warn "$tool not found (niri-screensaver-launch needs it at runtime)"
        else
            fail "$tool not found (required for local CI parity)"
        fi
    fi
done

section "Bash quality"

# bash -n syntax check on every shipped script
for s in "${BASH_SCRIPTS[@]}"; do
    if bash -n "$s" 2>/dev/null; then
        pass "syntax: $s"
    else
        fail "syntax: $s"
    fi
done

if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck -x "${BASH_SCRIPTS[@]}" >/dev/null 2>&1; then
        pass "shellcheck -x (zero warnings)"
    else
        fail "shellcheck -x has warnings"
    fi
else
    skip "shellcheck not installed"
fi

section "JSON"

if command -v python3 >/dev/null 2>&1; then
    bad=0
    while IFS= read -r f; do
        python3 -c "import json,sys; json.load(open('$f'))" 2>/dev/null \
            || { echo "    invalid: $f"; bad=1; }
    done < <(find . -name '*.json' -not -path './.git/*')
    if [[ "$bad" -eq 0 ]]; then
        pass "every *.json parses"
    else
        fail "one or more *.json files invalid"
    fi
else
    skip "python3 missing — JSON validation skipped"
fi

section "Doc links"

if [[ -x scripts/check-doc-links.sh ]]; then
    if bash scripts/check-doc-links.sh >/dev/null 2>&1; then
        pass "relative paths in markdown resolve in-tree"
    else
        fail "broken markdown / inline-path link(s) — run: bash scripts/check-doc-links.sh"
    fi
else
    warn "scripts/check-doc-links.sh missing or not executable"
fi

section "Project structure"

# SPDX headers on bash scripts
missing_spdx=()
for s in "${BASH_SCRIPTS[@]}" scripts/*.sh; do
    [[ -f "$s" ]] || continue
    grep -q "SPDX-License-Identifier" "$s" || missing_spdx+=("$s")
done
if [[ ${#missing_spdx[@]} -eq 0 ]]; then
    pass "SPDX headers present on every shipped/script .sh"
else
    fail "missing SPDX header: ${missing_spdx[*]}"
fi

# Required top-level files
for f in README.md LICENSE CHANGELOG.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md install.sh Makefile; do
    [[ -f "$f" ]] && pass "exists: $f" || fail "missing: $f"
done

# Logos
LOGO_COUNT=$(find share/logos -maxdepth 1 -name '*.txt' 2>/dev/null | wc -l)
if [[ "$LOGO_COUNT" -gt 0 ]]; then
    pass "share/logos: $LOGO_COUNT .txt files"
else
    fail "share/logos has no .txt files"
fi

# Plugin manifest sanity
if [[ -f noctalia-plugin/manifest.json ]]; then
    if python3 -c "
import json, sys
m = json.load(open('noctalia-plugin/manifest.json'))
# Top-level keys required by noctalia-dev/noctalia-plugins/schema.json
required_top = {'id', 'name', 'version', 'minNoctaliaVersion', 'author',
                'license', 'repository', 'description', 'entryPoints'}
missing = required_top - m.keys()
# Plus the nested metadata.defaultSettings
if 'defaultSettings' not in m.get('metadata', {}):
    missing.add('metadata.defaultSettings')
sys.exit(0 if not missing else 1)
" 2>/dev/null; then
        pass "noctalia-plugin/manifest.json has registry-required keys"
    else
        fail "noctalia-plugin/manifest.json missing one of: id/name/version/minNoctaliaVersion/author/license/repository/description/entryPoints/metadata.defaultSettings"
    fi
else
    fail "noctalia-plugin/manifest.json missing"
fi

# i18n nested-object convention (Noctalia's tr() walks nested keys)
if [[ -f noctalia-plugin/i18n/en.json ]]; then
    if python3 -c "
import json
en = json.load(open('noctalia-plugin/i18n/en.json'))
# Any flat dotted key like 'settings.idle.label' would mean we forgot to nest.
flat_dotted = [k for k in en.keys() if '.' in k]
import sys; sys.exit(0 if not flat_dotted else 1)
" 2>/dev/null; then
        pass "noctalia-plugin/i18n/en.json is nested (no flat dotted keys at top level)"
    else
        warn "noctalia-plugin/i18n/en.json has flat dotted keys at top level — Noctalia's tr() expects nested objects"
    fi
fi

if $QUICK; then
    section "Summary"
    echo -e "  ${GREEN}PASS${NC} $PASS  ${RED}FAIL${NC} $FAIL  ${YELLOW}WARN${NC} $WARN  ${CYAN}SKIP${NC} $SKIP"
    [[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
fi

# =========================================================================
# RUNTIME (full mode)
# =========================================================================
section "Wayland / niri runtime"

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    pass "Wayland session active ($WAYLAND_DISPLAY)"
else
    warn "WAYLAND_DISPLAY not set — niri runtime checks unreliable"
fi

if command -v niri >/dev/null 2>&1; then
    pass "niri binary on PATH"
    if niri msg --json outputs >/dev/null 2>&1; then
        OUT_COUNT=$(niri msg --json outputs 2>/dev/null | jq 'length' 2>/dev/null || echo 0)
        pass "niri IPC reachable ($OUT_COUNT output(s) enumerated)"
    else
        warn "niri installed but IPC not reachable (compositor not running?)"
    fi
else
    warn "niri not installed — launcher cannot spawn fullscreen surfaces"
fi

section "Companion tools"

if command -v alacritty >/dev/null 2>&1; then
    pass "alacritty available"
else
    fail "alacritty missing — required by niri-screensaver-launch"
fi

if command -v tte >/dev/null 2>&1; then
    pass "tte (TerminalTextEffects) available"
else
    fail "tte missing — required by inner driver (pip install terminaltexteffects)"
fi

section "Install state"

for bin in niri-screensaver niri-screensaver-launch niri-screensaver-ctl; do
    if command -v "$bin" >/dev/null 2>&1; then
        pass "$bin on PATH at: $(command -v "$bin")"
    else
        skip "$bin not on PATH (run 'make install' or './install.sh')"
    fi
done

DATA_CANDIDATES=(
    "${NIRI_SCREENSAVER_DATA:-}"
    "$HOME/.local/share/niri-screensaver"
    "/usr/local/share/niri-screensaver"
    "/usr/share/niri-screensaver"
)
found_data=""
for d in "${DATA_CANDIDATES[@]}"; do
    [[ -n "$d" && -d "$d" ]] && { found_data="$d"; break; }
done
if [[ -n "$found_data" ]]; then
    pass "data dir resolved: $found_data"
    [[ -f "$found_data/alacritty-screensaver.toml" ]] \
        && pass "alacritty config present" \
        || warn "alacritty-screensaver.toml missing in data dir"
    LOGOS=$(find "$found_data/logos" -maxdepth 1 -name '*.txt' 2>/dev/null | wc -l)
    [[ "$LOGOS" -gt 0 ]] \
        && pass "logos installed ($LOGOS files)" \
        || warn "no logos installed in $found_data/logos"
else
    skip "no data dir installed yet"
fi

section "User config"

USER_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/niri-screensaver/config"
if [[ -f "$USER_CFG" ]]; then
    pass "user config exists: $USER_CFG"
else
    skip "$USER_CFG not yet created (driver writes defaults on first run)"
fi

section "Noctalia plugin"

NOCT_PLUGIN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/plugins/niri-screensaver"
if [[ -L "$NOCT_PLUGIN_DIR" ]]; then
    pass "plugin symlinked for hot-reload dev: $NOCT_PLUGIN_DIR -> $(readlink "$NOCT_PLUGIN_DIR")"
elif [[ -d "$NOCT_PLUGIN_DIR" ]]; then
    pass "plugin installed (not symlinked) at $NOCT_PLUGIN_DIR"
else
    skip "Noctalia plugin not installed (run 'make plugin-link' from a checkout)"
fi

# =========================================================================
section "Summary"
echo -e "  ${GREEN}PASS${NC} $PASS  ${RED}FAIL${NC} $FAIL  ${YELLOW}WARN${NC} $WARN  ${CYAN}SKIP${NC} $SKIP"

if [[ "$FAIL" -eq 0 ]]; then
    echo -e "\n${GREEN}${BOLD}All checks passed.${NC}"
    exit 0
else
    echo -e "\n${RED}${BOLD}$FAIL check(s) failed.${NC}"
    exit 1
fi
