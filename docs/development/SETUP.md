# Development Environment Setup

How to set up a development environment for niri-screensaver. There is
no compile step — both deliverables (the bash CLI and the Noctalia QML
plugin) are interpreted, so "build" really means "have the right
runtime tooling installed."

## Prerequisites

### Operating System

- Any Linux distribution running a Wayland session under
  [niri](https://github.com/niri-wm/niri).
- Tested on CachyOS / Arch Linux. Should work on any distro that ships
  niri 0.x and the runtime dependencies below.

### Required runtime tools

| Tool | Why it's needed | Where to get it |
|------|-----------------|-----------------|
| niri | The compositor — only needed for full fullscreen runs (`niri-screensaver-ctl launch`). Inline `test` does not require niri. | <https://github.com/niri-wm/niri> |
| alacritty | Each fullscreen surface is an Alacritty window with `--class niri-screensaver`. | distro packages |
| terminaltexteffects (`tte`) | The animation engine. | `pip install --user terminaltexteffects` |
| jq | The launcher parses `niri msg --json outputs` to enumerate displays. | distro packages |
| python3 | Used by CI for JSON validation; `make json-validate` calls it. | distro packages |
| bash 5.x | All three CLI scripts. | distro packages |

For the Noctalia plugin side:

| Tool | Why |
|------|-----|
| [Noctalia](https://github.com/Ly-sec/Noctalia) | The shell that hosts the QML plugin. |
| Quickshell (`qs`) | What Noctalia is built on; needed if you want to manually re-launch the shell. |

### Required dev tools (CI parity)

| Tool | Used by |
|------|---------|
| shellcheck | `make shellcheck` and CI |
| python3 | `make json-validate` and CI |
| make | Convenience runner for local CI gates |

Distro install commands:

```bash
# Arch / CachyOS
sudo pacman -S alacritty jq python shellcheck make
pip install --user --break-system-packages terminaltexteffects

# Fedora
sudo dnf install alacritty jq python3 ShellCheck make
pip install --user terminaltexteffects

# Debian / Ubuntu
sudo apt install alacritty jq python3 shellcheck make
pip install --user terminaltexteffects
```

## Clone and install

```bash
git clone https://github.com/jfreed-dev/niri-screensaver
cd niri-screensaver
make install                 # → ~/.local (default)
# or
make install INSTALL_PREFIX=/usr/local
```

`make install` runs `install.sh`, which copies the three scripts into
`$INSTALL_PREFIX/bin/` and the alacritty config + logos into
`$INSTALL_PREFIX/share/niri-screensaver/`. Make sure `~/.local/bin` is
on your `$PATH`.

Verify:

```bash
make health-quick           # build/lint/structural — should pass on a clean tree
make health                 # adds runtime checks (niri, alacritty, tte, install state)
niri-screensaver-ctl status
niri-screensaver-ctl test   # render a single TTE effect inline (no fullscreen)
```

## Plugin development workflow

For active plugin work, **symlink** the source directory into Noctalia's
plugin path so QML edits hot-reload without re-installing:

```bash
make plugin-link            # creates ~/.config/noctalia/plugins/niri-screensaver -> $PWD/noctalia-plugin
```

Then in Noctalia: Settings → Developer → enable Debug. With Debug on,
saving a `.qml` file triggers a hot-reload in the running shell — no
restart needed.

To remove the dev symlink:

```bash
make plugin-unlink
```

To install the plugin "for real" (copy, not symlink), use Noctalia's
own plugin install flow against the `noctalia-plugin/` directory.

## Asset discovery (`NIRI_SCREENSAVER_DATA`)

The launcher and the inner driver both resolve sibling assets (the
alacritty config, the logos directory) through this candidate list:

1. `$NIRI_SCREENSAVER_DATA` (if set)
2. `$XDG_DATA_HOME/niri-screensaver` or `~/.local/share/niri-screensaver`
3. `<script-dir>/../share/niri-screensaver` — the dev-checkout fallback

For dev work where you want to use the in-tree assets without running
`make install`, export `NIRI_SCREENSAVER_DATA=$PWD/share`. New assets
should be discoverable through the same chain — see the candidate list
in `bin/niri-screensaver` (`DEFAULT_LOGO_CANDIDATES`) and
`bin/niri-screensaver-launch`.

## IDE setup

There's no language server requirement, but a few things make life
easier:

- **bash**: any editor with shellcheck integration. The project ships
  `.editorconfig` which sets 4-space indents for bash, 2-space for
  QML/JSON/KDL/TOML, tabs for Makefile.
- **QML**: VS Code's "Qt for Python" or the Quickshell-recommended QML
  plugins work fine. Quickshell has its own QML language server (`qmlls`)
  if you want completions on Quickshell-specific types.
- **Markdown**: `markdownlint` on save catches the kinds of formatting
  drift the doc-link checker won't.

## Troubleshooting

### `niri-screensaver-ctl test` exits immediately

The inner driver does an intentional 300 ms drain of stdin after
enabling mouse tracking — Alacritty's response to OSC/DA queries starts
with `\e`, and the keypress loop would otherwise interpret that byte as
the user pressing Escape. If you're testing inside a terminal that
doesn't respond to those queries (e.g. piping output), the drain is
harmless. If you've shortened or removed it, the symptom is "screensaver
dies the instant the surface opens." Don't remove the drain.

### Plugin settings don't propagate to the bash side

The plugin writes `~/.config/niri-screensaver/config` on every
`pluginSettingsChanged` signal. Two things commonly break this:

1. The `Connections { target: pluginApi }` handler must listen on
   `pluginApi` (a QObject with the actual signal), not on the plain JS
   `pluginSettings` object — JS objects have no `Changed` signal.
2. The plugin writes blank values for unset keys (e.g. `LOGO_FILE=""`),
   which means the bash side's `load_config` re-applies defaults *after*
   sourcing. Any config key with a path-shaped default needs the
   `: "${LOGO_FILE:=...}"` fallback pattern. See `bin/niri-screensaver`.

### `i18n/<lang>.json` keys don't translate

Noctalia's `tr()` walks dot-paths through *nested objects*. Flat dotted
keys like `"settings.idle.label": "Idle"` don't work. The `make
health-quick` check warns on flat dotted keys at the top level.

### `niri-screensaver-launch` says "no outputs"

`niri msg --json outputs` requires niri to be running and the calling
user to own the niri socket. If you're testing in an X11 session or
without niri, use `niri-screensaver-ctl test` instead — it bypasses the
launcher entirely.

## Next steps

- [WORKFLOW.md](WORKFLOW.md) — branching, commits, releases.
- [LINTING.md](LINTING.md) — what `make check` runs and why.
- [TESTING.md](TESTING.md) — UAT checklist before release.
- [UPSTREAM-SUBMISSION.md](UPSTREAM-SUBMISSION.md) — getting listed in
  `awesome-niri`.
