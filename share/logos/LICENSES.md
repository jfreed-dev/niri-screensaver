# Logo Attribution

This directory ships ASCII-art logos derived from third-party project
brand marks. niri-screensaver itself is GPL-3.0-only (see [LICENSE](../../LICENSE));
the *content* of individual `.txt` files in this directory carries the
licensing / trademark status documented below.

niri-screensaver is **not affiliated with or endorsed by** any of the
projects listed here. Brand marks are referenced for the convenience of
users who want recognizable iconography on their screensaver. If you are
a brand owner and would like a logo removed or the attribution adjusted,
open an issue at
<https://github.com/jfreed-dev/niri-screensaver/issues>.

---

## niri (community Wayland compositor)

| File | Status |
|------|--------|
| `niri-icon.txt` | ASCII art inspired by niri's stylized "i" brand mark. Not a verbatim trace of any specific officially-released SVG asset. |
| `niri-name.txt` | "NIRI" rendered in the [figlet](http://www.figlet.org/) "ANSI Shadow" font. Typefaces are not copyrightable in the United States. |
| `niri-name-with-icon.txt` | Composition of the two above. |
| `niri-tiles.txt` | Original artistic representation of niri's scrolling-tile workspace layout. CC0 / public domain dedication for this file. |
| `niri-name-with-tiles.txt` | Composition of `niri-tiles.txt` + the wordmark. |

niri itself is hosted at <https://github.com/YaLTeR/niri> (GPL-3.0).
"niri" is a project name belonging to the niri community; trademark
status is informal / not registered to our knowledge. These files are
provided in good faith as community artwork.

---

## Hyprland

| File | Status |
|------|--------|
| `hyprland-icon.txt` | ASCII derivative of `hyprwm/Hyprland/assets/hyprland.png`. |
| `hyprland-name.txt` | "HYPRLAND" rendered in figlet "ANSI Shadow". |
| `hyprland-name-with-icon.txt` | Composition of the two. |

Upstream Hyprland is BSD-3-Clause licensed
(<https://github.com/hyprwm/Hyprland>). The repository LICENSE applies
repo-wide and includes the asset at `assets/hyprland.png`. The
ASCII derivative carries the same notice:

```text
BSD 3-Clause License

Copyright (c) 2022-2026, vaxerski
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met: [...]  See the upstream LICENSE at
https://github.com/hyprwm/Hyprland/blob/main/LICENSE for the full text.
```

---

## Framework Computer Inc.

| File | Status |
|------|--------|
| `framework-icon.txt` | ASCII derivative of Framework's 8-lobed cog logo (40×18). |
| `framework-icon-medium.txt` | Same shape, 30×14. |
| `framework-icon-small.txt` | Same shape, 24×10. |
| `framework-name.txt` | "FRAMEWORK" rendered in figlet "ANSI Shadow". |
| `framework-name-with-icon*.txt` | Compositions of the above. |
| `framework-name-with-cachyos-icon.txt` | Composition with CachyOS shield (see CachyOS section). |

The Framework cog and the "Framework" name are **trademarks of Framework
Computer Inc.** Framework's logo is not released under an open-source
license; these ASCII derivatives are provided for **nominative use** —
identification of Framework hardware by its owners — and do not imply
endorsement, sponsorship, or affiliation. Users who do not own a
Framework laptop should consider not using these logos.

If you are Framework Computer Inc. and want these removed, please open
an issue or email the contact in
[SECURITY.md](../../SECURITY.md).

---

## CachyOS

| File | Status |
|------|--------|
| `cachyos-icon.txt` | ASCII derivative of the CachyOS shield (originally bundled with [fastfetch](https://github.com/fastfetch-cli/fastfetch)). |
| `cachyos-name.txt` | "CACHYOS" rendered in figlet "ANSI Shadow". |
| `cachyos-name-with-icon.txt` | Composition. |

The CachyOS shield is the brand mark of the **CachyOS project**
(<https://cachyos.org>). fastfetch is MIT-licensed, but its license
covers fastfetch's code, not the upstream distro brand marks bundled
with it. These ASCII derivatives are provided for nominative use by
CachyOS users on their own systems.

---

## A note on figlet wordmarks

Files matching `*-name.txt` are figlet output of plain ASCII strings
("FRAMEWORK", "CACHYOS", "HYPRLAND", "NIRI"). The "ANSI Shadow" figlet
font is freely redistributable. Typefaces are not copyrightable in the
United States, so the rendered ASCII art is not a copyright-protected
work. Trademark status of the underlying *word* is independent and
addressed in each project's section above.

---

## User-supplied logos

Anything you drop into `~/.local/share/niri-screensaver/logos/` (or
point `LOGO_FILE` at directly) is yours; this attribution file does
not apply to logos you provide.
