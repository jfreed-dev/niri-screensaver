#!/usr/bin/env bash
# scripts/json-validate.sh
#
# Parses every *.json in the tree to catch malformed manifests, i18n
# files, or doc-embedded snippets before they break CI / Noctalia /
# the noctalia-plugins registry. Mirrors the json-validate job in
# .github/workflows/ci.yml so it can be run locally.
#
# SPDX-License-Identifier: GPL-3.0-only

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

fail=0
while IFS= read -r -d '' f; do
    if ! python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
        echo "invalid: $f"
        fail=1
    fi
done < <(find . -name '*.json' \
    -not -path './.git/*' \
    -not -path './node_modules/*' \
    -print0)

exit $fail
