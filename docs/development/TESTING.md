# Testing Guide

How to verify a change doesn't break either deliverable. There are no
unit tests — the project is bash + QML + ASCII assets, so testing is
mostly **layered smoke testing** (each script tested in isolation,
then together) plus a UAT checklist for user-visible behavior.

## Quick reference

```bash
# Lint + structural sanity (run before every commit)
make pre-commit             # shellcheck + json + doc-links

# Build / install state
make health-quick           # build/lint/structural — no runtime needed
make health                 # adds runtime checks (niri running, alacritty/tte present, install state)

# Smoke tests
niri-screensaver-ctl test               # one TTE effect, inline (no fullscreen)
niri-screensaver-ctl test EFFECT_NAME   # one specific TTE effect
niri-screensaver-ctl effects            # list all TTE effects
niri-screensaver-ctl launch             # full fullscreen run (requires niri)
niri-screensaver-ctl status             # report state — paste this in bug reports
```

## Layered smoke tests

The three CLI scripts are intentionally separated by layer. Test the
layer your change touches:

### Inner driver — `bin/niri-screensaver`

Owns: config loading, effect loop, fade-in/out, clock, logo picker,
key-dismiss, terminal restore on exit. Runs in the *current* terminal.

Test inline:

```bash
niri-screensaver-ctl test                  # random effect from default set
niri-screensaver-ctl test slide            # specific effect
LOGO_FILE=share/logos/niri-name-with-tiles.txt \
    niri-screensaver-ctl test
RANDOM_LOGO=true LOGO_DIR=share/logos \
    niri-screensaver-ctl test              # exercises the random picker
```

You're checking:

- The effect renders and doesn't crash.
- Pressing any key (when `dismissOnKey=true`) dismisses cleanly.
- After dismissal, your terminal prompt comes back un-mangled — no
  hidden cursor, no leftover mouse-tracking, no rogue color codes.
- If you set `LOGO_FILE` to a missing path, the driver falls back
  gracefully (logs a warning, picks a default) rather than dying.

### Launcher — `bin/niri-screensaver-launch`

Owns: PID/toggle files, multi-monitor `focus-monitor-next` cycling,
output enumeration via `niri msg --json outputs | jq`, spawning one
Alacritty per output with `--class niri-screensaver`.

Test against a real niri session:

```bash
niri-screensaver-launch launch    # full fullscreen, all monitors
niri-screensaver-launch status    # shows running PIDs / output state
niri-screensaver-launch kill      # stop
niri-screensaver-launch toggle    # respect the toggle/disabled flag
```

You're checking:

- One fullscreen surface per output. The niri window-rule on
  `app-id="niri-screensaver"` should auto-fullscreen each.
- `kill` actually kills (no orphaned Alacritty windows, no orphaned
  `tte` processes).
- `status` accurately reports PIDs and state.
- The toggle file at the documented location flips correctly.

### Plugin — `noctalia-plugin/`

Owns: writing `~/.config/niri-screensaver/config`, IdleService wiring,
bar widget, settings UI, IPC surface (`plugin:niri-screensaver`).

Test the QML hot-reload loop:

```bash
make plugin-link            # symlink for hot-reload
# In Noctalia: Settings → Developer → enable Debug
# Edit any noctalia-plugin/*.qml and save
# Noctalia hot-reloads — change should appear within ~1s
```

You're checking:

- Saving a `.qml` causes a visible UI/state update without a
  shell restart.
- Tweaking a setting in `Settings.qml` advances the mtime on
  `~/.config/niri-screensaver/config` and writes the new value.
- The `Connections { target: pluginApi }` handler fires on
  `pluginSettingsChanged` (not on the plain JS `pluginSettings`
  object). If you're not seeing config updates, this is the most
  common cause.
- The bar widget icon respects the active Noctalia theme (white SVG
  strokes are tinted via MultiEffect — see CLAUDE.md).

## Health-check script

`scripts/health-check.sh` is a section-organized PASS/FAIL/WARN/SKIP
report covering everything `make check` doesn't.

### Quick mode

```bash
./scripts/health-check.sh --quick
# or
make health-quick
```

Runs:

- Toolchain: bash, shellcheck, python3, jq present
- Bash quality: `bash -n` syntax check, `shellcheck -x`
- JSON: every `*.json` parses
- Doc links: `scripts/check-doc-links.sh` clean
- Structure: SPDX headers on bash + script files; required top-level
  files (`README.md`, `LICENSE`, `CHANGELOG.md`, etc.) present;
  `share/logos/` non-empty
- Plugin schema: `noctalia-plugin/manifest.json` has the registry's
  required keys
- i18n: `noctalia-plugin/i18n/en.json` uses nested objects (Noctalia's
  `tr()` walks dot-paths through nested objects, not flat dotted
  keys at top level)

### Full mode

```bash
./scripts/health-check.sh
# or
make health
```

Adds:

- Wayland session detection (`$WAYLAND_DISPLAY`)
- niri reachable via `niri msg --json outputs`; output count
- alacritty + tte (TerminalTextEffects) on PATH
- Install state: each binary on PATH, data dir resolved
- User config presence (informational; defaults are written on first
  run)
