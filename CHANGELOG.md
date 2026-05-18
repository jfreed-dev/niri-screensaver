# Changelog

All notable changes to **niri-screensaver** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] — 2026-05-18

### Added

- CI: three new gates wired into `.github/workflows/ci.yml` and
  `make check` — `typos` (spell-check, pinned to `crate-ci/typos@v1.46.1`),
  `markdownlint-cli2` (markdown hygiene, pinned to `@v23`), and
  `actionlint` (workflow YAML + embedded-script hygiene, pinned to
  `v1.7.12`). Each has a Makefile target that skips with an install
  hint when the tool isn't on `$PATH` locally, so a fresh clone still
  runs `make check` without forcing every contributor to install three
  extra linters. Dependabot already watches the workflows dir, so the
  pins will float upward via PR.
- `_typos.toml` and `.markdownlint-cli2.jsonc` — project-level config
  for the new linters, with comments explaining each disabled rule.
- `scripts/json-validate.sh` — extracts the inline json-validate step
  from CI so it's shellcheck-clean and reusable from `make`.

### Fixed

- CI: `json-validate` step previously globbed JSON paths with
  `for f in $(find …)` (SC2044) and `doc-links` inlined a regex that
  shellcheck false-positived as SC2016. Both replaced by calls to
  shipped scripts under `scripts/`, which are themselves shellcheck-gated.
- `SECURITY.md` and `CODE_OF_CONDUCT.md`: bare-email `MD034` violations
  fixed by wrapping the maintainer address in autolink brackets.
- `CHANGELOG.md`: each `### Heading` now has the required blank line
  before the first list item (`MD022`/`MD032`), so the file passes
  markdownlint without disabling the rule.
- `.github/ISSUE_TEMPLATE/bug_report.md`: status-output fence gains
  an explicit `text` language tag (`MD040`).

### Changed

- CI: all jobs moved from GitHub-hosted runners to the self-hosted
  `spark-niri-screensaver` runner (`runs-on: [self-hosted, linux]`).
  Cuts GitHub Actions minutes to zero for routine pushes; the runner
  image ships `shellcheck` so the lint job no longer needs an install
  step.

## [0.3.0] — 2026-05-12

### Fixed

- Launcher now parks the mouse pointer in the bottom-right corner after
  spawning the screensaver windows, via `wlrctl` (preferred) or `ydotool`
  if installed. Resolves the TODO `[bug] Mouse cursor handling during
  screensaver` — the pointer no longer sits visible on top of the
  animation. Combine with niri's `cursor { hide-after-inactive-ms 500 }`
  for a full hide. If neither tool is installed, the launcher logs a
  one-time hint.

### Added

- `.github/dependabot.yml` — weekly tracking of GitHub Actions versions
  in `.github/workflows/`. Dependabot will open PRs as referenced
  actions publish new releases, so the next Node-runtime / API
  deprecation gets chased automatically rather than by hand.
- `SECURITY.md` with supported-versions table and private vulnerability
  reporting policy.
- Plugin: `cliAvailable` detection in `Main.qml` and a CLI-missing
  banner at the top of `Settings.qml` — when `niri-screensaver-launch`
  isn't on `$PATH`, the plugin says so loudly instead of failing
  silently on every launch attempt.

### Changed

- Plugin: bumped to **0.3.0** (registry submission readiness).
- Plugin: `manifest.json` `repository` field now points to
  `noctalia-dev/noctalia-plugins` (matches the registry convention for
  PRs into the registry); upstream link remains in `README.md`.
- Plugin: tag set updated to `["Bar", "Utility", "Niri"]` — "Utility"
  fits the registry's tag taxonomy better than "System".
- Plugin: `preview.png` resized from 960×640 to 960×540 (16:9) to match
  the registry's required dimensions.
