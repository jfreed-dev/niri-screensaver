#!/usr/bin/env bash
# scripts/check-doc-links.sh
#
# Verifies that every relative path mentioned in the project's top-level
# markdown docs resolves to a file in the tree. Mirrors the doc-links job
# in .github/workflows/ci.yml so it can be run locally.
#
# Two passes per doc:
#   1. Markdown links: any [text](relative/path) must exist
#   2. Inline path mentions: any `backticked` token that looks like a repo
#      path (starts with a known top-level dir, contains a slash) must exist
#
# Skips: tilde paths (~/.config/...), absolute paths, flags, command-line
# examples with spaces/globs/var-substitutions, third-party repo refs.
# SPDX-License-Identifier: GPL-3.0-only

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

prefix_re='^(bin|docs|noctalia-plugin|share|scripts|\.github)/'
fail=0

for doc in README.md CHANGELOG.md CONTRIBUTING.md; do
    [[ -f "$doc" ]] || continue
    echo "=== $doc ==="

    # Markdown link pass
    while IFS= read -r path; do
        [[ -e "$path" ]] || { echo "  missing md-link: $path"; fail=1; }
    done < <(grep -oP '(?<=\]\()(?!http)[^)#]+' "$doc" | sort -u)

    # Inline backtick path mention pass
    while IFS= read -r token; do
        [[ "$token" == *" "*  ]] && continue
        [[ "$token" == *"*"*  ]] && continue
        [[ "$token" == *"<"*  ]] && continue
        [[ "$token" == *"="*  ]] && continue
        [[ "$token" == *"("*  ]] && continue
        [[ "$token" == *"#"*  ]] && continue
        [[ "$token" == "~"*   ]] && continue
        [[ "$token" == "/"*   ]] && continue
        [[ "$token" == "-"*   ]] && continue
        [[ "$token" == *"/"*  ]] || continue
        [[ "$token" =~ $prefix_re ]] || continue
        candidate="${token%/}"
        [[ -e "$candidate" ]] || { echo "  missing inline: $token"; fail=1; }
    done < <(grep -oP '(?<=`)[^`]+(?=`)' "$doc" | sort -u)
done

exit $fail
