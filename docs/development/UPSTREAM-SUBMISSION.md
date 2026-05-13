# Upstream Submission

niri-screensaver has two reasonable upstream listings, with different
audiences:

| Target | What it lists | Audience |
|--------|---------------|----------|
| [`noctalia-dev/noctalia-plugins`](https://github.com/noctalia-dev/noctalia-plugins) | Just the QML plugin (Bar widget + idle wiring) | Noctalia users browsing the Plugin Manager |
| [`niri-wm/awesome-niri`](https://github.com/niri-wm/awesome-niri) | The whole project (CLI + plugin together) | Anyone using niri who finds it via the curated list |

Both are PR-driven against external repos. Submit to **noctalia-plugins
first** — getting indexed in Noctalia's Plugin Manager surfaces the
project to the most relevant audience. The awesome-niri PR is a
one-liner you can do anytime after.

---

## Path A — noctalia-dev/noctalia-plugins (primary)

Noctalia's Plugin Manager pulls plugins from the registry repo, so
landing here makes installation a one-click flow for users.

### Pre-submission checklist

Match Noctalia's [registry README](https://github.com/noctalia-dev/noctalia-plugins/blob/main/README.md)
expectations and validate against [schema.json](https://github.com/noctalia-dev/noctalia-plugins/blob/main/schema.json):

- [ ] `noctalia-plugin/manifest.json` has every schema-required key:
      `id`, `name`, `description`, `version`, `author`. Conventional
      additions: `repository`, `license`, `minNoctaliaVersion`, `tags`,
      `entryPoints`, `metadata`. `make health-quick` checks this.
- [ ] `id` matches the registry directory name we'll create
      (`niri-screensaver`) and is `[a-zA-Z\-]+`.
- [ ] `description` is under ~100 characters.
- [ ] `tags` are valid registry tags. Current set:
      `["Bar", "Utility", "Niri"]`.
- [ ] **`preview.png` is exactly 960×540 (16:9).** Confirm with
      `file noctalia-plugin/preview.png`. Memory note
      `recording_screensaver_gifs.md` has the capture recipe if it
      needs to be regenerated.
- [ ] `noctalia-plugin/README.md` documents what the plugin does, with
      at least one screenshot (the `preview.png` is fine).
- [ ] Tested on a Noctalia version ≥ `minNoctaliaVersion` in the
      manifest.
- [ ] **`repository` field must be exactly
      `https://github.com/noctalia-dev/noctalia-plugins`.** The
      registry's `check-manifest.yml` CI hard-fails any other value as
      a high-priority issue. Upstream-project link lives in
      `noctalia-plugin/README.md` instead.
- [ ] QML passes the registry's `code-quality.yml` regex traps:
      no hardcoded numeric `border|spacing|pointSize|radius|margin`
      literals, no `console.log`, no bare `Text|Button|Checkbox|Switch`
      (use the `N*` widgets), no `pluginApi?.tr(…) || …` fallbacks, no
      hardcoded `text|label|description: "..."` (use `pluginApi?.tr()`).
      Required root properties on `Main.qml`, `BarWidget.qml`,
      `Settings.qml`, etc. — see the workflow source for the exact
      regex per component.

### Submission steps

```bash
# 1. Fork the registry
gh repo fork noctalia-dev/noctalia-plugins --clone --remote
cd noctalia-plugins

# 2. Copy the plugin into a directory matching the manifest 'id'.
#    The --exclude is important: noctalia-plugin/settings.json is
#    Noctalia's runtime cache (gitignored upstream); a plain `cp -r`
#    would silently include it and registry CI doesn't flag it.
mkdir niri-screensaver
rsync -a --exclude='settings.json' \
  ~/Repos/niri-screensaver/noctalia-plugin/ niri-screensaver/

# 3. Verify the manifest has the schema-required keys (CI runs this
#    against schema.json on PR open; this is a faster local check).
python3 - <<'PY'
import json
m = json.load(open('niri-screensaver/manifest.json'))
required = {'id', 'name', 'description', 'version', 'author'}
missing = required - m.keys()
assert not missing, f"missing schema-required keys: {missing}"
assert m['id'] == 'niri-screensaver'
assert m['repository'] == 'https://github.com/noctalia-dev/noctalia-plugins', \
    "repository must point to the registry — CI hard-fails any other value"
print("manifest OK")
PY

# 4. Branch, commit, push, PR
git checkout -b add-niri-screensaver
git add niri-screensaver/
git commit -m "feat: add niri-screensaver plugin"
git push -u origin add-niri-screensaver
gh pr create --title "feat: add niri-screensaver plugin" \
  --body "$(cat <<'BODY'
## Summary
Adds the `niri-screensaver` plugin — an idle-aware terminal
screensaver for niri, driven by TerminalTextEffects. Wires Noctalia's
IdleService to a small bash CLI that spawns one fullscreen Alacritty
per output via niri's window-rule on `app-id="niri-screensaver"`.

## Features
- Bar widget toggles the screensaver on/off, reflects running state.
- Settings panel exposes effect filters, fade-in/out, clock, random
  logo picker, dismiss-on-key, idle threshold.
- 14 TTE effects pre-tuned for screensaver use; per-effect canvas
  fitting; multi-monitor coverage.

## Requirements
- niri (the plugin shells out to `niri msg` for output enumeration).
- The companion bash CLI (`niri-screensaver-launch`) shipped from the
  upstream repo below.
- TerminalTextEffects (`tte`) and Alacritty.

## Links
- Upstream: https://github.com/jfreed-dev/niri-screensaver
- License: GPL-3.0-only
- Min Noctalia: 4.7.0

Manifest validates against schema.json; preview.png is 960×540.
BODY
)"
```

The registry's CI auto-updates `registry.json` when manifests change,
so you don't edit that file by hand.

### Post-merge

- Update `README.md`'s Quick Start / Install section to reference the
  Plugin Manager flow (e.g. "Install via Noctalia → Plugins → Browse").
- Add a `Listed in:` badge or section linking to the registry entry.
- Bump `noctalia-plugin/manifest.json` `version` for any subsequent QML
  change — Noctalia's Plugin Manager uses that version to flag updates.

---

## Path B — niri-wm/awesome-niri

A one-line entry in the curated list at
<https://github.com/niri-wm/awesome-niri>.

### Format rules

Per [awesome-niri/CONTRIBUTING.md](https://github.com/niri-wm/awesome-niri/blob/main/CONTRIBUTING.md):

- Format exactly: `[Resource Title](url) - description.`
  (Note the **ASCII hyphen** ` - `, with a space on each side. The
  upstream `CONTRIBUTING.md` confusingly shows an em dash in its example,
  but `awesome-lint`'s `awesome-list-item` rule actively rejects
  en/em dashes with `List item link and description separated by invalid
  en-dash or em-dash`. Every existing entry in the README uses hyphen.)
- Sort entries alphabetically by title within their section.
- Keep the description short and simple.
- Capitalization rule: write **niri** in lowercase in descriptions.
  Capitalized "Niri" is OK in titles where the project is named that
  way. Reframe sentences so they don't start with the word.
- One PR per suggestion.
- The repo runs [awesome-lint](https://github.com/sindresorhus/awesome-lint);
  basic formatting must pass.

### Choosing a section

Likely fit: **Tools → System Integration and Automation** (the section
already lists `Stasis`, an idle manager, which is the closest analog).
Alternative: a new **Wallpapers and Visuals** sub-bullet, but that
section currently focuses on wallpapers, not screensavers.

A draft entry to add at the right alphabetical position (between
`niri-autoselect-portal` and `nirilayout`):

```markdown
- [niri-screensaver](https://github.com/jfreed-dev/niri-screensaver) - Idle-aware terminal screensaver for niri, driven by TerminalTextEffects, with an optional Noctalia plugin for IdleService integration.
```

### Submission steps

```bash
# 1. Fork. `gh repo fork` rejects --remote when a repo arg is provided;
#    cloning alone sets origin=fork and adds upstream=original.
gh repo fork niri-wm/awesome-niri --clone
cd awesome-niri

# 2. Edit README.md — add the entry in the right section, alphabetical
$EDITOR README.md

# 3. Run awesome-lint locally. Not optional — CI runs the same rules and
#    will block on awesome-list-item (em-dash / no-period / etc.) before
#    a maintainer even sees the PR.
npx awesome-lint

# 4. Branch, commit, PR
git checkout -b add-niri-screensaver
git add README.md
git commit -m "Add niri-screensaver"
git push -u origin add-niri-screensaver
gh pr create --title "Add niri-screensaver" \
  --body "Idle-aware terminal screensaver for niri, driven by TerminalTextEffects. Ships a small bash CLI plus a Noctalia plugin that wires IdleService → screensaver. GPL-3.0-only. https://github.com/jfreed-dev/niri-screensaver"
```

---

## Maintenance after acceptance

When you cut a new release of niri-screensaver:

1. **noctalia-plugins**: open a follow-up PR there only if the QML
   changed *and* you bumped `manifest.json` `version`. The registry's
   CI will pick up the version bump and flag the update for users.
2. **awesome-niri**: usually no follow-up needed unless the project
   description changes materially or the URL moves. If you rename the
   repo, open a PR that updates the link.

Both repos appreciate one PR per change — don't bundle.

## If something is rejected

- **noctalia-plugins** PRs sometimes ask for tag adjustments or
  manifest tweaks. Address inline; the registry team is responsive.
- **awesome-niri** has stricter format rules (alphabetical, em dash,
  lowercase niri); re-read [their CONTRIBUTING.md](https://github.com/niri-wm/awesome-niri/blob/main/CONTRIBUTING.md)
  if the lint job fails.
