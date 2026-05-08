#!/bin/bash
# install.sh - User-local install of niri-screensaver
#
# Places binaries in ~/.local/bin and shared assets in ~/.local/share/niri-screensaver.
# Run with INSTALL_PREFIX=/usr/local for a system-wide install.
# SPDX-License-Identifier: GPL-3.0-only

set -euo pipefail

REPO_DIR="$(dirname "$(readlink -f "$0")")"
PREFIX="${INSTALL_PREFIX:-$HOME/.local}"
BIN_DIR="${PREFIX}/bin"
DATA_DIR="${PREFIX}/share/niri-screensaver"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()  { echo -e "${GREEN}[OK]${NC} $*"; }

log "Installing to: $PREFIX"

mkdir -p "$BIN_DIR" "$DATA_DIR/logos"

install -m 0755 "$REPO_DIR/bin/niri-screensaver"        "$BIN_DIR/niri-screensaver"
install -m 0755 "$REPO_DIR/bin/niri-screensaver-launch" "$BIN_DIR/niri-screensaver-launch"
install -m 0755 "$REPO_DIR/bin/niri-screensaver-ctl"    "$BIN_DIR/niri-screensaver-ctl"

install -m 0644 "$REPO_DIR/share/alacritty-screensaver.toml" "$DATA_DIR/"
install -m 0644 "$REPO_DIR/share/logos/"*.txt               "$DATA_DIR/logos/"

ok "Binaries installed to $BIN_DIR"
ok "Assets installed to $DATA_DIR"

cat << EOF

Next steps:
  1. Make sure ~/.local/bin is on your PATH.
  2. Add the niri window-rule from docs/niri-window-rule.kdl to ~/.config/niri/config.kdl.
  3. Wire idle in Noctalia (Settings > Idle > Custom Commands) using the snippet
     in docs/noctalia-customCommand.json, OR install the Noctalia plugin:
       see noctalia-plugin/README.md
  4. Verify with:  niri-screensaver-ctl launch
EOF
