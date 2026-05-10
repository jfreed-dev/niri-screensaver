#!/usr/bin/env bash
# scripts/uninstall.sh
#
# Reverse of install.sh — removes binaries and shared assets that
# install.sh placed under $INSTALL_PREFIX. Does NOT touch user config
# at ~/.config/niri-screensaver (intentional, so you can reinstall
# without losing settings).
#
# Usage:
#   bash scripts/uninstall.sh                # uses $HOME/.local
#   bash scripts/uninstall.sh /usr/local     # explicit prefix
#
# SPDX-License-Identifier: GPL-3.0-only

set -uo pipefail

PREFIX="${1:-${INSTALL_PREFIX:-$HOME/.local}}"
BIN_DIR="${PREFIX}/bin"
DATA_DIR="${PREFIX}/share/niri-screensaver"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
log()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
miss() { echo -e "${YELLOW}[SKIP]${NC} $*"; }

log "Uninstalling from: $PREFIX"

for bin in niri-screensaver niri-screensaver-launch niri-screensaver-ctl; do
    if [[ -e "$BIN_DIR/$bin" ]]; then
        rm -f "$BIN_DIR/$bin" && ok "removed $BIN_DIR/$bin"
    else
        miss "$BIN_DIR/$bin (not present)"
    fi
done

if [[ -d "$DATA_DIR" ]]; then
    rm -rf "$DATA_DIR" && ok "removed $DATA_DIR"
else
    miss "$DATA_DIR (not present)"
fi

cat << EOF

User config at ~/.config/niri-screensaver/ was left in place.
Remove it manually if you want a clean slate:
  rm -rf ~/.config/niri-screensaver
EOF
