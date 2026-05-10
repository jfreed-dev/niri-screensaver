# Niri Screensaver

Idle-aware terminal screensaver for [niri](https://github.com/niri-wm/niri),
driven by [TerminalTextEffects](https://github.com/ChrisBuilds/terminaltexteffects)
and rendered in a fullscreen Alacritty surface.

![Preview](preview.png)

## What this plugin does

- **Auto-registers a screensaver entry** in Noctalia's
  `Settings.data.idle.customCommands` based on an Enabled toggle, so the
  screensaver kicks in after your configured idle threshold without manual
  JSON edits.
- **Auto-wires the screenLock / screenUnlock hook slots** so the screensaver
  tears down cleanly when Noctalia's lock fires (avoids burning CPU under the
  lock surface). Only writes to hook slots that are empty or already hold the
  plugin's command — never clobbers a hook you authored manually.
- **Bar widget**: click to trigger; right-click for stop / toggle enabled /
  open settings. Recolors to follow the active Noctalia theme.
- **Settings tab** for idle threshold, effect include/exclude lists,
  fade-in/out, clock, random-logo picker, and a manual trigger/stop pair.
- **IPC surface** `plugin:niri-screensaver` exposing `launch`, `kill`,
  `toggle` — bind to niri keybinds via
  `qs ipc call plugin:niri-screensaver launch`.
- **Writes settings** to `~/.config/niri-screensaver/config` (XDG-aware) in
  shell `KEY="value"` format — the same file the bash CLI reads. The plugin
  and the CLI stay in lockstep.

## Requires the bash CLI

This plugin **does not ship** the actual screensaver. It expects
`niri-screensaver-launch` on `$PATH`. Install it first from
<https://github.com/jfreed-dev/niri-screensaver>:

```bash
git clone https://github.com/jfreed-dev/niri-screensaver
cd niri-screensaver
./install.sh                 # → ~/.local/bin
```

Also requires `alacritty` and the `tte` Python CLI on PATH (`pip install
--user terminaltexteffects`). If the CLI is missing the plugin surfaces a
banner at the top of its settings panel.

## Compositor support

niri-specific. The launcher enumerates outputs via `niri msg --json outputs`
and relies on niri's window-rule on `app-id="niri-screensaver"` for
fullscreen. Won't work on Hyprland / Sway / labwc without porting.

## Settings

Each field in the plugin's Settings tab maps to a key in the shell-format
config the bash CLI reads. Changing a value writes the file on save and
re-syncs the idle hook.

| UI label | Shell key | Default |
|---|---|---|
| Enabled | (registers an entry in `Settings.data.idle.customCommands`) | `true` |
| Idle threshold (seconds) | sets `timeout` of that customCommand | `300` |
| Include effects (CSV) | `INCLUDE_EFFECTS` | _empty_ |
| Exclude effects (CSV) | `EXCLUDE_EFFECTS` | `dev_worm` |
| Fade-in effect | `FADE_IN_EFFECT` | _empty_ |
| Fade-out effect | `FADE_OUT_EFFECT` | _empty_ |
| Random logo per cycle | `RANDOM_LOGO` | `false` |
| Logo directory | `LOGO_DIR` | _empty_ |
| Show clock between effects | `SHOW_CLOCK` | `false` |
| Clock format (strftime) | `CLOCK_FORMAT` | `%H:%M` |
| Trigger now | (runs `launcherCommand`) | `niri-screensaver-launch launch` |
| Stop | (runs `killCommand`) | `niri-screensaver-launch kill` |

Settings not surfaced in the UI (`FRAME_RATE`, `CLOCK_DURATION`,
`CLOCK_FONT`, `CURSOR_HIDE`, `DISMISS_ON_KEY`) can be edited directly in
`~/.config/niri-screensaver/config` — they round-trip through the plugin on
next reload.

## License

GPL-3.0-only. See [LICENSE](https://github.com/jfreed-dev/niri-screensaver/blob/main/LICENSE)
in the upstream repo.
