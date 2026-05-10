# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
roughly tracks [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Niri logo set: real brand mark ASCII-ized from the official SVG (looks
  like a stylized "i" or, depending on how you read it, an owl), `NIRI`
  ANSI Shadow wordmark, scrolling-tiles representation of niri's
  signature layout, plus combined variants. Niri logo files are
  CC BY-SA 4.0 (carried over from upstream).
- Hyprland logo set: official teardrop ASCII-ized from
  `hyprwm/Hyprland/assets/hyprland.png`, `HYPRLAND` ANSI Shadow
  wordmark, and combined variant.

### Changed
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
- **Breaking:** logo file renames so the names match the actual content
  (all three are the same 8-lobed Framework cog at different sizes):
  `framework-gear.txt` → `framework-icon-medium.txt`,
  `framework-hex.txt` → `framework-icon-small.txt`,
  `framework-name-with-gear.txt` → `framework-name-with-icon-medium.txt`,
  `framework-name-with-hex.txt` → `framework-name-with-icon-small.txt`.
  If you had `LOGO_FILE` pointing at one of the old names, update it.
- All `framework-name-with-*.txt` files now end with the same single
  trailing blank line as every other logo file (cosmetic uniformity).

## [0.2.0] - 2026-05-08

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

## [0.1.0] - 2026-05-07

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