- Plugin: `Settings.qml` rewritten around the AGENTS.md edit-copy
  pattern — exposes a `saveSettings()` function (called by Noctalia on
  Save), with local `edit*` properties feeding `pluginSettings` only on
  save rather than per-keystroke. Raw `TextField` / `Button` / `SpinBox`
  swapped for `NTextInput` / `NButton` / `NSpinBox`.
- Plugin: `i18n/en.json` — added all placeholder strings (previously
  hardcoded literals in `Settings.qml`), `cli-missing` banner, and
  one-line descriptions for every user-visible setting; dropped the
  in-QML `tr() || k` fallback wrapper per AGENTS.md guidance.
- Plugin: `pluginSettingsChanged` handler in `Main.qml` is now debounced
  by 250ms. Live testing showed Noctalia's panel framework fires the
  signal ~5× per Apply click (once per changed property + once for the
  explicit save), which previously triggered 5 concurrent
  `writeConfigProcess` invocations writing identical content to
  `~/.config/niri-screensaver/config`. Single Timer in `Main.qml`
  collapses the burst into one disk write. `Component.onCompleted` and
  `onPluginApiChanged` still invoke `_syncAll()` directly for the eager
  first-run path.
- Plugin: `Settings.qml` refactored to use N* widgets' built-in
  `label` / `description` / `defaultValue` properties, removing the
  `RowLayout { NText + NToggle }` wrappers that produced inconsistent
  layouts. Matches the pattern used by reference plugins (clipper,
  timer, pomodoro). The `defaultValue` indicator now shows users when
  their value differs from the manifest default.
- Plugin: `README.md` rewritten for end-user / registry context —
  drops the obsolete "Custom registry source" install instructions
  that won't apply post-merge.

### Fixed

- **Plugin bug: CLI-missing banner used `Color.mErrorContainer` and
  `Color.mOnErrorContainer`, neither of which exists in
  `noctalia-shell`'s Color singleton.** Only `mError` / `mOnError` are
  defined. The banner would have rendered with undefined colors —
  effectively invisible. Swapped to the real tokens.
- **Plugin security: heredoc-EOF shell injection in `_writeShellConfig`.**
  Config values were interpolated into a `sh -c` heredoc with a fixed
  `__NIRI_SS_EOF__` marker, so a setting whose value contained that
  string would terminate the heredoc early and expose whatever followed
  to shell parsing. New implementation passes paths via positional
  arguments (`$1`/`$2` inside the script, never string-substituted)
  and uses a randomized, collision-checked heredoc marker. Also fixes
  the related issue where a `HOME` / `XDG_CONFIG_HOME` containing
  shell metacharacters would corrupt the write.
- Plugin: `_shEscape` was only escaping `"`; now also escapes
  backslash, `$`, and backtick, so values inside double-quoted shell
  strings can't break out of the quoting.
- Plugin: `Process` objects now have `onExited` handlers that log
  non-zero exits via `Logger.w` — previously, missing CLI / permission
  errors were silently swallowed.
- Plugin: `Component.onDestruction` now calls `Settings.saveImmediate()`
  after clearing the `customCommands` entry and hook slots, so a crash
  mid-cleanup can't leave Noctalia with stale state.
- Plugin: file paths now honor `XDG_CONFIG_HOME` before falling back to
  `$HOME/.config`.
- Plugin: launcher / kill `Process` invocations now use direct exec
  (`["niri-screensaver-launch", "launch"]`) when the user has not
  overridden the default, sidestepping the shell entirely. Falls back
  to `sh -c` only when the user has customized the command (where
  shell semantics may be intentional).
- Plugin: centralized launcher/kill defaults as `readonly property`
  declarations on Main.qml; BarWidget.qml and Settings.qml call back
  through `pluginApi.mainInstance._launcherArgv()` /
  `_killArgv()` rather than re-string-littering the defaults.
