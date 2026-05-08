# Niri Screensaver — Noctalia plugin

A QuickShell/QML plugin for [Noctalia](https://github.com/noctalia-dev/noctalia-shell)
that drives the [niri-screensaver](../README.md) script package.

## What it provides

- A **Settings tab** under Noctalia's plugin settings: idle threshold, effect
  include/exclude lists, fade-in/out, clock toggle, manual trigger and stop
  buttons.
- **Auto-wires** the screensaver into Noctalia's `IdleService` by maintaining a
  `Niri Screensaver` entry in `Settings.data.idle.customCommands`. Toggle the
  plugin's "Enabled" switch to add or remove the entry without editing JSON.
- **Auto-wires** the `screenLock` and `screenUnlock` hook slots so the
  screensaver tears down cleanly when Noctalia's lock fires (avoids burning
  CPU under the lock surface). Only written when the slot is empty — never
  clobbers a hook you've authored. Requires Noctalia → Settings → Hooks to be
  enabled (the plugin does not flip that master toggle for you).
- **Persists** all settings to `~/.config/niri-screensaver/config` (the same
  shell-format config the script driver reads), so the plugin and the CLI
  stay in sync.
- A **bar widget**: click to trigger; right-click for stop / toggle / settings.
- An **IPC surface**: `plugin:niri-screensaver` exposes `launch`, `kill`,
  `toggle` — bind these to niri keybinds via `qs -c noctalia-shell ipc call
  plugin:niri-screensaver launch`.

The plugin does **not** ship the actual screensaver — it expects
`niri-screensaver-launch` to be on `$PATH` (run the repo's `install.sh` first).

## Install

Until this plugin lands in the official `noctalia-plugins` registry, install
manually as a custom plugin source.

### Option 1 — Custom registry source

Edit `~/.config/noctalia/plugins.json` and add this repo as a source:

```json
{
  "sources": [
    { "enabled": true, "name": "Noctalia Plugins",
      "url": "https://github.com/noctalia-dev/noctalia-plugins" },
    { "enabled": true, "name": "niri-screensaver",
      "url": "https://github.com/jfreed-dev/niri-screensaver" }
  ]
}
```

(Adjust the URL once the repo has a public remote.) Open Noctalia Settings →
Plugins → Available, find **Niri Screensaver**, install it.

### Option 2 — Local symlink (developing the plugin)

```bash
ln -s ~/Repos/niri-screensaver/noctalia-plugin ~/.config/noctalia/plugins/niri-screensaver
```

Then restart Noctalia: `pkill qs && qs -c noctalia-shell &`

## Files

```
manifest.json   Plugin metadata + defaultSettings.
Main.qml        Persistence + idle wiring + IPC handlers.
Settings.qml    Configuration UI rendered in Noctalia Settings.
BarWidget.qml   Status-bar capsule with click + context menu.
i18n/en.json    English strings.
```

## Hacking

Enable Noctalia's debug mode to get hot-reload on QML edits — Settings →
Developer → Debug. Then any change in this directory triggers a reload of
the plugin without restarting the shell.

The settings UI is intentionally minimal — extend it by editing
`Settings.qml`. The shape of `pluginApi.pluginSettings` is whatever you
declare in `manifest.json` under `metadata.defaultSettings`.
