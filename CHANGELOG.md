# Changelog

All notable changes to **niri-screensaver** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Mirror mode: pixel-identical rendering across mismatched-resolution
  monitors (#14).** Two new config keys, `MIRROR_CANVAS_COLS` and
  `MIRROR_CANVAS_ROWS`, lock `tte`'s canvas to a fixed cell box in mirror mode
  (`--canvas-width`/`--canvas-height`, centered via the `--anchor-canvas c`
  already passed at every call site). Because the animated region is then the
  same cell grid on every output, `tte`'s deterministic RNG renders
  byte-identical animations even when the monitors differ in resolution —
  previously mirror only matched on equal-resolution outputs and otherwise
  played the same effect with a different layout. Opt-in: leave both empty (the
  default) to keep the full-screen, per-monitor canvas. Both must be positive
  integers to take effect; a blank, garbage, or half-set value falls back to
  full screen. Like `MIRROR_INTERVAL`, it's an advanced config-file knob and is
  not surfaced in the Noctalia plugin UI.

## [0.6.1] — 2026-06-03

### Added

- **Bats unit tests + kcov coverage.** A `test/` suite asserts the bash scripts'
  pure functions — effect-arg building, `load_config` defaulting, logo
  resolution/picking, toggle state, the kill-debounce (#4), battery gating, and
  mirror-mode argument assembly. Both bin scripts now guard `main "$@"` so they
  can be sourced for testing. A new CI job runs the suite under `kcov` and
  uploads line coverage to Codecov; `make unit` and `make coverage` run it
  locally (both skip with a hint when the tool is missing, same as the linters).

### Changed

- **Security and dev docs refreshed.** `SECURITY.md` now lists 0.6.x as
  supported (was 0.3.x) and documents the CI gates that guard the codebase.
  `TESTING.md` and `LINTING.md` cover the new unit suite and the coverage job.

## [0.6.0] — 2026-06-03

### Added

- **Multi-monitor mode: `independent` (default) or `mirror`.** New
  `MULTI_MONITOR_MODE` config key. `independent` keeps the existing behavior —
  each output runs its own driver and randomizes its own effect/logo. `mirror`
  makes every output show the *same* effect: the launcher rolls one RNG seed
  (and, when `RANDOM_LOGO` is on, picks one shared logo) and passes them to every
  driver via argv (`--seed`/`--logo`), since `niri msg action spawn` runs in the
  compositor's environment and would not inherit exported vars. Each driver seeds
  `tte` with `SEED + window`, where `window = wall-clock-seconds / MIRROR_INTERVAL`
  (default 8s) — deriving the effect window from the shared wall clock, not a
  per-process counter, is what keeps the monitors on the *same* effect at the
  same time even though the surfaces spawn at different moments and animate for
  different durations. `tte`'s deterministic RNG then renders identical
  animations on matched-resolution monitors; it degrades to "same effect,
  different layout" when resolutions differ. Surfaced in the Noctalia plugin as a
  **Multi-monitor mode** dropdown in the Effects section. Only applies with more
  than one output; single-monitor setups are unaffected.
- **Bar widget: left-click is now a smart toggle.** Clicking the Noctalia bar
  widget previously always launched the screensaver; it now stops it if it's
  already running and launches it otherwise, so it no longer has to be killed
  from a menu or the CLI. Backed by a new quiet `niri-screensaver-launch
  is-running` command (exit 0 if running, 1 if not; also forwarded by
  `niri-screensaver-ctl`) that the widget probes on click. Right-click still
  opens the full Trigger / Stop / Toggle / Settings menu.
- **Bar widget: Quit and Reload menu items.** The right-click menu gains
  **Quit** (stop the screensaver *and* disable it, so idle won't relaunch it
  until re-enabled) and **Reload** (stop the screensaver, restart the Noctalia
  shell so the systray reappears, and leave the screensaver enabled — a one-shot
  fresh start, run detached so it survives `qs kill`).

### Fixed

- **Multi-monitor: surfaces no longer collapse onto one output under
  `focus-follows-mouse`.** `niri-screensaver-launch` previously spread one
  Alacritty per output by cycling *keyboard* focus
  (`niri msg action focus-monitor-next`) between spawns. With niri's
  `input { focus-follows-mouse }`, window placement follows the *pointer*, not
  keyboard focus, and the pointer isn't parked until after the spawn loop — so
  every surface opened on the cursor's monitor and the others stayed blank. The
  launcher now enumerates outputs once up front and pins each spawned surface to
  its target output by window id
  (`niri msg action move-window-to-monitor --id <id> <output>`), which is
  independent of pointer/keyboard focus. Outputs are enumerated a single time so
  N>2 monitors and mid-launch hotplug are handled deterministically. A new
  `NIRI_SCREENSAVER_SPAWN_PIN_TIMEOUT_SECS` env var (default `2`) bounds how long
  the launcher waits for each surface to appear before moving on. Thanks to
  @landryjeanluc for the report and root-cause analysis (#11).
- **Multi-monitor: dismissing one screen now wakes all of them.** Each output
  runs its own driver in its own terminal, and a keypress only reaches the
  focused one — so on a multi-monitor setup, dismissing the active screen left
  the others still running the screensaver. The driver now broadcasts a
  terminate to its sibling instances on dismiss (`dismiss_all` →
  `terminate_sibling_drivers`, which SIGTERMs the other `niri-screensaver run`
  processes via a `/proc` scan that skips its own PID). Siblings exit through
  the normal signal path and do not re-broadcast, so there is no signal storm.
  Surfaced once #11's fix made surfaces actually spread across outputs.

## [0.5.9] — 2026-05-22

### Fixed

- A white cursor block briefly flashed at the end of each effect, just before
  the screensaver transitioned to the next one. `tte` re-shows the terminal
  cursor when an effect finishes, undoing our `tput civis`, and it lingered
  until the next loop iteration re-hid it. The driver now passes
  `--no-restore-cursor` to `tte` (when supported and `CURSOR_HIDE` is on) so the
  cursor stays hidden across the whole run.

## [0.5.8] — 2026-05-21

### Added

- **Sleep-on-battery threshold.** New `BATTERY_MIN_PERCENT` config key
  (default `0` = disabled). When set, `niri-screensaver-launch` skips
  auto-launch if the machine is running on battery below that percentage,
  to save power. Plugged in (any AC/Mains adapter online) or no battery
  present (desktop) never skips; `launch force` overrides the check.
  Surfaced in the Noctalia plugin as a new **Power** settings section
  ("Skip on battery below %"), and reported in `niri-screensaver-ctl
  status` when enabled. Battery state is read from
  `/sys/class/power_supply/*` by `type` (so adapter/battery naming is
  irrelevant); multiple batteries use the most-drained one. Verified
  end-to-end on real battery power (2026-05-21): the skip fires when on
  battery below the threshold and correctly proceeds when above-threshold,
  disabled (`0`), forced (`launch force`), or on AC — and the AC/battery
  state tracks the adapter live.

### Fixed

- `niri-screensaver-ctl effects` listed every TTE effect twice. `tte -h`
  prints the `{beams,...}` choices block twice (usage line + positional
  args); `get_effects` now takes only the first occurrence (`grep -m1`).

## [0.5.7] — 2026-05-18

### Documentation

- README "Creating your own" logo subsection now covers **layout**
  (centering behavior, trailing-whitespace gotcha, blank-line padding,
  icon+wordmark stacking) and includes a small size reference table.
  Existing tool recipes (`figlet`, `jp2a`, `chafa`, patorjk web
  generator) and the `LOGO_FILE=... niri-screensaver-ctl test` preview
  workflow are retained.
- `noctalia-plugin/README.md` Settings table rebuilt with a `Widget`
  column reflecting actual control types (toggle / spinbox / dropdown /
  text + Browse / button), and the previously-missing `LOGO_FILE`,
  `SHOW_NOW_PLAYING`, and `NOW_PLAYING_DURATION` rows added. New
  "Logos" section in the plugin README covers the dropdown's auto-
  refresh behavior, the effective-dir resolution order, and a concise
  layout/size primer that cross-links to the upstream README for the
  full guide.

### Added

- Noctalia plugin: dropdown selector for the logo file in the Logo
  settings section. Lists `*.txt` files from the effective logo
  directory (the `logoDir` override if set, else the installed
  `share/logos/`) and auto-refreshes when files are added or removed
  — no Noctalia restart needed. Disabled when "Random logo per cycle"
  is on, since the random picker overrides any specific selection.
  Previously the `logoPath` setting had no UI and was only editable by
  hand-editing the Noctalia settings JSON.
- Noctalia plugin: fade-in / fade-out effect controls are now
  `NComboBox` dropdowns populated at startup from
  `niri-screensaver-ctl effects` (deduped + sorted). First entry
  `(none)` clears the fade. Eliminates the silent-no-op when a typo'd
  effect name slipped past the free-text inputs.
- Noctalia plugin: "Logo directory" now uses `NTextInputButton` —
  text input on the left, folder icon on the right that opens
  Noctalia's `NFilePicker` in folder-select mode. The picker starts at
  your current `logoDir` if set, otherwise at the detected install
  path. Picking a folder fills the text input; the input stays
  editable for paste / type workflows.
- Noctalia plugin: Logo section moved above Effects in the Settings
  panel (matches typical edit frequency); within Logo, the file
  dropdown is now first, then Random toggle, then directory. `.txt`
  extensions are stripped from dropdown display names; combobox
  `minimumWidth` bumped to 320px to fit the longest shipped logo
  names without truncation.

### Changed

- Default seeded logo is now `niri-name-with-icon.txt` (was
  `framework-name-with-icon.txt`). Only affects fresh installs where
  `~/.config/niri-screensaver/logo.txt` does not yet exist; existing
  installs keep whatever logo was previously copied. To pick up the new
  default, delete `~/.config/niri-screensaver/logo.txt` and re-run
  `niri-screensaver-ctl` (or symlink any other logo from
  `share/logos/` — all are still installed).

## [0.5.6] — 2026-05-18

### Changed

- AUR PKGBUILD `optdepends` descriptions trimmed across both packages.
  Dropped parenthetical / env-var noise: `playerctl` no longer carries
  `(SHOW_NOW_PLAYING=true)`, `wlrctl` no longer carries `(recommended)`,
  and the `ydotool` / `figlet` blurbs are slightly shorter. The env
  var docs belong in the README, not in a pacman info pane. Cleaner
  output from `pacman -Qi` and `pacman -Si`. Also reduces the volume
  of false errors produced by CachyOS's `shelly` package manager,
  which has a parser bug that splits optdep descriptions on
  whitespace and treats each token as a separate package name
  (standard `pacman` / `paru` / `yay` were never affected).

## [0.5.5] — 2026-05-18

### Fixed

- AUR `.install` post-install messages and the README "Wire it into
  Noctalia" Option A now recommend `cp -r` instead of `ln -sfn` for
  the plugin into `~/.config/noctalia/plugins/niri-screensaver`. With
  a symlink, the plugin loads fine, but Noctalia's
  `PluginService.savePluginSettings()` writes via `sh -c "mkdir -p '<dir>'
  && cat > '<settings.json>' << HEREDOC ..."`, and that `cat >` fails
  with permission denied because `/usr/share/niri-screensaver/noctalia-plugin/`
  is `root:root 755`. The write is fire-and-forget via
  `Quickshell.execDetached`, so the user sees no error — they just
  notice their plugin Settings changes silently revert on Noctalia
  restart. Caught by an end-to-end install test on a fresh AUR install.
  Tradeoff of `cp -r` is that plugin updates from `pacman -Syu` don't
  auto-flow into the user copy; the new note in both the post-install
  message and the README tells users to re-run `cp -r` after upgrades.

## [0.5.4] — 2026-05-18

### Changed

- `install.sh` cache-refresh guards rewritten with explicit
  `if cmd; then action || true; fi` rather than
  `cmd && action || true` to satisfy stricter shellcheck (SC2015).
  Runtime behavior is identical — both forms no-op when the tool
  isn't installed and don't break the install on cache-refresh
  failure. Only the lint pattern changed. Caught by CI on a newer
  shellcheck version than the one shipped locally.
- AUR packaging scaffold (`packaging/aur/`) received pre-publish
  polish per a full pass against `AUR_submission_guidelines`:
  0BSD `LICENSE` per package dir (gates eligibility for official-
  repo promotion), whitelist `.gitignore` in the publish recipe
  (fail-closed against future file types accidentally landing in
  the AUR repo), obfuscated maintainer email, and a corrected
  first-time publish recipe using `git -c init.defaultBranch=master
  clone` since AUR only accepts pushes to `master`. None of this
  changes runtime behavior — strictly publishing hygiene.

## [0.5.3] — 2026-05-18

### Fixed

- `.desktop` "Preview an effect inline" action wrapped in
  `alacritty -e ...` so it works when invoked from a desktop
  launcher (Fuzzel, Anyrun, GNOME Activities, etc.). The
  underlying `niri-screensaver-ctl test` needs a TTY for `tte`
  to render; without the wrapper, launcher invocations silently
  no-op. CLI use was always fine. Alacritty is already a hard
  runtime dep, so no new dependency.

## [0.5.2] — 2026-05-18

### Added

- Desktop integration: `share/applications/niri-screensaver.desktop`
  and `share/icons/hicolor/scalable/apps/niri-screensaver.svg`. The
  `.desktop` entry exposes the primary `niri-screensaver-ctl launch`
  action plus two `Actions=` entries (Preview an effect inline,
  Enable/disable screensaver) so launchers like Fuzzel/Anyrun/Walker
  can right-click to the secondary actions. Icon is a charcoal-stroke
  variant of the existing plugin SVG so it stays visible across
  light and dark GTK/Qt themes (the plugin's `stroke="white"`
  version is intentional for Noctalia tinting and stays as-is). Both
  install.sh and the AUR PKGBUILDs ship them to their respective
  XDG paths and refresh `gtk-update-icon-cache` /
  `update-desktop-database` post-install (silent no-op if those
  tools aren't installed).
- AUR PKGBUILDs scaffolded under `packaging/aur/` — both
  `niri-screensaver` (stable, tracks tags; `pkgver=0.5.1` with the
  v0.5.1 tarball sha256 baked in) and `niri-screensaver-git` (HEAD,
  with a `pkgver()` that derives from `git describe`). Each ships a
  `$pkgname.install` post-install hook that points the user at the
  niri window-rule snippet, the Noctalia plugin symlink command, and
  the inline `noctalia-customCommand.json` fallback.
  Pre-generated `.SRCINFO` files included so AUR sync is a clean copy.
  `packaging/aur/.gitignore` excludes makepkg build artifacts (`pkg/`,
  `src/`, `*.pkg.tar.*`, fetched tarballs, etc.) so a stray
  `git add -A` from the repo root doesn't accidentally commit them.
  `packaging/aur/README.md` documents first-time publish and per-release
  update flow, including the structurally identical `.gitignore` that
  belongs in each AUR-side repo. All declared deps (`alacritty`,
  `niri`, `jq`, `python-terminaltexteffects`) plus optdeps
  (`noctalia-shell`, `playerctl`, `wlrctl`, `ydotool`, `figlet`)
  verified present in Arch repos or AUR. End-to-end test build
  confirmed: `makepkg --verifysource` passes, `makepkg -d` produces a
  92K `niri-screensaver-0.5.1-1-any.pkg.tar.zst` with the expected
  41-file layout, and the `-git` PKGBUILD's `pkgver()` resolves
  correctly to `<tag>.r<count>.g<short-hash>`.
- CI: `.github/workflows/release.yml` auto-creates a GitHub Release
  on any `v*` tag push. Pulls the matching `## [X.Y.Z]` section out of
  `CHANGELOG.md` via `awk` and feeds it to `gh release create
  --notes-file`. Falls back to the bare tag name if no matching section
  exists. Backfilled releases for v0.4.0/v0.5.0/v0.5.1 so the
  "Releases" sidebar reflects the actual ship history. Future cuts
  only require `git tag vX.Y.Z && git push origin vX.Y.Z`.

## [0.5.1] — 2026-05-18

### Fixed

- `niri-screensaver-launch` now debounces `kill` invocations that arrive
  within 3 seconds of `launch`. Under Noctalia (and likely other idle
  daemons that pair a `launchCommand` with a `resumeCommand`), spawning
  the fullscreen Alacritty triggers a Wayland focus/enter event that
  `ext-idle-notify-v1` reports as activity — causing the resume command
  to fire ~1 second after launch and tear the screensaver down before
  it renders. The launcher now writes a launch timestamp and drops `kill`
  invocations inside the debounce window. Tune via
  `NIRI_SCREENSAVER_KILL_DEBOUNCE_SECS` (set to `0` to disable). Fixes #4.

## [0.5.0] — 2026-05-18

### Added

- Now-playing overlay. When `SHOW_NOW_PLAYING=true` and `playerctl`
  reports a player as `Playing`, the inner driver renders the current
  track (`artist — title`) briefly between effect cycles, using the
  same figlet/centered-text path as the clock. Silently no-ops when
  `playerctl` isn't installed or no player is active. New config keys:
  `SHOW_NOW_PLAYING` (default `false`), `NOW_PLAYING_DURATION`
  (default `3`). Plugin gains a matching "Now playing" Settings
  section.
- `playerctl` listed as an optional dependency in the Requirements
  table and the per-distro install snippets.

### Changed

- Inner driver's figlet/plain centered-text rendering pulled out of
  `display_clock` into a shared `render_centered_text` helper, since
  the now-playing overlay reuses it. No user-visible change.

## [0.4.0] — 2026-05-18

### Added

- `niri-screensaver-ctl preview EFFECT` — friendlier wrapper for previewing
  a single named TTE effect inline. Same machinery as `test EFFECT`, but
  requires an explicit effect name (use `effects` to list available names).
  `test` keeps its existing "random if omitted" behavior.

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

[0.5.9]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.5.8...v0.5.9
[0.5.8]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.5.7...v0.5.8
[0.5.7]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.5.6...v0.5.7
[0.5.6]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.5.5...v0.5.6
[0.5.5]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.5.4...v0.5.5
[0.5.4]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.3.1...v0.4.0
[0.2.0]: https://github.com/jfreed-dev/niri-screensaver/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/jfreed-dev/niri-screensaver/releases/tag/v0.1.0
