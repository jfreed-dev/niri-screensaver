# AUR packaging

Two PKGBUILDs are scaffolded here for publishing to the [Arch User
Repository](https://aur.archlinux.org/):

| Package | Source | Use when |
|---|---|---|
| `niri-screensaver` | Latest release tarball (currently `v0.5.1`) | You want stable releases pinned to tagged versions |
| `niri-screensaver-git` | `main` branch, HEAD | You want bleeding-edge or to test pre-release fixes |

They `provides`/`conflicts` each other so users can only have one
installed at a time.

## Local test build

From the repo root:

```bash
cd packaging/aur/niri-screensaver
makepkg -si      # build + install for testing
makepkg --printsrcinfo > .SRCINFO   # regenerate before each AUR push
```

For the git variant the same commands apply under
`packaging/aur/niri-screensaver-git/`.

## Publishing to AUR (first time)

```bash
# 1. Create the empty AUR repo via the web UI, or just push to a new ssh path
ssh aur@aur.archlinux.org setup-repo niri-screensaver
git clone ssh://aur@aur.archlinux.org/niri-screensaver.git /tmp/aur-stable
cp packaging/aur/niri-screensaver/{PKGBUILD,niri-screensaver.install} /tmp/aur-stable/
cd /tmp/aur-stable
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO niri-screensaver.install
git commit -m "init: niri-screensaver 0.5.1-1"
git push
```

Repeat for `niri-screensaver-git` with its own AUR repo path.

## Maintenance per release

Each time a new tag is cut here:

1. Bump `pkgver` in `packaging/aur/niri-screensaver/PKGBUILD`
2. Refresh the `sha256sums` via `updpkgsums` (or manually:
   `curl -sL https://github.com/jfreed-dev/niri-screensaver/archive/refs/tags/vX.Y.Z.tar.gz | sha256sum`)
3. `makepkg --printsrcinfo > .SRCINFO` in the AUR repo checkout
4. Commit + push to AUR

The `-git` package only needs a push when the PKGBUILD itself changes —
its `pkgver()` recomputes from `git describe` at build time, so users
running `yay -Syu` automatically pick up new commits.

## Dependency notes

All declared deps exist in either the official Arch repos or AUR
(verified 2026-05-18):

| Dep | Source | Notes |
|---|---|---|
| `bash`, `alacritty`, `niri`, `jq` | extra/community | Required |
| `python-terminaltexteffects` | extra | The `tte` CLI |
| `noctalia-shell` | AUR | Optional — only for idle/lock integration |
| `playerctl` | extra | Optional — now-playing overlay |
| `wlrctl` | AUR | Optional — cursor parking |
| `ydotool` | extra | Optional — cursor parking fallback |
| `figlet` | extra | Optional — large clock/now-playing |

If `niri` itself is later moved between repos, update `depends`
accordingly.
