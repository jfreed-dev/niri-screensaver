# Shared helpers for the bats unit tests.
#
# The two bin scripts guard `main "$@"` behind a BASH_SOURCE/$0 check, so
# sourcing them here defines their functions without running anything. We then
# relax `set -u` (the scripts enable it) so bats' own use of unset variables
# doesn't abort a test.
#
# SPDX-License-Identifier: GPL-3.0-only

# These are consumed by the sibling *.bats files that `load` this helper; the
# linter can't see those uses from this file alone, hence the SC2034 waivers.
# shellcheck disable=SC2034
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
DRIVER="$REPO_ROOT/bin/niri-screensaver"
# shellcheck disable=SC2034
LAUNCHER="$REPO_ROOT/bin/niri-screensaver-launch"
# shellcheck disable=SC2034
CTL="$REPO_ROOT/bin/niri-screensaver-ctl"

source_driver() {
    # shellcheck source=/dev/null
    source "$DRIVER"
    set +u
}

source_launcher() {
    # shellcheck source=/dev/null
    source "$LAUNCHER"
    set +u
}
