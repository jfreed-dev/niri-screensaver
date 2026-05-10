# Contributing

Thanks for considering a contribution. This is a small project — issues,
patches, and ideas all welcome.

## Getting set up

```bash
git clone https://github.com/jfreed-dev/niri-screensaver
cd niri-screensaver
./install.sh                # installs to ~/.local
```

For the Noctalia plugin, a symlink is the most ergonomic option while
hacking — Noctalia hot-reloads QML when its debug mode is on:

```bash
ln -s "$PWD/noctalia-plugin" ~/.config/noctalia/plugins/niri-screensaver
# Settings → Developer → Debug → enable to get hot-reload on QML edits
```

## Project layout

| Path | What's there |
|------|--------------|
| `bin/` | Three bash scripts: inner driver, launcher, ctl shim |
| `share/logos/` | ASCII-art logos (UTF-8 text files) |
| `share/alacritty-screensaver.toml` | Minimal Alacritty config the launcher passes |
| `noctalia-plugin/` | QML plugin (Main / Settings / BarWidget) + manifest + i18n |
| `docs/` | niri / Noctalia config snippets, demo media |

## Testing your change

| Change to | How to verify |
|-----------|---------------|
| `bin/niri-screensaver` | `niri-screensaver-ctl test` — single inline effect, no fullscreen |
| `bin/niri-screensaver-launch` | `niri-screensaver-launch launch` — full fullscreen run |
| Plugin QML | Toggle the plugin off/on in Noctalia Settings → Plugins; or restart `qs -c noctalia-shell` |
| Plugin settings persistence | Edit a value, watch `~/.config/niri-screensaver/config` mtime advance |
| New logo file | `niri-screensaver-ctl test` after pointing `LOGO_FILE` at it |

## Style conventions

- **Bash:** `set -uo pipefail` at the top; double-quote variable expansions; prefer
  `[[ ]]` to `[ ]`. Run `shellcheck bin/*` before sending a PR — CI runs the
  same. Inline comments only for non-obvious *why*.
- **QML:** match the surrounding 2-space indentation and the existing file's
  property-ordering style. Avoid invented signal handler names; if you need a
  property change to fire `Connections`, the target must be a `QObject` with
  an actual `Changed` signal (the plugin's `pluginSettings` is a JS object,
  not a QObject — listen on `pluginApi` instead).
- **Plugin i18n:** `i18n/<lang>.json` uses **nested objects** (Noctalia's
  `tr()` walks dot-paths). Don't use flat dotted keys.
- **Logos:** plain UTF-8, max ~88 cols wide for the wordmark + ~50 cols
  for the icon to keep things readable on smaller terminals. Match the
  existing 2-blank-leading / 1-blank-trailing convention.
- **Commit messages:** present-tense imperative ("Add foo", "Fix bar"),
  optional one-paragraph body explaining the *why*.

## Pull requests

1. Fork, branch off `main`.
2. One feature / fix per PR.
3. Update `CHANGELOG.md` under `## [Unreleased]` (create the section if
   missing).
4. If you touched user-visible behavior (a new config key, a new
   plugin setting, a new CLI option), update README.md too.
5. The PR template will prompt you for the rest.

## Reporting Issues

Use the issue templates in [.github/](.github/). Bug reports especially
benefit from `niri-screensaver-ctl status` output + a few lines of relevant
`~/.config/niri-screensaver/config` so we can reproduce locally. For
security-sensitive reports, follow [SECURITY.md](SECURITY.md) instead of
opening a public issue.

## Code of Conduct

Participation in this project is governed by the
[Code of Conduct](CODE_OF_CONDUCT.md).

## License

By submitting a pull request, you agree to license your contribution under
GPL-3.0-only. See [LICENSE](LICENSE).