- Noctalia plugin install state (symlink for dev vs copied install)

Exit codes:

- `0` — all PASS, possibly with WARN/SKIP (informational)
- `1` — one or more FAIL

## UAT checklist

Run before tagging a release. Each row should be reproducible from a
fresh shell on a real niri + Noctalia session.

### UAT-01 — Inline driver

| Step | Action | Expected |
|---|---|---|
| 1 | `niri-screensaver-ctl test` | Random effect renders for one cycle |
| 2 | `niri-screensaver-ctl test slide` | Specific effect renders |
| 3 | `niri-screensaver-ctl effects` | List of TTE effects, exit 0 |
| 4 | Press any key during effect | Effect dismisses, prompt restored cleanly |
| 5 | Test with `LOGO_FILE=/nonexistent` | Fallback warning, default logo used, no crash |

### UAT-02 — Fullscreen launcher

| Step | Action | Expected |
|---|---|---|
| 1 | `niri-screensaver-ctl launch` | One fullscreen Alacritty per output, all running effects |
| 2 | Move cursor between outputs (multi-monitor) | `focus-monitor-next` cycling, no surface lost |
| 3 | `niri-screensaver-ctl status` from another shell | Shows `running=true`, PIDs, output count matches `niri msg outputs` |
| 4 | Press any key on any output | All surfaces close together, no orphan processes |
| 5 | `pgrep -f tte` after dismiss | Empty (no leftover effect processes) |
| 6 | `pgrep -fa niri-screensaver` after dismiss | Empty (no leftover scripts) |

### UAT-03 — Plugin hot-reload

| Step | Action | Expected |
|---|---|---|
| 1 | `make plugin-link` from a fresh checkout | Symlink at `~/.config/noctalia/plugins/niri-screensaver` |
| 2 | Toggle plugin off/on in Noctalia → Plugins | Plugin reloads, bar widget appears/disappears |
| 3 | Edit `noctalia-plugin/Settings.qml` (any visible change) and save | Hot-reload reflects the change without restarting Noctalia |
| 4 | Toggle a setting in the Settings UI | `~/.config/niri-screensaver/config` mtime advances; new value present |
| 5 | Disable the plugin | Bar widget removed, IdleService entry de-registered |

### UAT-04 — Idle integration

| Step | Action | Expected |
|---|---|---|
| 1 | Set `idleSeconds=15` in plugin Settings | Config file shows `IDLE_SECONDS=15` |
| 2 | Stay idle for 15+ seconds | Screensaver launches automatically |
| 3 | Move mouse / press key | Screensaver dismisses, normal session resumes |
| 4 | Disable the plugin's "Enabled" toggle | Idle no longer triggers screensaver |

### UAT-05 — Lock-screen interaction

| Step | Action | Expected |
|---|---|---|
| 1 | `loginctl lock-session` while screensaver is running | Noctalia lock takes over; screensaver kills cleanly |
| 2 | Unlock | No leftover screensaver surfaces; Noctalia unlock animation completes |

### UAT-06 — Logo picker

| Step | Action | Expected |
|---|---|---|
| 1 | Set `LOGO_FILE=share/logos/niri-name-with-icon.txt`, run `test` | That logo renders |
| 2 | Set `RANDOM_LOGO=true`, `LOGO_DIR=share/logos`, run `test` repeatedly | Different logo per run (eyeball check) |
| 3 | Set `RANDOM_LOGO=true` with empty `LOGO_DIR` | Falls back to default logo, no crash |

### UAT-07 — Bar widget visuals

| Step | Action | Expected |
|---|---|---|
| 1 | Look at the bar widget under default Noctalia theme | Custom monitor-with-image SVG glyph, tinted in theme color |
| 2 | Switch Noctalia themes | Glyph re-tints to match new theme accent |
| 3 | Toggle `bar.showCapsule` in Noctalia | Capsule fill respects the preference (matches Battery, Volume, Clock) |
| 4 | Toggle `bar.showOutline` | Outline border respects the preference |
| 5 | Click the widget | Triggers screensaver (or whatever the configured action is) |

## Regression checklist

Run before any release or after touching the dual-deliverable surface:

- [ ] `make pre-commit` clean
- [ ] `make health-quick` clean
- [ ] `make health` clean (or only intentional WARNs)
- [ ] UAT-01 through UAT-07 all green on a real session
- [ ] No new "Logo X.txt missing" warnings during randomized runs
- [ ] `~/.config/niri-screensaver/config` mtime advances on every plugin
      setting change
- [ ] Plugin manifest version bumped if any QML changed
- [ ] `CHANGELOG.md` `[Unreleased]` reflects every user-visible change

## Reporting bugs

Bug reports benefit from:

- `niri-screensaver-ctl status` output
- A few lines of `~/.config/niri-screensaver/config`
- `niri --version`, `alacritty --version`, `tte --version`
- Whether you're using the plugin or shelling out manually
