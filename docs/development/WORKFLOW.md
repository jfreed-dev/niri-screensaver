# Development Workflow

How changes flow through this repo, plus the rules unique to a project
that ships **two parallel deliverables** in lockstep.

## Repository status

| Branch | Purpose | Status |
|--------|---------|--------|
| `main` | Stable development | **Active** |

- **Single maintainer** today; external contributions via fork + pull
  request.
- Direct commits to `main` for routine fixes, doc tweaks, etc.
- Larger or risky changes go on a short-lived feature branch and merge
  via PR (even when self-merging — keeps the branch's `git log` clean).

## The two-deliverable rule

The repo ships:

1. **Bash CLI** (`bin/`) — actual screensaver runtime.
2. **Noctalia plugin** (`noctalia-plugin/`) — the QML wrapper that
   writes config and shells out to the CLI.

These are **not independent**. The plugin's `Main.qml` writes
`~/.config/niri-screensaver/config` whose keys must match what the
bash driver's `load_config` reads. Adding or renaming a config key
requires touching every file in this list — and CI does not enforce
the symmetry. Per [CLAUDE.md](../../CLAUDE.md):

| Layer | File(s) |
|-------|---------|
| Bash defaults & arg parsing | `bin/niri-screensaver` |
| User-facing docs | `README.md` (config table) |
| Plugin defaults | `noctalia-plugin/manifest.json` (`metadata.defaultSettings`) |
| Plugin shell-config writer | `noctalia-plugin/Main.qml._renderShellConfig` |
| Plugin settings UI | `noctalia-plugin/Settings.qml` |
| i18n labels | `noctalia-plugin/i18n/en.json` (and other locales) |
| Release notes | `CHANGELOG.md` under `## [Unreleased]` |

If you add a config key with a path-shaped default (e.g. `LOGO_DIR`),
also add a `: "${LOGO_DIR:=...}"` fallback in `bin/niri-screensaver`'s
`load_config`. The plugin writes blank values for unset keys, so the
bash side must re-apply defaults *after* sourcing — see
[CLAUDE.md](../../CLAUDE.md) "Config-flow gotchas" for the full list.

## Commit style

Conventional Commits, present-tense imperative subject:

```text
feat: add new config key
fix: drain stdin before key-listener loop
docs: refresh demo gif
refactor: split logo picker into helper
test: add UAT note for hot-reload
chore: bump version to 0.3.0
ci: widen doc-link check to inline path mentions
```

Body (optional, encouraged for non-trivial changes): explain *why*,
not *what* — diff already shows what. One paragraph is plenty.

## Pre-commit gate

Run before every push:

```bash
make pre-commit             # alias for 'make check' — same gates as CI
```

Equivalent to running:

```bash
make shellcheck             # bash linter
make json-validate          # parse every *.json
make doc-links              # markdown + inline path mention links
```

For a deeper check (file structure, install state, runtime sanity),
run `make health` before cutting a release.

A pre-commit hook example (optional):

```bash
cat > .git/hooks/pre-commit << 'HOOK'
#!/usr/bin/env bash
exec make pre-commit
HOOK
chmod +x .git/hooks/pre-commit
```

## Feature branches

For changes that touch multiple files in the dual-deliverable list, or
that you want to test on a real Noctalia session before landing:

```bash
git checkout -b feat/random-logo
# ... edit, test ...
git push -u origin feat/random-logo
gh pr create --fill
# review, merge
git checkout main && git pull && git branch -d feat/random-logo
```

## Releases

The project tracks [Semantic Versioning](https://semver.org/).
Pre-1.0, breaking config-key changes are signaled in the changelog
with a `**Breaking:**` prefix and bumped as minor versions (0.2 → 0.3).

Cutting a release:

1. **Sync version strings.** All three places must agree:
   - `noctalia-plugin/manifest.json` `version`
   - `CHANGELOG.md` — promote `## [Unreleased]` to `## [X.Y.Z] — YYYY-MM-DD`
     and add a fresh empty `## [Unreleased]` section above it
   - Any other place that hard-codes version (`README.md` is generally
     version-agnostic)
2. **Run `make health`** end-to-end. PASS only.
3. **Commit:** `chore: release vX.Y.Z`
4. **Tag and push:**
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push --tags
   ```
5. **Create the GitHub release** with the changelog excerpt:
   ```bash
   gh release create vX.Y.Z --notes-from-tag
   ```
6. **Update the awesome-niri / noctalia-plugins entries** if anything
   user-visible changed — see
   [UPSTREAM-SUBMISSION.md](UPSTREAM-SUBMISSION.md).

## Distribution status

| Format | Status | Notes |
|--------|--------|-------|
| Source install (`./install.sh`) | **Shipped** | Default path, ~/.local prefix, no privileges needed |
| Noctalia plugin registry | **Pending** | Plugin meets manifest schema; preview.png needs resize. See [UPSTREAM-SUBMISSION.md](UPSTREAM-SUBMISSION.md). |
| awesome-niri listing | **Pending** | One-line PR; see [UPSTREAM-SUBMISSION.md](UPSTREAM-SUBMISSION.md). |
| AUR | **Considered, not shipped** | A `niri-screensaver-git` PKGBUILD would just wrap `install.sh`; defer until there's enough demand. |
| Flatpak / .deb | **Not planned** | The bash CLI works fine via `~/.local`; sandboxing TTE + Alacritty + niri IPC isn't worth the surface area. |

## Quick reference

```bash
# day-to-day
make pre-commit                       # before every push
make plugin-link                      # symlink for hot-reload
niri-screensaver-ctl test             # render single effect inline

# release
make health                           # full health check
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push --tags
gh release create vX.Y.Z --notes-from-tag
```