- `Makefile` and `scripts/health-check.sh` provide local CI parity:
  `make check` runs the same shellcheck + JSON validation + doc-link
  checks as `.github/workflows/ci.yml`; `make health` adds runtime /
  install-state checks. `make plugin-link` symlinks the plugin into
  Noctalia for hot-reload dev. `scripts/check-doc-links.sh` extracts
  the doc-link logic so the Makefile and CI can share it.
  `scripts/uninstall.sh` reverses `install.sh`.
- `docs/development/` directory with `SETUP.md`, `WORKFLOW.md`,
  `LINTING.md`, `TESTING.md`, and `UPSTREAM-SUBMISSION.md` (the last
  covering both the noctalia-plugins registry and the awesome-niri
  curated list).
- `share/logos/LICENSES.md` documents per-file attribution and
  trademark status for every bundled logo (BSD-3-Clause notice for
  Hyprland-derived ASCII; nominative-fair-use language for Framework
  and CachyOS marks).
- `README.md` gains a Trademarks section explicitly disclaiming
  affiliation with Framework, CachyOS, Hyprland, and niri.
- Niri logo set: ASCII art inspired by niri's stylized "i" / arguably
  owl-shaped brand mark, `NIRI` ANSI Shadow wordmark, scrolling-tiles
  representation of niri's signature layout, plus combined variants.
- Hyprland logo set: ASCII derivative of
  `hyprwm/Hyprland/assets/hyprland.png` (BSD-3-Clause; attribution in
  `share/logos/LICENSES.md`), `HYPRLAND` ANSI Shadow wordmark, and
  combined variant.

### Changed

- `CODE_OF_CONDUCT.md` replaced with the full Contributor Covenant v2.1
  text (was a 14-line abbreviated summary). Reports go to the maintainer
  email noted in the file.
- `CONTRIBUTING.md` gains standard `Reporting Issues` / `Code of Conduct`
  / `License` footer sections.
- `CHANGELOG.md` header re-aligned with sibling-project conventions
  (em-dash between version and date; "based on" / "adheres to" wording).
- Bar widget now ships its own monitor-with-image SVG icon
  (`assets/screensaver.svg`) instead of using a Tabler glyph.
  Tabler-style strokes (24×24 viewBox, 2px stroke, rounded caps) so it
  visually matches the other bar glyphs. Recolored at runtime via
  MultiEffect to follow the active Noctalia theme.
- Bar widget rebuilt from primitives (`Item` + `Rectangle` capsule +
  `Image` + `MouseArea`) rather than wrapping `NIconButton`. The
  capsule fill and border are driven by `Style.capsuleColor` /
  `Style.capsuleBorderColor`, so they respect the user's
  `bar.showCapsule` and `bar.showOutline` preferences — same as
  Battery, Volume, and Clock.
- Plugin `preview.png` refreshed: now shows the niri brand mark + NIRI
  wordmark settled mid-gradient, with the Noctalia bar visible at the
  top. Replaces the previous CACHYOS mid-glitch frame.
- README demo `docs/screensaver.gif` refreshed: 8-second loop of the
  niri brand mark fullscreen with one of TTE's particle/rain effects
  on the cyan-to-magenta gradient. Replaces the previous CACHYOS
  RANDOM_LOGO frame; same dimensions and similar file size.
- **Breaking:** logo file renames so the names match the actual content
  (all three are the same 8-lobed Framework cog at different sizes):
  `framework-gear.txt` → `framework-icon-medium.txt`,
  `framework-hex.txt` → `framework-icon-small.txt`,
  `framework-name-with-gear.txt` → `framework-name-with-icon-medium.txt`,
  `framework-name-with-hex.txt` → `framework-name-with-icon-small.txt`.
  If you had `LOGO_FILE` pointing at one of the old names, update it.
- All `framework-name-with-*.txt` files now end with the same single
  trailing blank line as every other logo file (cosmetic uniformity).
