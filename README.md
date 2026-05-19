# niri-screensaver

[![License: GPL v3](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/jfreed-dev/niri-screensaver)](https://github.com/jfreed-dev/niri-screensaver/releases)
[![AUR version](https://img.shields.io/aur/version/niri-screensaver?label=AUR)](https://aur.archlinux.org/packages/niri-screensaver)
[![CI](https://github.com/jfreed-dev/niri-screensaver/actions/workflows/ci.yml/badge.svg)](https://github.com/jfreed-dev/niri-screensaver/actions/workflows/ci.yml)

A terminal-based screensaver for [Niri](https://github.com/YaLTeR/niri), driven by
[TerminalTextEffects](https://github.com/ChrisBuilds/terminaltexteffects) and
designed to integrate with the [Noctalia](https://github.com/noctalia-dev/noctalia-shell)
desktop shell.

![Screensaver demo](docs/screensaver.gif)

> 8-second loop on CachyOS — the niri brand mark rendered with one of
> TTE's particle/rain effects on the cyan-to-magenta gradient.

Forked from [cosmic-order](https://github.com/jfreed-dev/cosmic-order)'s screensaver
component, with the COSMIC-specific glue (cosmic-randr, cosmic-greeter, the
focus-follows-cursor / autotile dance) stripped out and replaced with niri-native
equivalents. Idle, lock, and DPMS are deferred to Noctalia rather than reimplemented
in swayidle.

## Layout

```text
bin/
  niri-screensaver         Inner driver — runs TTE in the current terminal.
  niri-screensaver-launch  Spawns one fullscreen Alacritty per output, runs the driver inside.
  niri-screensaver-ctl     Thin shim: launch | kill | toggle | status | test | preview | effects.
share/
  alacritty-screensaver.toml  Minimal Alacritty config (black bg, no padding, hidden cursor).
  logos/                       ASCII art logos (Framework cog, CachyOS shield, combos). See `Logos` below.
docs/
  niri-window-rule.kdl         Snippet for ~/.config/niri/config.kdl.
  noctalia-customCommand.json  Snippet for ~/.config/noctalia/settings.json idle.customCommands.
noctalia-plugin/                Native Noctalia plugin (manifest + QML).
install.sh                     User-local install (defaults to ~/.local).
```

## Requirements

| Package | Required | Purpose |
|---------|----------|---------|
| `niri` | yes | The compositor; window-rule + `niri msg action spawn` |
| `alacritty` | yes | Host terminal for the fullscreen screensaver surface |
| `terminaltexteffects` (`tte`) | yes | Renders the actual effects |
| `jq` | optional | Used by the launcher to enumerate outputs |
| `figlet` | optional | Renders the between-effects clock and now-playing overlay |
| `playerctl` | optional | Source for the now-playing track display |
| `notify-send` (`libnotify`) | optional | Toggle / status notifications |

Install the dependencies for your distro:

```bash
# Arch / CachyOS
paru -S python-terminaltexteffects alacritty niri jq figlet libnotify playerctl

# Fedora / RHEL
sudo dnf install alacritty niri jq figlet libnotify playerctl
pipx install terminaltexteffects

# Debian / Ubuntu
sudo apt install alacritty jq figlet libnotify-bin playerctl
pipx install terminaltexteffects
# (niri may need a manual install on older releases)
```

The Noctalia plugin additionally requires Noctalia ≥ 4.7.0 (uses the plugin
API's `tr()` translation helper and Tabler icon names).

## Install

### Arch / CachyOS (AUR)

```bash
yay -S niri-screensaver         # stable, tracks tagged releases
# or
yay -S niri-screensaver-git     # tracks main HEAD
```

Substitute `paru` / `pikaur` / your AUR helper of choice. Either package
installs the bash CLI to `/usr/bin`, shared assets to
`/usr/share/niri-screensaver/`, the `.desktop` entry and hicolor icon
to the standard XDG paths, and prints a post-install message with the
remaining wire-up steps (niri window-rule, Noctalia plugin symlink).

The two packages `provides`/`conflicts` each other — install one or the
other, not both.

### Other distros / from source

```bash
./install.sh                             # installs into ~/.local
INSTALL_PREFIX=/usr/local ./install.sh   # system-wide
```

This deploys the three `bin/` scripts and the `share/` assets (Alacritty
config + logos + `.desktop` entry + hicolor icon). It does **not**
install the niri window-rule or the Noctalia plugin — those are separate
steps below.

### Verify

```bash
niri-screensaver-ctl status
niri-screensaver-ctl test     # render one effect inline (no fullscreen)
```

## Wire it into Niri

Append the contents of `docs/niri-window-rule.kdl` to your `~/.config/niri/config.kdl`.
The rule matches `app-id="niri-screensaver"` and applies `open-fullscreen true`,
which is how the launcher achieves fullscreen without an Alacritty CLI flag.

## Wire it into Noctalia

Three options, from least to most friction.

The plugin adds a Settings tab, a bar widget, and auto-registers the
screensaver in Noctalia's `IdleService` when enabled.

![Plugin bar widget with screensaver running](noctalia-plugin/preview.png)

> Niri logo mid-gradient with the Noctalia bar visible at the top — the
> plugin's bar widget (custom monitor-with-image icon, far left of the
> tray cluster) launches the screensaver on click.

### Option A — Copy the AUR-shipped plugin (Arch / CachyOS, recommended)

If you installed via the AUR package above, the plugin source is already
on disk at `/usr/share/niri-screensaver/noctalia-plugin/`. Copy it into
Noctalia's per-user plugin dir:

```bash
mkdir -p ~/.config/noctalia/plugins
cp -r /usr/share/niri-screensaver/noctalia-plugin \
      ~/.config/noctalia/plugins/niri-screensaver
```

Then enable it in **Noctalia → Settings → Plugins**.

> **Why `cp -r` and not `ln -sfn`** — Noctalia writes plugin settings
> back into the plugin dir on every toggle in the Settings tab. The
> AUR-shipped tree under `/usr/share/` is root-owned, so a symlinked
> plugin loads fine but silently fails to persist any user-changed
> settings (defaults always come back on Noctalia restart). The cost
> of using `cp -r` is that plugin updates from `pacman -Syu` don't
> auto-flow — re-run the `cp -r` after each upgrade if you want the
> latest plugin code.

### Option B — Install from the Noctalia plugin registry (any distro)

Open **Noctalia → Settings → Plugins**, find `niri-screensaver` in the
registry browser, install. The plugin lands in
`~/.config/noctalia/plugins/`.

Note: the registry ships only the plugin's QML files. The bash CLI
(`niri-screensaver-launch` and friends) is a separate install — use the
AUR package on Arch / CachyOS, or `./install.sh` from this repo on other
distros. If the CLI is missing, the plugin's Settings tab shows a
"install niri-screensaver first" banner.

### Option C — Manual JSON edit (no plugin)

If you don't want the Noctalia plugin (no Settings UI, no bar widget),
just wire the idle trigger directly: copy the relevant fields from
`docs/noctalia-customCommand.json` into `~/.config/noctalia/settings.json`
under the `idle` object. After saving, restart Noctalia (`pkill qs` then
re-launch `qs -c noctalia-shell`) to pick up the new idle hook.

## Usage

```bash
niri-screensaver-ctl launch    # trigger now
niri-screensaver-ctl kill      # stop
niri-screensaver-ctl status    # report state
niri-screensaver-ctl toggle    # disable / re-enable the launcher
niri-screensaver-ctl test           # run a single random effect inline (no fullscreen)
niri-screensaver-ctl preview rain   # preview a specific named effect inline
niri-screensaver-ctl effects        # list all TTE effects
```

## Configuration

`~/.config/niri-screensaver/config` is sourced as shell. Keys:

| Key | Default | Notes |
|-----|---------|-------|
| `FRAME_RATE` | `60` | TTE frame rate |
| `INCLUDE_EFFECTS` | _empty_ | Comma-separated effect names; takes precedence over excludes |
| `EXCLUDE_EFFECTS` | `dev_worm` | Comma-separated effects to skip |
| `FADE_IN_EFFECT` | _empty_ | One-shot effect on launch (e.g. `expand`, `slide`) |
| `FADE_OUT_EFFECT` | _empty_ | One-shot effect on dismiss (e.g. `burn`, `crumble`) |
| `SHOW_CLOCK` | `false` | Render time between effects |
| `CLOCK_DURATION` | `3` | Seconds to display the clock |
| `CLOCK_FORMAT` | `%H:%M` | strftime format string |
| `CLOCK_FONT` | _empty_ | figlet font name (shared with the now-playing overlay) |
| `SHOW_NOW_PLAYING` | `false` | Render the playerctl track title between effects (no-op if `playerctl` is missing or nothing is playing) |
| `NOW_PLAYING_DURATION` | `3` | Seconds to display the now-playing overlay |
| `CURSOR_HIDE` | `true` | Hide the *text* cursor (`tput civis`) |
| `DISMISS_ON_KEY` | `true` | Any key dismisses; ESC and mouse always dismiss |
| `RANDOM_LOGO` | `false` | When `true`, pick a random `*.txt` from `LOGO_DIR` before each effect cycle |
| `LOGO_DIR` | _empty_ | Directory the random picker scans. Defaults to the installed `share/logos/` |

On launch, the launcher parks the mouse pointer in the bottom-right corner via
`wlrctl` (preferred) or `ydotool` if either is installed. For a full hide,
combine with niri's `cursor { hide-after-inactive-ms 500 }` so the parked
pointer disappears after the idle window. With neither tool installed, the
launcher logs a one-time hint and falls back to niri-only auto-hide.

## Logos

`share/logos/` ships ready-to-use ASCII art. Point `LOGO_FILE` at one of them
in `~/.config/niri-screensaver/config` (or via the Noctalia plugin's Settings
panel) — or symlink your favorite to the active path:

```bash
ln -sf ~/.local/share/niri-screensaver/logos/framework-name-with-icon-medium.txt \
       ~/.config/niri-screensaver/logo.txt
```

### CachyOS

| File | Contents |
|------|----------|
| `cachyos-icon.txt` | CachyOS shield |
| `cachyos-name.txt` | `CACHYOS` ANSI Shadow wordmark |
| `cachyos-name-with-icon.txt` | Shield + wordmark |

### Framework

| File | Contents |
|------|----------|
| `framework-icon.txt` | 8-lobed Framework cog (40×18) |
| `framework-icon-medium.txt` | Same cog (30×14) |
| `framework-icon-small.txt` | Same cog (24×10) |
| `framework-name.txt` | `FRAMEWORK` ANSI Shadow wordmark |
| `framework-name-with-icon.txt` | Cog (40×18) + wordmark |
| `framework-name-with-icon-medium.txt` | Cog (30×14) + wordmark |
| `framework-name-with-icon-small.txt` | Cog (24×10) + wordmark |
| `framework-name-with-cachyos-icon.txt` | CachyOS shield + `FRAMEWORK` wordmark — for CachyOS-on-Framework setups |

### Hyprland

| File | Contents |
|------|----------|
| `hyprland-icon.txt` | Hyprland teardrop |
| `hyprland-name.txt` | `HYPRLAND` ANSI Shadow wordmark |
| `hyprland-name-with-icon.txt` | Teardrop + wordmark |

### niri

| File | Contents |
|------|----------|
| `niri-icon.txt` | Stylized "i" / arguably owl-shaped niri brand mark |
| `niri-name.txt` | `NIRI` ANSI Shadow wordmark |
| `niri-name-with-icon.txt` | Icon + wordmark |
| `niri-tiles.txt` | Five scrolling-tile columns — niri's signature layout |
| `niri-name-with-tiles.txt` | Tiles + wordmark |

Per-file attribution, licensing, and trademark notes are in
[share/logos/LICENSES.md](share/logos/LICENSES.md).

### Adding your own

Drop any UTF-8 text file into `~/.local/share/niri-screensaver/logos/`
(or `share/logos/` in the repo) and point `LOGO_FILE` at it. TTE
renders any text content; block characters (`█`) and ANSI Shadow
letters look best.

## Trademarks

niri-screensaver is **not affiliated with or endorsed by** Framework
Computer Inc., the CachyOS project, the Hyprland project, or the niri
project. Brand marks rendered in `share/logos/` belong to their
respective owners and are referenced for the convenience of users who
own / run those products. The Hyprland-derived ASCII carries the
upstream BSD-3-Clause attribution; Framework and CachyOS marks are
provided for nominative use only. See
[share/logos/LICENSES.md](share/logos/LICENSES.md) for per-file detail.

If you are a brand owner and would like a logo removed or the
attribution adjusted, please open an issue.

## What was dropped from cosmic-order

- The 1500-line `screensaver-ctl.sh` (swayidle config generator, systemd unit
  installer, lock command setup) — Noctalia owns idle/lock/DPMS now.
- The `disable_compositor_interference` block (focus_follows_cursor / autotile
  poking) — niri doesn't have the focus-stealing problem.
- The `ydotool` Super+F injection to toggle fullscreen — replaced by niri
  window-rule with `open-fullscreen true`.
- Ghostty-specific config generation; replaced with a single Alacritty TOML.
- cosmic-randr monitor enumeration; replaced with `niri msg --json outputs`.
- `cosmic-greeter --lock`; Noctalia's native lock is invoked via `loginctl
  lock-session` or directly through Noctalia's IdleService.
- Power-aware effect profiles (UPower D-Bus). Add back via the Noctalia plugin
  if you want them.

## License

GPL-3.0-only (carried over from cosmic-order).
