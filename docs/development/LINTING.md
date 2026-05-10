# Linting and Code Quality

What `make check` runs, why, and how to extend it.

## Overview

There is no compile step in this project. Quality gates run on the
*source files we ship* — bash, JSON (manifest + i18n), markdown, QML
(structure-only). The same three jobs run in CI
([.github/workflows/ci.yml](../../.github/workflows/ci.yml)) so local
parity is one `make check` away.

| Tool | Purpose | Configuration |
|------|---------|---------------|
| `shellcheck -x` | Bash linter; follows `source` directives across files | `bin/*` and `install.sh` are checked; warnings fail the build |
| `python3 -c "import json; json.load(...)"` | JSON parse validation | Every `*.json` in tree, excluding `.git/` |
| `scripts/check-doc-links.sh` | Markdown link + inline-path validity | Top-level docs (`README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`) |
| `.editorconfig` | Whitespace conventions across languages | Enforced by editor; not a CI gate |

## Quick commands

```bash
make check                  # all three gates (== CI)
make shellcheck             # bash only
make json-validate          # JSON only
make doc-links              # docs only

make health-quick           # check + structural sanity (no runtime)
make health                 # adds runtime/integration checks
make pre-commit             # alias for 'make check'
```

## ShellCheck

```bash
shellcheck -x bin/niri-screensaver bin/niri-screensaver-launch \
              bin/niri-screensaver-ctl install.sh
```

The `-x` flag tells shellcheck to follow `source`/`.` directives across
files. We don't currently use it, but it costs nothing and future-proofs
against script-splitting.

### What we accept

- `set -uo pipefail` at the top of every script. (Drivers run inside
  Alacritty, where `set -e` would kill the process on benign read-loop
  failures, so `-e` is intentionally **off**.)
- Double-quoted variable expansions (`"$var"`) by default.
- `[[ ]]` over `[ ]` everywhere — we're bash-only, no POSIX `sh`
  compatibility goal.
- Functions that read stdin should not also read positional args; the
  inner driver's keypress loop and stdin drain depend on the loop
  owning stdin.

### Common false-positives we suppress

We don't currently disable any rules globally. If you need to, prefer
inline `# shellcheck disable=SCxxxx` with a comment explaining *why*,
not a project-wide silencer.

## JSON validation

```bash
for f in $(find . -name '*.json' -not -path './.git/*'); do
    python3 -c "import json,sys; json.load(open('$f'))"
done
```

The CI job uses `python3` rather than `jq` because `python3` is more
universally available on minimal CI images and gives sharper error
messages on malformed JSON.

Files this currently catches:

- `noctalia-plugin/manifest.json` — registry-required schema
- `noctalia-plugin/i18n/<lang>.json` — translation tables
- `noctalia-plugin/settings.json` — plugin's persisted settings
- `docs/noctalia-customCommand.json` — sample IdleService snippet

The validator only checks parseability, not semantics. The
[health-check](TESTING.md#health-checks) script does additional
schema-shape checks (manifest required keys, i18n nested-object
convention) on top.

## Doc-link checking

`scripts/check-doc-links.sh` walks `README.md`, `CHANGELOG.md`, and
`CONTRIBUTING.md` and verifies two kinds of references:

1. **Markdown links** of the form `[text](relative/path)` — the
   relative path must exist in-tree.
2. **Inline backticked path mentions** like `bin/niri-screensaver` —
   any backticked token starting with a known top-level dir
   (`bin/`, `docs/`, `noctalia-plugin/`, `share/`, `scripts/`,
   `.github/`) and containing a slash must exist on disk.

Skipped:

- `http://` / `https://` URLs (no remote check)
- `~/...` paths and absolute `/...` paths (assumed user-side)
- Tokens with spaces, globs, `=`, `<`, `(`, `#`, leading `-` (i.e.
  command-line examples, not paths)
- Third-party repo refs (paths that don't start with one of our
  top-level dirs, e.g. `hyprwm/Hyprland/...`)

If the script flags a path you intentionally reference but isn't on
disk, the right fix is usually to make the path real (e.g. add the
file or fix a typo), not to silence the checker.

## .editorconfig

[`.editorconfig`](../../.editorconfig) enforces whitespace conventions
that aren't covered by the linters above:

| Pattern | Rule |
|---------|------|
| `*` | UTF-8, LF line endings, final newline, trim trailing whitespace, 4-space indent |
| `*.{qml,json,kdl,toml}` | 2-space indent |
| `*.md` | 2-space indent, **don't** trim trailing whitespace (markdown hard-breaks are two trailing spaces) |
| `Makefile` | Tab indent (a hard requirement of `make`) |
| `share/logos/*.txt` | **Don't** trim trailing whitespace — logos are pixel-art; trailing spaces are content |

Most editors honor `.editorconfig` automatically. If yours doesn't, the
CI doesn't check this — but reviewers will notice trailing-whitespace
diffs and Makefile-with-spaces breakage.

## Pre-commit hook (optional)

```bash
cat > .git/hooks/pre-commit << 'HOOK'
#!/usr/bin/env bash
exec make pre-commit
HOOK
chmod +x .git/hooks/pre-commit
```

This runs `make check` before every commit. If you'd rather defer the
gate to push time:

```bash
cat > .git/hooks/pre-push << 'HOOK'
#!/usr/bin/env bash
exec make pre-commit
HOOK
chmod +x .git/hooks/pre-push
```

## CI integration

[`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) runs three
parallel jobs on push and PR:

1. **shellcheck** — same command as `make shellcheck`.
2. **json-validate** — same loop as `make json-validate`.
3. **doc-links** — inline copy of the same logic as
   `make doc-links` / `scripts/check-doc-links.sh`. (The CI job has
   the logic embedded rather than calling the script, so changes to
   the script must be mirrored in the workflow file. See
   [TESTING.md](TESTING.md) for why.)

All three must pass for PRs to be mergeable.

## What's intentionally not linted

- **QML** — Quickshell's QML is not strictly compatible with stock Qt
  QML, and `qmllint` produces noise on Quickshell idioms (the
  `pluginApi` / `pluginSettings` distinction in particular). We rely on
  Noctalia's hot-reload + manual review instead.
- **Markdown style** — no `markdownlint` config because the project
  uses idiomatic prose, not a fixed style guide. Reviewers eyeball.
- **Spelling** — no `typos` config; spellcheck is reviewer-side.