- `README.md` Logos section restructured: bundled logos now grouped by
  project (CachyOS / Framework / Hyprland / niri), tightened
  descriptions, in-table licensing claims removed (those live in
  `share/logos/LICENSES.md`).
- `README.md` niri-icon attribution corrected: previously claimed
  CC BY-SA 4.0 from upstream, but the niri repo (`niri-wm/niri`) does
  not publish a logo asset under any explicit license. Restated as
  community artwork inspired by niri's brand mark.

## [0.2.0] — 2026-05-08

### Added

- `RANDOM_LOGO` config key — when `true`, the inner driver picks a different
  logo from `LOGO_DIR` before each effect cycle. `LOGO_DIR` defaults to the
  installed `share/logos/` directory and can be overridden.
- Plugin Settings: new "Logo" section with a Random-logo toggle and an
  optional Logo-directory override.
- Plugin manifest gains `randomLogo` and `logoDir` to its `defaultSettings`.
- Real Framework logo: `framework-icon.txt` now ASCII-rendered from the
  official SVG (8-lobed cog with circular cutout). Two smaller size variants
  in `framework-gear.txt` (30×14) and `framework-hex.txt` (24×10) — all of
  the same canonical shape — plus matching `framework-name-with-*` combos.
- CachyOS logo set: `cachyos-icon.txt` (shield, lifted from fastfetch),
  `cachyos-name.txt` (CACHYOS ANSI Shadow wordmark), and
  `cachyos-name-with-icon.txt` combined.
- Mixed combo: `framework-name-with-cachyos-icon.txt` for CachyOS-on-Framework
  setups.
- README `## Logos` section documenting the full logo inventory and how to
  add custom files. README also gains a `## Requirements` table with
  per-distro install commands (Arch / Fedora / Debian).

### Changed

- Plugin Connections handler in `Main.qml` now watches the correct
  `pluginSettingsChanged` signal on `pluginApi`. Previously listened for
  invented signals (`onAnyChanged`) and per-key signals on a plain JS
  object, so user edits never triggered a re-sync until plugin reload.
- Bar widget icons changed from Material Symbols names (`bedtime`,
  `play_arrow`, `power_settings_new`) to Tabler equivalents (`moon`,
  `player-play`, `power`). Noctalia ships Tabler icons; unmatched names
  rendered as the literal `skull` fallback glyph.
- Plugin `i18n/en.json` restructured from flat dotted keys to nested
  objects, matching what Noctalia's `tr()` actually expects (it splits on
  `.` and walks nested properties).

### Fixed

- Inner driver no longer dies the instant Alacritty opens. Terminals reply
  to the script's OSC/DA queries asynchronously; the first byte of those
  replies is `\e`, which the dismiss-on-key read loop interpreted as the
  user pressing Escape. A 300 ms drain after enabling mouse tracking lets
  the replies arrive and be discarded before key listening starts.

## [0.1.0] — 2026-05-07

### Added

- Initial release. Terminal-based screensaver for Niri driven by
  TerminalTextEffects (`tte`) and rendered in a fullscreen Alacritty
  surface. Forked from cosmic-order's screensaver component, with
  COSMIC-specific glue replaced by niri-native equivalents.
- Three CLI scripts in `bin/`: `niri-screensaver` (inner driver),
  `niri-screensaver-launch` (per-output Alacritty spawner),
  `niri-screensaver-ctl` (launch/kill/toggle/status/test/effects).
- Noctalia plugin (`noctalia-plugin/`): Settings tab, bar widget,
  IdleService auto-wiring, screen-lock/unlock hook wiring, and
  `plugin:niri-screensaver` IPC surface.
- `install.sh` for user-local install (`~/.local`, override via
  `INSTALL_PREFIX=/usr/local`).
- `share/logos/` initial set: Framework square frame, FRAMEWORK wordmark,
  combined.

[0.2.0]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jfreed-dev/niri-screensaver/releases/tag/v0.1.0
